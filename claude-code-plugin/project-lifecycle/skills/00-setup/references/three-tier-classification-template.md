# 사내 자산 3계층 분류 템플릿

> Step 8(`v0.8.0+`) 의 *시작 샘플*. 사용자에게 그대로 보여줘도 되고, 프로젝트 맥락에 맞게 편집해도 된다.
> 상위 헌장: `docs/direction/2026-04-29-three-tier-asset-charter.md`

---

## 분류 원칙 (한 줄 요약)

- **공유 자산** = `docs/<name>/` (실체) + `.claude/<name>` 심볼릭 링크. 외부 협업·온보딩 가치 큰 *읽기 자료*.
- **운영 자산** = `.claude/` 직속 + `.gitignore` negate. 플러그인이 *작동을 위해 읽고 쓰는* 자산.
- **로컬 전용** = `.claude/local/`, `.claude/settings.local.json`. 일시 작업·개인 설정.

> docs 와 .claude 양쪽에 사본을 두지 않는다 — symlink 로 *단일 진실* 유지(헌장 D2·D3).

---

## 권장 분류표

| 산출물 | 계층 | 권장 위치 | 이유 |
|--------|------|-----------|------|
| `glossary.md`, `product-requirements.md`, `technical-requirements.md`, `index.md` | 공유 | `docs/knowledge/` | three-doc-set 헌장(v0.6.0) |
| `tech-stack.md`, `system-design.md`, `data-model.md`, `api-spec.md` | 공유 | `docs/architecture/` | ADR·시스템 설계는 변경 영향 분석 기준선·온보딩 핵심 |
| `monitoring-report.md`, `feedback-analysis.md`, `retrospective.md`, `incident-reports/` | 공유 | `docs/operations/` | 운영 학습 자산. blameless 회고는 팀 가시성 본질 |
| `project-config.md`, `team-conventions.md` | 공유 | `docs/team/` | 팀 컨벤션은 모든 멤버에 동일 적용 |
| `decisions.md` (Lightweight ADR) | 공유 | `docs/policies/` | 결정의 단일 진입점 |
| `lifecycle.md`, `tech-debt-registry.md`, `kpi-definitions.md` | 운영 | `.claude/` (negate) | 플러그인이 갱신하는 ALM 추적 자산 |
| `issues/` | 운영 | `.claude/issues/` (negate) | 외부 트래커 부재 시 대체 |
| `secret-guard.json` | 운영 | `.claude/` (negate) | 보안 정책 — 멤버 간 drift 방지 필수 |
| `settings.json` | 운영 | `.claude/` (negate) | 프로젝트 공통 Claude Code 설정 |
| `CLAUDE.md` | 운영 | `.claude/` (negate) | AI 컨텍스트 — 멤버·도구 간 일관성 보장 |
| `local/plans/<branch>/...` | 로컬 | `.claude/local/` (차단) | 브랜치별 일시 실행계획서 |
| `local/stack.json` | 로컬 | `.claude/local/` (차단) | 03-architecture 해시 검증 캐시 |
| `settings.local.json` | 로컬 | `.claude/` (명시 차단) | 개인 IDE/단축키 설정 |

> ⚠️ **디렉토리명은 사용자 결정** (헌장 D8). `00-setup → team`, `08-maintenance → operations` 는 *권장*. 사용자가 `setup`/`maintenance` 같은 다른 이름 선택 가능.

---

## 마이그레이션 명령 시퀀스

> ⚠️ **Windows 호환성** (헌장 D11): symlink 미지원 환경에선 `mklink /D` 또는 `git config core.symlinks=true` 가 필요하다. POSIX 환경 기준으로 작성됨.
> ⚠️ **자동 실행 금지** (헌장 D6·D7): 플러그인은 *명령을 보여줄 뿐* 자동 실행하지 않는다.

### 단계 1: 공유 자산 승격 (사용자 명시 결정 시)

승격할 디렉토리마다 다음 2 명령을 실행:

```bash
# .claude/03-architecture → docs/architecture
mv .claude/03-architecture docs/architecture
ln -s ../docs/architecture .claude/03-architecture

# .claude/08-maintenance → docs/operations
mv .claude/08-maintenance docs/operations
ln -s ../docs/operations .claude/08-maintenance

# .claude/00-setup → docs/team
mv .claude/00-setup docs/team
ln -s ../docs/team .claude/00-setup

# .claude/policies → docs/policies
mv .claude/policies docs/policies
ln -s ../docs/policies .claude/policies
```

