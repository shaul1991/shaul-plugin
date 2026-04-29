# 자산 위치 템플릿 (v0.9.0+)

> Step 8(`v0.9.0+`) 의 *시작 샘플*. 사용자에게 그대로 보여줘도 되고, 프로젝트 맥락에 맞게 편집해도 된다.
> 상위 헌장: `docs/direction/2026-04-29-claude-as-settings-only-charter.md`
> 이전 버전(v0.8.0): `three-tier-classification-template.md` (*Superseded*)

---

## 분류 원칙 (한 줄 요약)

- **`.claude/`** = *Claude/플러그인 사용 설정만* (`CLAUDE.md`, `secret-guard.json`, `settings.json`).
- **`docs/`** = *모든 문서* (의미별 하위 폴더에 분산).
- **`.claude/local/`, `.claude/settings.local.json`** = *로컬 전용* (차단 유지).

> v0.8.0 의 symlink 패턴은 폐기. 모든 cross-reference 는 `docs/<name>` 로 직접 작성.

---

## 권장 분류표

| 산출물 | 위치 | 이유 |
|--------|------|------|
| `CLAUDE.md` | `.claude/CLAUDE.md` | Claude Code 자동 로드. AI 컨텍스트 |
| `secret-guard.json` | `.claude/secret-guard.json` | PreToolUse 훅 자동 로드 |
| `settings.json` | `.claude/settings.json` | Claude Code 자동 로드 |
| `glossary.md`, `product-requirements.md`, `technical-requirements.md`, `index.md`, `api-flows/` | `docs/knowledge/` | three-doc-set 헌장 (v0.6.0) |
| `tech-stack.md`, `system-design.md`, `data-model.md`, `api-spec.md` | `docs/architecture/` | Phase 3 산출물 |
| `monitoring-report.md`, `feedback-analysis.md`, `retrospective.md`, `incident-reports/` | `docs/operations/` | Phase 8 산출물 |
| `project-config.md`, `team-conventions.md` | `docs/team/` | 팀 컨벤션 |
| `decisions.md` (Lightweight ADR) | `docs/policies/` | 결정의 단일 진입점 |
| `lifecycle.md`, `tech-debt-registry.md`, `kpi-definitions.md` | `docs/alm/` | ALM 추적 자산 |
| `issues/` | `docs/issues/` | 외부 트래커 대체 |
| `local/plans/<branch>/...` | `.claude/local/` (차단) | 브랜치별 일시 실행계획서 |
| `local/stack.json` | `.claude/local/` (차단) | 03-architecture 해시 검증 캐시 |
| `settings.local.json` | `.claude/settings.local.json` (차단) | 개인 IDE/단축키 설정 |

> ⚠️ **디렉토리명은 사용자 결정**. `alm`, `issues` 같은 카테고리는 *권장*.

---

## 신규 프로젝트의 초기 셋업

`00-setup` Step 5 이후 다음 폴더만 생성하면 시작점으로 충분:

```bash
mkdir -p docs/alm docs/issues docs/team
# 다른 docs/ 카테고리(architecture, operations, policies, knowledge)는
# 각 Phase 진입 시 또는 /knowledge 호출 시 자연스럽게 생성됨
```

`.claude/` 에는 `CLAUDE.md`·`settings.json`·(필요 시) `secret-guard.json` 만 둔다.

---

## 기존 v0.8.x 프로젝트의 마이그레이션

> ⚠️ **자동 실행 금지** (헌장 D9): 플러그인은 *명령을 보여줄 뿐* 자동 실행하지 않는다.

### 단계 1: 새 폴더 생성

```bash
mkdir -p docs/alm docs/issues
```

### 단계 2: 운영 자산 이동

```bash
mv .claude/lifecycle.md docs/alm/lifecycle.md
mv .claude/tech-debt-registry.md docs/alm/tech-debt-registry.md
mv .claude/kpi-definitions.md docs/alm/kpi-definitions.md
mv .claude/issues docs/issues
```

