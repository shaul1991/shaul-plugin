"""project-lifecycle plugin — Plane integration core (v0.10.0)

Charter: docs/direction/2026-04-30-plane-integration-charter.md

Module is imported by:
  - hooks/plane-sync.sh   (PostToolUse, Edit|Write — push on local change)
  - hooks/plane-watch.sh  (SessionStart — read-only status report)

Design choices (see charter):
  - One module: config + HTTP + frontmatter + file-end blocks + per-domain sync.
  - Stdlib only — no PyYAML, no requests. urllib for HTTP.
  - Fail-open: any Plane failure logs to stderr and returns; never blocks
    the user's tool call. (Contrast: secret-guard is fail-closed.)
  - Round-trip safe frontmatter — preserve user-authored keys verbatim, only
    rewrite the keys we own.
"""

from __future__ import annotations

import fnmatch
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

LOG_PREFIX = "[project-lifecycle/plane]"
SCHEMA_VERSION = 1
SUPPORTED_SCHEMA_VERSIONS = {1}

# Keys this module owns inside frontmatter. Anything else is preserved verbatim.
OWNED_FM_KEYS = (
    "plane_id",
    "plane_sequence_id",
    "plane_state",
    "plane_labels",
    "plane_url",
    "sync_origin",
    "last_synced_at",
    "last_synced_hash",
)