> *PoC 1개부터* 시작해도 무방. 4개 모두 한 번에 진행할 필요 없다.

### 단계 2: `.gitignore` 수정 (운영 자산 추적 + 승격된 symlink 추적)

기존 `.claude/` 한 줄 차단을 다음 패턴으로 교체:

```gitignore
.claude/*
!.claude/CLAUDE.md
!.claude/lifecycle.md
!.claude/tech-debt-registry.md
!.claude/kpi-definitions.md
!.claude/issues/
!.claude/secret-guard.json
!.claude/settings.json
!.claude/00-setup
!.claude/03-architecture
!.claude/08-maintenance
!.claude/policies
!.claude/knowledge
.claude/settings.local.json
```

핵심 포인트:
- **와일드카드 차단(`.claude/*`) 후 명시 negate** — 단순 `.claude/` 차단 후 negate 는 git 룰 상 무효 (헌장 D9).
- **symlink 도 negate 대상** — 다른 멤버 `clone` 시 즉시 호환 경로 동작 (헌장 D10).
- **`.claude/settings.local.json` 은 명시 차단** — 와일드카드에 묻혀 무심코 추적되지 않도록 마지막에 한 번 더 명시.

### 단계 3: 추적 활성화 검증

```bash
git ls-files --others --exclude-standard | grep -E "^(\.claude|docs)/"
```

다음 항목이 출력되어야 정상:
- `.claude/` 운영 자산 (CLAUDE.md, lifecycle.md, ...)
- `.claude/` 호환 symlink (00-setup, 03-architecture, ...)
- `docs/` 신규 승격 디렉토리의 모든 파일

다음 항목은 *출력되지 않아야* 정상 (차단 유지):
- `.claude/local/`
- `.claude/settings.local.json`

### 단계 4: cross-reference 갱신 (선택)

승격된 자산에 대한 *진입점 파일*(`CLAUDE.md`, `lifecycle.md`, `docs/knowledge/index.md` 등) 안의 경로 참조를 `docs/<new>/` 로 갱신한다.

`.claude/<old>` 참조는 symlink 가 처리하므로 *반드시 갱신할 필요는 없으나*, 신규로 작성하는 참조는 `docs/<new>` 로 통일하는 것이 일관됨.

---

## 분류 가이드 (왜 그 위치인가)

새 산출물 카테고리가 생기면 다음 질문으로 분류:

1. **누가 읽는가?** — 팀 전체·외부 협업자가 읽으면 → 공유. 플러그인·AI 만 읽으면 → 운영. 본인만 읽으면 → 로컬.
2. **누가 쓰는가?** — 사람이 의도적으로 작성하면 → 공유 후보. 플러그인이 자동 갱신하면 → 운영. 일시적 작업 산출물이면 → 로컬.
3. **회귀 시 영향?** — 다른 멤버 머신에 없으면 작업 중단되면 → 공유 또는 운영. 본인만 영향이면 → 로컬.
4. **변경 빈도?** — 분기/연 단위 → 공유. 매일/매 작업 → 운영 또는 로컬.

3계층 분류가 *애매한* 자산은 *운영* 으로 시작 → 사용 패턴 관찰 후 재분류.

---

## 자주 묻는 질문

**Q: 모든 프로젝트에 적용해야 하나?**
A: 아니. v0.7.x 이전의 `.claude/` 전체 차단 패턴은 *그대로 유지 가능*. 본 분류는 *팀 협업 가치가 크고 적극 활용하는 프로젝트*용. 1인 사용·실험 프로젝트는 단순 차단도 충분.

**Q: 모든 디렉토리를 승격해야 하나?**
A: 아니. *PoC 1개* 부터 시작해도 무방. 가장 가치 큰 것부터 (`03-architecture` 또는 `policies`).

**Q: 운영 자산을 docs 로 옮기면 안 되나?**
A: 헌장 D4 — `lifecycle.md` 같은 자산은 *플러그인이 갱신*한다. `docs/` 로 옮기면 외부 도구가 무심코 편집할 위험. *드문 케이스*에서는 옮길 수 있지만 본 헌장 갱신 우선.

**Q: 승격 후 다시 `.claude/` 로 되돌릴 수 있나?**
A: 가능하지만 비추천. git history 가 분산되어 추적 어려움. 옮기기 전 신중히 결정.