### 단계 3: 호환 symlink 제거 (있는 경우)

```bash
cd .claude && rm -f 00-setup 03-architecture 08-maintenance policies knowledge
```

### 단계 4: `.gitignore` 단순화

기존 와일드카드 + 7~12 negate 패턴을 *3 negate* 만 유지:

```gitignore
.claude/*
!.claude/CLAUDE.md
!.claude/secret-guard.json
!.claude/settings.json
.claude/settings.local.json
```

### 단계 5: cross-reference 일괄 갱신

```bash
find docs -type f -name "*.md" -exec sed -i '' \
  -e 's|\.claude/lifecycle\.md|docs/alm/lifecycle.md|g' \
  -e 's|\.claude/tech-debt-registry\.md|docs/alm/tech-debt-registry.md|g' \
  -e 's|\.claude/kpi-definitions\.md|docs/alm/kpi-definitions.md|g' \
  -e 's|\.claude/issues|docs/issues|g' \
  -e 's|\.claude/03-architecture|docs/architecture|g' \
  -e 's|\.claude/08-maintenance|docs/operations|g' \
  -e 's|\.claude/00-setup|docs/team|g' \
  -e 's|\.claude/policies|docs/policies|g' \
  -e 's|\.claude/knowledge|docs/knowledge|g' \
  {} \;
```

> Linux GNU sed 는 `-i ''` 대신 `-i` 만 사용.

### 단계 6: 점검·수동 보정

```bash
grep -rn "\.claude/" docs/ | grep -v "\.claude/CLAUDE\|\.claude/secret-guard\|\.claude/settings\|\.claude/local"
```

남은 라인을 수동 점검. 특히 *symlink 설명* 같은 문맥 의존 표현은 sed 가 손상시킬 수 있다.

### 단계 7: `.claude/CLAUDE.md` ALM 표 재구성

기존의 *공유/운영/로컬 3계층 표* 를 *사용 설정·팀 공유 문서·로컬 전용 2+1 카테고리* 로 갱신.

### 단계 8: lifecycle 변경 이력 row 추가

`docs/alm/lifecycle.md` 의 변경 이력에 본 마이그레이션을 한 row 추가.

---

## 자주 묻는 질문

**Q: 모든 프로젝트가 `docs/alm/` 을 만들어야 하나?**
A: 아니. *권장*일 뿐. 1인·실험 프로젝트는 `.claude/lifecycle.md` 를 그대로 두고 단순 차단을 유지해도 된다.

**Q: `secret-guard.json` 도 docs/ 로 옮길 수 있나?**
A: *옮기지 않는다* (헌장 미래 변경 #6). PreToolUse 훅이 `.claude/secret-guard.json` 위치로 자동 로드한다 — 옮기면 가드가 작동하지 않는다.

**Q: `CLAUDE.md` 를 docs/ 로 옮길 수 있나?**
A: 비추천. Claude Code 가 `.claude/CLAUDE.md` 와 루트 `CLAUDE.md` 를 자동 로드한다 — `.claude/` 가 표준 위치. *AI 컨텍스트 = 사용 설정* 이라는 헌장 원칙과도 정합.

**Q: v0.8.0 의 symlink 패턴을 그대로 유지하면 안 되나?**
A: 가능하지만 비추천. macOS 환경에선 동작하지만 Windows·일부 CI 환경에서 깨질 수 있고, 사본 관리·`.gitignore` 룰이 복잡해진다. 본 헌장은 *symlink 도입 안 함* 을 D3 로 명시.

**Q: 운영 자산을 docs/ 로 옮기면 git history 가 끊기나?**
A: `git mv` 또는 `mv` 후 git 이 자동 *rename* 인식 (≥50% 유사도 보존). `git log --follow <new-path>` 로 history 추적 가능. 단, blame 은 일부 도구에서 분산될 수 있음.