def log(msg: str) -> None:
    sys.stderr.write(f"{LOG_PREFIX} {msg}\n")


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_str(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

class Config:
    """Parsed view of `<cwd>/.claude/integrations.json`.

    Attributes default to the "do nothing" shape when the file is missing or
    malformed — that is the point of fail-open + default-mode-local (D1).
    """

    def __init__(
        self,
        primary: Optional[str],
        default_mode: str,
        plane: Optional[Dict[str, Any]],
        loaded_from: Optional[str],
    ) -> None:
        self.primary = primary
        self.default_mode = default_mode
        self.plane = plane or {}
        self.loaded_from = loaded_from

    @property
    def is_local_only(self) -> bool:
        """True when no external tracker is active. v0.9.0 bit-identical path."""
        return not self.primary or self.primary == "local"

    def domain_mode(self, domain_key: str) -> str:
        """Return effective mode for a domain — explicit override or inherited default."""
        d = (self.plane.get("domains") or {}).get(domain_key) or {}
        return (d.get("mode") or self.default_mode or "local").lower()

    def domain(self, domain_key: str) -> Dict[str, Any]:
        return (self.plane.get("domains") or {}).get(domain_key) or {}

    @classmethod
    def load(cls, project_root: Path) -> "Config":
        p = project_root / ".claude" / "integrations.json"
        if not p.exists():
            return cls(primary=None, default_mode="local", plane=None, loaded_from=None)
        try:
            raw = json.loads(p.read_text(encoding="utf-8"))
        except Exception as exc:
            log(f"integrations.json 파싱 실패 — sync 비활성: {exc}")
            return cls(primary=None, default_mode="local", plane=None, loaded_from=str(p))
        if not isinstance(raw, dict):
            log(f"integrations.json 루트가 객체가 아님 — sync 비활성")
            return cls(primary=None, default_mode="local", plane=None, loaded_from=str(p))

        sv = raw.get("schema_version", 1)
        if not isinstance(sv, int) or sv not in SUPPORTED_SCHEMA_VERSIONS:
            log(f"integrations.json schema_version={sv!r} 미지원 — sync 비활성")
            return cls(primary=None, default_mode="local", plane=None, loaded_from=str(p))

        tracker = raw.get("tracker") or {}
        primary = tracker.get("primary")
        if isinstance(primary, str):
            primary = primary.strip().lower() or None
        else:
            primary = None
        default_mode = (tracker.get("default_mode") or "local").lower()

        providers = raw.get("providers") or {}
        plane = providers.get("plane") if isinstance(providers, dict) else None
        if plane and not (isinstance(plane, dict) and plane.get("enabled", True)):
            plane = None

        return cls(primary=primary, default_mode=default_mode, plane=plane, loaded_from=str(p))


# ---------------------------------------------------------------------------
# Token resolution (priority: env > env > secret file > none)
# ---------------------------------------------------------------------------

def resolve_token(project_root: Path, secret_file_rel: Optional[str]) -> Tuple[Optional[str], str]:
    """Return (token, source_label). source_label is for debug/stderr only."""
    v = os.environ.get("CLAUDE_PLUGIN_PLANE_TOKEN")
    if v:
        return v, "env:CLAUDE_PLUGIN_PLANE_TOKEN"
    v = os.environ.get("PLANE_API_TOKEN")
    if v:
        return v, "env:PLANE_API_TOKEN"
    if secret_file_rel:
        p = project_root / secret_file_rel
        if p.exists():
            try:
                data = json.loads(p.read_text(encoding="utf-8"))
                tok = data.get("api_token") if isinstance(data, dict) else None
                if isinstance(tok, str) and tok:
                    return tok, f"file:{secret_file_rel}"
            except Exception as exc:
                log(f"secret 파일 파싱 실패 ({secret_file_rel}): {exc}")
    return None, "none"


# ---------------------------------------------------------------------------
# Frontmatter — round-trip safe (preserve unknown keys verbatim)
# ---------------------------------------------------------------------------

_FM_DELIM_RE = re.compile(r"^---\s*$")


class Frontmatter:
    """Minimalist frontmatter codec — *not* a YAML parser.

    We only parse simple `key: value` and inline list `key: [a, b]` shapes.
    We preserve unknown lines as raw strings (round-trip), and only rewrite
    keys this module owns.
    """

    def __init__(self, raw_lines: List[str], body_offset: int = 0) -> None:
        self.raw_lines = raw_lines  # original lines between the two `---` delimiters
        self.body_offset = body_offset  # number of lines occupied by `---\n<fm>\n---\n`

    @classmethod
    def split(cls, text: str) -> Tuple[Optional["Frontmatter"], str]:
        """Return (frontmatter or None, body_text)."""
        lines = text.splitlines(keepends=True)
        if not lines or not _FM_DELIM_RE.match(lines[0].rstrip("\n").rstrip("\r")):
            return None, text
        # Find closing delim
        for i in range(1, len(lines)):
            if _FM_DELIM_RE.match(lines[i].rstrip("\n").rstrip("\r")):
                fm_lines = lines[1:i]
                body = "".join(lines[i + 1:])
                return cls(raw_lines=fm_lines, body_offset=i + 1), body
        # No closing delim — treat as no frontmatter
        return None, text

    def _line_for_key(self, key: str) -> Optional[int]:
        for idx, line in enumerate(self.raw_lines):
            stripped = line.lstrip()
            if not stripped or stripped.startswith("#"):
                continue
            head, _, _ = stripped.partition(":")
            if head.strip() == key:
                return idx
        return None

    def get(self, key: str) -> Optional[str]:
        idx = self._line_for_key(key)
        if idx is None:
            return None
        line = self.raw_lines[idx]
        _, _, rest = line.partition(":")
        return rest.strip().rstrip("\n").rstrip("\r")

    def get_list(self, key: str) -> List[str]:
        v = self.get(key)
        if not v:
            return []
        s = v.strip()
        if s.startswith("[") and s.endswith("]"):
            inner = s[1:-1].strip()
            if not inner:
                return []
            return [p.strip().strip("\"'") for p in inner.split(",") if p.strip()]
        # bare scalar
        return [s.strip().strip("\"'")]

    def set(self, key: str, value: Any) -> None:
        if isinstance(value, list):
            rendered = "[" + ", ".join(str(x) for x in value) + "]"
        elif value is None:
            rendered = ""
        else:
            rendered = str(value)
        new_line = f"{key}: {rendered}\n"
        idx = self._line_for_key(key)
        if idx is None:
            self.raw_lines.append(new_line)
        else:
            self.raw_lines[idx] = new_line

    def dump(self) -> str:
        return "---\n" + "".join(self.raw_lines) + "---\n"


def attach_frontmatter(text: str, fm: Frontmatter) -> str:
    """Re-attach frontmatter to body. Idempotent if fm came from split()."""
    _, body = Frontmatter.split(text)
    return fm.dump() + body


# ---------------------------------------------------------------------------
# File-end HTML comment block (B / C domains)
# ---------------------------------------------------------------------------

def _block_re(name: str) -> re.Pattern:
    # <!-- plane-sync:<name>\n{json}\nplane-sync:end -->
    return re.compile(
        r"<!--\s*plane-sync:" + re.escape(name) + r"\s*\n(.*?)\nplane-sync:end\s*-->",
        re.DOTALL,
    )


def read_block(text: str, name: str) -> Dict[str, Any]:
    m = _block_re(name).search(text)
    if not m:
        return {}
    try:
        return json.loads(m.group(1)) or {}
    except Exception as exc:
        log(f"file-end block (plane-sync:{name}) 파싱 실패: {exc}")
        return {}


def write_block(text: str, name: str, data: Dict[str, Any]) -> str:
    rendered = (
        f"<!-- plane-sync:{name}\n"
        + json.dumps(data, ensure_ascii=False, indent=2)
        + f"\nplane-sync:end -->\n"
    )
    pat = _block_re(name)
    if pat.search(text):
        return pat.sub(lambda _: rendered.rstrip("\n"), text)
    sep = "" if text.endswith("\n") else "\n"
    return text + sep + "\n" + rendered


# ---------------------------------------------------------------------------
# Plane API client (urllib only)
# ---------------------------------------------------------------------------

class PlaneError(Exception):
    def __init__(self, status: int, msg: str) -> None:
        super().__init__(f"{status}: {msg}")
        self.status = status


class PlaneClient:
    """Thin urllib wrapper. All Plane HTTP isolated here per charter D12."""

    def __init__(
        self,
        host: str,
        api_version: str,
        workspace_slug: str,
        project_id: str,
        token: str,
        dry_run: bool = False,
    ) -> None:
        self.host = host.rstrip("/")
        self.api_version = api_version
        self.workspace_slug = workspace_slug
        self.project_id = project_id
        self.token = token
        self.dry_run = dry_run
        self.calls = 0

    def _url(self, path: str) -> str:
        return f"{self.host}/api/{self.api_version}/workspaces/{self.workspace_slug}/projects/{self.project_id}/{path.lstrip('/')}"

    def _request(self, method: str, path: str, body: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        url = self._url(path)
        if self.dry_run:
            log(f"DRY-RUN {method} {url} body={json.dumps(body, ensure_ascii=False) if body else 'None'}")
            return {"_dry_run": True}
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("X-API-Key", self.token)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")
        self.calls += 1
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                txt = resp.read().decode("utf-8") or "{}"
                return json.loads(txt)
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode("utf-8", errors="replace") if hasattr(exc, "read") else ""
            raise PlaneError(exc.code, f"{url} :: {raw[:200]}")
        except urllib.error.URLError as exc:
            raise PlaneError(0, f"{url} :: {exc.reason}")
        except Exception as exc:
            raise PlaneError(-1, f"{url} :: {exc}")

    # Issue ----------------------------------------------------------------
    def create_issue(self, name: str, description: str, labels: List[str], state_name: Optional[str] = None, parent_id: Optional[str] = None) -> Dict[str, Any]:
        body: Dict[str, Any] = {
            "name": name,
            "description_html": description,
            "labels": labels,
        }
        if state_name:
            body["state_name"] = state_name
        if parent_id:
            body["parent"] = parent_id
        return self._request("POST", "issues/", body)

    def update_issue(self, issue_id: str, name: str, description: str, labels: List[str]) -> Dict[str, Any]:
        body = {"name": name, "description_html": description, "labels": labels}
        return self._request("PATCH", f"issues/{issue_id}/", body)

    def search_issue_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        try:
            res = self._request("GET", f"issues/?search={urllib.request.quote(name)}")
        except PlaneError:
            return None
        items = res.get("results") if isinstance(res, dict) else None
        if not items and isinstance(res, list):
            items = res
        for it in items or []:
            if isinstance(it, dict) and it.get("name") == name:
                return it
        return None

    # Module ---------------------------------------------------------------
    def get_or_create_module(self, name: str) -> Dict[str, Any]:
        try:
            res = self._request("GET", "modules/")
            items = res.get("results") if isinstance(res, dict) else (res if isinstance(res, list) else [])
            for it in items or []:
                if isinstance(it, dict) and it.get("name") == name:
                    return it
        except PlaneError as exc:
            log(f"modules GET 실패 (계속 진행): {exc}")
        return self._request("POST", "modules/", {"name": name})


# ---------------------------------------------------------------------------
# Domain matching
# ---------------------------------------------------------------------------

def match_domain(rel_path: str, plane_cfg: Dict[str, Any]) -> Optional[str]:
    """Return domain key whose path/path_glob matches rel_path, or None."""
    rel = rel_path.lstrip("./")
    domains = plane_cfg.get("domains") or {}
    for key, cfg in domains.items():
        if not isinstance(cfg, dict):
            continue
        path = cfg.get("path")
        if path and rel == path.lstrip("./"):
            return key
        glob = cfg.get("path_glob")
        if glob and fnmatch.fnmatch(rel, glob.lstrip("./")):
            return key
    return None


# ---------------------------------------------------------------------------
# Sync handlers per domain
# ---------------------------------------------------------------------------

def _split_title_and_body(text: str) -> Tuple[str, str]:
    """Pull `# title` from body. Returns (title, body_without_title)."""
    body = text
    title = ""
    m = re.search(r"^\s*#\s+(.+?)\s*$", body, re.MULTILINE)
    if m:
        title = m.group(1).strip()
        body = body[: m.start()] + body[m.end():]
    return title, body.strip()


def sync_issues_file(file_path: Path, project_root: Path, client: PlaneClient, domain_cfg: Dict[str, Any]) -> bool:
    """A domain — docs/issues/<slug>.md ↔ Plane Issue (root)."""
    if not file_path.exists():
        return False
    text = file_path.read_text(encoding="utf-8")
    fm, body = Frontmatter.split(text)
    if fm is None:
        # No frontmatter yet — create one.
        fm = Frontmatter(raw_lines=[], body_offset=0)
        body = text

    title, body_clean = _split_title_and_body(body)
    if not title:
        # Filename slug as fallback title
        title = file_path.stem.replace("-", " ").strip().capitalize()
    body_hash = sha256_str(title + "\n" + body_clean)
    if fm.get("last_synced_hash") == body_hash and fm.get("plane_id"):
        return False  # No change

    plane_id = fm.get("plane_id")
    labels = fm.get_list("plane_labels") or list(domain_cfg.get("default_labels") or [])
    state = fm.get("plane_state") or domain_cfg.get("default_state")
    description = body_clean

    if plane_id:
        try:
            res = client.update_issue(plane_id, title, description, labels)
        except PlaneError as exc:
            log(f"PATCH 실패 ({file_path}): {exc}")
            return False
    else:
        existing = client.search_issue_by_name(title)
        if existing and existing.get("id"):
            plane_id = existing["id"]
            log(f"동명 이슈 발견 — PATCH 로 흡수 ({file_path}, plane_id={plane_id})")
            try:
                res = client.update_issue(plane_id, title, description, labels)
            except PlaneError as exc:
                log(f"PATCH 실패 ({file_path}): {exc}")
                return False
        else:
            try:
                res = client.create_issue(title, description, labels, state_name=state)
            except PlaneError as exc:
                log(f"CREATE 실패 ({file_path}): {exc}")
                return False

    if client.dry_run:
        log(f"DRY-RUN sync_issues_file ({file_path}) — frontmatter 갱신 skip")
        return False

    fm.set("plane_id", res.get("id") or plane_id or "")
    if res.get("sequence_id") is not None:
        fm.set("plane_sequence_id", res.get("sequence_id"))
    fm.set("plane_state", state or "")
    fm.set("plane_labels", labels)
    if res.get("project") and res.get("id"):
        fm.set("plane_url", f"{client.host}/{client.workspace_slug}/projects/{client.project_id}/issues/{res.get('id')}")
    fm.set("sync_origin", fm.get("sync_origin") or "local")
    fm.set("last_synced_at", now_iso())
    fm.set("last_synced_hash", body_hash)

    new_text = fm.dump() + (body_clean + "\n" if body_clean else "")
    if title:
        new_text = fm.dump() + f"# {title}\n\n" + (body_clean + "\n" if body_clean else "")
    file_path.write_text(new_text, encoding="utf-8")
    log(f"PUSHED issue ({file_path.relative_to(project_root) if project_root in file_path.parents or project_root == file_path.parent else file_path})")
    return True


_TD_HEADING_RE = re.compile(r"^###\s+(TD-\d{3,})\s*:\s*(.+?)\s*$", re.MULTILINE)


def sync_tech_debt(file_path: Path, project_root: Path, client: PlaneClient, domain_cfg: Dict[str, Any]) -> bool:
    """C domain — docs/alm/tech-debt-registry.md ↔ Issue per TD-NNN."""
    if not file_path.exists():
        return False
    text = file_path.read_text(encoding="utf-8")
    block = read_block(text, "tech-debt") or {}
    issues_map: Dict[str, Any] = block.get("issues") or {}

    sections = list(_TD_HEADING_RE.finditer(text))
    if not sections:
        return False

    base_labels = list(domain_cfg.get("default_labels") or ["tech-debt"])
    sev_map = domain_cfg.get("label_by_severity") or {}

    pushed_any = False
    for i, m in enumerate(sections):
        td_id = m.group(1)
        title = m.group(2).strip()
        end = sections[i + 1].start() if i + 1 < len(sections) else len(text)
        section_body = text[m.end():end].strip()

        # Severity heuristic: line "Severity: High" 등
        sev_match = re.search(r"^\s*[-*]?\s*Severity\s*:\s*(\w+)", section_body, re.MULTILINE | re.IGNORECASE)
        labels = list(base_labels)
        if sev_match:
            sev = sev_match.group(1).strip().capitalize()
            for extra in sev_map.get(sev, []) or []:
                if extra not in labels:
                    labels.append(extra)

        record = issues_map.get(td_id) or {}
        plane_id = record.get("plane_id")
        last_hash = record.get("last_synced_hash")
        body_hash = sha256_str(f"{td_id}|{title}|{section_body}")
        if plane_id and last_hash == body_hash:
            continue

        full_title = f"{td_id}: {title}"
        try:
            if plane_id:
                res = client.update_issue(plane_id, full_title, section_body, labels)
            else:
                res = client.create_issue(full_title, section_body, labels)
        except PlaneError as exc:
            log(f"tech-debt sync 실패 ({td_id}): {exc}")
            continue

        if client.dry_run:
            continue

        record["plane_id"] = res.get("id") or plane_id
        if res.get("sequence_id") is not None:
            record["sequence_id"] = res.get("sequence_id")
        record["last_synced_hash"] = body_hash
        record["last_synced_at"] = now_iso()
        issues_map[td_id] = record
        pushed_any = True
        log(f"PUSHED tech-debt {td_id}")

    if pushed_any:
        block["issues"] = issues_map
        new_text = write_block(text, "tech-debt", block)
        file_path.write_text(new_text, encoding="utf-8")
    return pushed_any


_LIFECYCLE_PHASE_RE = re.compile(r"^##\s+Phase\s+(\d+(?:[-:]?\w+)?)\s*[—:\-]?\s*(.*?)\s*$", re.MULTILINE | re.IGNORECASE)


def sync_lifecycle(file_path: Path, project_root: Path, client: PlaneClient, domain_cfg: Dict[str, Any]) -> bool:
    """B domain — docs/alm/lifecycle.md ↔ Module + Module Issue per Phase.

    v1 scope: ensure Module exists, ensure one Issue per Phase. Table-row
    comments are deferred (charter §"v1 구현 범위").
    """
    if not file_path.exists():
        return False
    text = file_path.read_text(encoding="utf-8")
    block = read_block(text, "lifecycle") or {}
    module_id = block.get("module_id")
    phase_issues: Dict[str, str] = block.get("phase_issues") or {}

    module_name = domain_cfg.get("module_name_template") or "ALM Lifecycle"
    if not module_id:
        try:
            mod = client.get_or_create_module(module_name)
            module_id = mod.get("id")
        except PlaneError as exc:
            log(f"lifecycle module ensure 실패: {exc}")
            return False

    phases = list(_LIFECYCLE_PHASE_RE.finditer(text))
    pushed_any = False
    for i, m in enumerate(phases):
        phase_key = m.group(1).strip().lower()
        phase_title = m.group(2).strip() or f"Phase {phase_key}"
        end = phases[i + 1].start() if i + 1 < len(phases) else len(text)
        body = text[m.end():end].strip()
        full_title = f"Phase {phase_key} — {phase_title}" if phase_title else f"Phase {phase_key}"
        plane_id = phase_issues.get(phase_key)
        try:
            if plane_id:
                client.update_issue(plane_id, full_title, body, ["phase", "alm-lifecycle"])
            else:
                res = client.create_issue(full_title, body, ["phase", "alm-lifecycle"])
                if not client.dry_run and res.get("id"):
                    phase_issues[phase_key] = res["id"]
                    pushed_any = True
        except PlaneError as exc:
            log(f"lifecycle phase {phase_key} sync 실패: {exc}")
            continue

    if pushed_any or block.get("module_id") != module_id:
        block["module_id"] = module_id
        block["module_name"] = module_name
        block["phase_issues"] = phase_issues
        block["last_synced_at"] = now_iso()
        new_text = write_block(text, "lifecycle", block)
        file_path.write_text(new_text, encoding="utf-8")
        return True
    return False


_PLAN_PATH_RE = re.compile(r"^\.claude/local/plans/([^/]+)/([^/]+)/execution-plan\.md$")


def sync_execution_plan(file_path: Path, project_root: Path, client: PlaneClient, domain_cfg: Dict[str, Any], lifecycle_path: Optional[Path]) -> bool:
    """D domain — execution-plan.md ↔ Sub-issue (parent = lifecycle Phase Issue)."""
    if not file_path.exists():
        return False
    rel = str(file_path.relative_to(project_root)) if project_root in file_path.parents else str(file_path)
    m = _PLAN_PATH_RE.match(rel)
    if not m:
        return False
    branch = m.group(1)
    phase = m.group(2)

    parent_id: Optional[str] = None
    if lifecycle_path and lifecycle_path.exists():
        lc_block = read_block(lifecycle_path.read_text(encoding="utf-8"), "lifecycle") or {}
        parent_id = (lc_block.get("phase_issues") or {}).get(phase)

    text = file_path.read_text(encoding="utf-8")
    fm, body = Frontmatter.split(text)
    if fm is None:
        fm = Frontmatter(raw_lines=[], body_offset=0)
        body = text

    title, body_clean = _split_title_and_body(body)
    if not title:
        title = f"[{branch}/{phase}] execution plan"
    body_hash = sha256_str(title + "\n" + body_clean)
    if fm.get("last_synced_hash") == body_hash and fm.get("plane_id"):
        return False

    labels = list(domain_cfg.get("default_labels") or ["execution-plan"])
    if f"branch:{branch}" not in labels:
        labels.append(f"branch:{branch}")
    if f"phase:{phase}" not in labels:
        labels.append(f"phase:{phase}")

    plane_id = fm.get("plane_id")
    try:
        if plane_id:
            res = client.update_issue(plane_id, title, body_clean, labels)
        else:
            res = client.create_issue(title, body_clean, labels, parent_id=parent_id)
    except PlaneError as exc:
        log(f"execution-plan sync 실패 ({file_path}): {exc}")
        return False

    if client.dry_run:
        return False

    fm.set("plane_id", res.get("id") or plane_id or "")
    if res.get("sequence_id") is not None:
        fm.set("plane_sequence_id", res.get("sequence_id"))
    fm.set("plane_labels", labels)
    fm.set("sync_origin", fm.get("sync_origin") or "local")
    fm.set("last_synced_at", now_iso())
    fm.set("last_synced_hash", body_hash)

    new_text = fm.dump() + (f"# {title}\n\n" if title else "") + (body_clean + "\n" if body_clean else "")
    file_path.write_text(new_text, encoding="utf-8")
    log(f"PUSHED execution-plan ({rel})")
    return True


# ---------------------------------------------------------------------------
# Entry points (called from .sh wrappers)
# ---------------------------------------------------------------------------

def _project_root() -> Optional[Path]:
    """Use git toplevel when available; else cwd."""
    import subprocess
    try:
        out = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL)
        return Path(out.decode("utf-8").strip())
    except Exception:
        return None


def _build_client(cfg: Config, dry_run_override: Optional[bool] = None) -> Optional[PlaneClient]:
    plane = cfg.plane
    if not plane:
        return None
    host = plane.get("host") or "https://api.plane.so"
    api_version = plane.get("api_version") or "v1"
    workspace_slug = plane.get("workspace_slug")
    project_id = plane.get("project_id")
    if not workspace_slug or not project_id:
        log("workspace_slug 또는 project_id 미설정 — sync 비활성")
        return None
    secret_file = plane.get("secret_file") or ".claude/local/plane.secret.json"
    project_root = _project_root() or Path.cwd()
    token, source = resolve_token(project_root, secret_file)
    if not token:
        # Quiet skip — could be intentional offline / not yet configured.
        return None
    safety = plane.get("safety") or {}
    dry_run = dry_run_override if dry_run_override is not None else bool(safety.get("dry_run", False))
    return PlaneClient(host, api_version, workspace_slug, project_id, token, dry_run=dry_run)


def run_post_tool_use() -> int:
    """Read PostToolUse JSON from stdin → push if file matches a domain."""
    project_root = _project_root()
    if project_root is None:
        return 0
    cfg = Config.load(project_root)
    if cfg.is_local_only or not cfg.plane:
        return 0
    if cfg.primary != "plane":
        return 0  # v1: only plane provider implemented

    raw = sys.stdin.read()
    if not raw:
        return 0
    try:
        evt = json.loads(raw)
    except Exception:
        return 0
    tool_name = evt.get("tool_name") or ""
    if tool_name not in ("Edit", "Write"):
        return 0
    fp = (evt.get("tool_input") or {}).get("file_path") or ""
    if not fp:
        return 0
    abs_path = Path(fp) if Path(fp).is_absolute() else (project_root / fp)
    try:
        rel_path = str(abs_path.relative_to(project_root))
    except ValueError:
        return 0

    domain = match_domain(rel_path, cfg.plane)
    if not domain:
        return 0
    domain_mode = cfg.domain_mode(domain)
    if domain_mode not in ("plane", "both"):
        return 0

    client = _build_client(cfg)
    if client is None:
        return 0

    safety = (cfg.plane.get("safety") or {})
    max_calls = int(safety.get("max_calls_per_session", 200))
    domain_cfg = cfg.domain(domain)
    lifecycle_path = project_root / (cfg.domain("lifecycle").get("path") or "docs/alm/lifecycle.md")

    try:
        if domain == "issues":
            sync_issues_file(abs_path, project_root, client, domain_cfg)
        elif domain == "tech_debt":
            sync_tech_debt(abs_path, project_root, client, domain_cfg)
        elif domain == "lifecycle":
            sync_lifecycle(abs_path, project_root, client, domain_cfg)
        elif domain == "execution_plans":
            sync_execution_plan(abs_path, project_root, client, domain_cfg, lifecycle_path)
    except Exception as exc:
        log(f"sync 중 예외 (fail-open, 무시): {exc}")

    if client.calls > max_calls:
        log(f"max_calls_per_session({max_calls}) 초과 — 다음 호출은 skip 권장")
    return 0


def run_session_start() -> int:
    """Read-only status report on session start."""
    project_root = _project_root()
    if project_root is None:
        return 0
    cfg = Config.load(project_root)
    if cfg.is_local_only or not cfg.plane:
        return 0
    if cfg.primary != "plane":
        log(f"primary={cfg.primary!r} — 본 v1 은 'plane' 만 지원, sync 비활성")
        return 0

    plane = cfg.plane
    safety = plane.get("safety") or {}
    secret_file = plane.get("secret_file") or ".claude/local/plane.secret.json"
    token, source = resolve_token(project_root, secret_file)
    if not token:
        log("토큰 미설정 — sync 비활성 (CLAUDE_PLUGIN_PLANE_TOKEN, PLANE_API_TOKEN, 또는 .claude/local/plane.secret.json)")
        return 0

    domains = plane.get("domains") or {}
    summary = ", ".join(sorted(domains.keys())) or "(없음)"
    log(
        f"활성: workspace={plane.get('workspace_slug')}, project={plane.get('project_id')}, "
        f"mode={cfg.default_mode}, dry_run={bool(safety.get('dry_run', False))}, token={source}"
    )
    log(f"  도메인: {summary}")
    if safety.get("dry_run"):
        log("  DRY-RUN 모드: 실제 push 안 함, stderr 로그만 출력")

    # Token age check (optional D5 supplement)
    secret_path = project_root / secret_file
    if secret_path.exists():
        try:
            data = json.loads(secret_path.read_text(encoding="utf-8"))
            issued = data.get("issued_at") if isinstance(data, dict) else None
            if isinstance(issued, str):
                issued_dt = datetime.strptime(issued.replace("Z", ""), "%Y-%m-%dT%H:%M:%S")
                age_days = (datetime.utcnow() - issued_dt).days
                if age_days >= 90:
                    log(f"  토큰 발급 후 {age_days}일 경과 — 회전 권장")
        except Exception:
            pass
    return 0
