# project-lifecycle 플러그인 출시 준비 작업계획 (Readiness Plan)

- 작성일: 2026-04-28
- 대상 버전: project-lifecycle v0.3.0
- 작성 브랜치: `claude/plugin-status-review-9RmBv`
- 검토 대상: `/home/user/shaul-plugin/claude-code-plugin/project-lifecycle/`
  및 마켓플레이스 배포 아카이브 `claude-code-plugin/project-lifecycle.plugin`

---

## 1. 목표 (Objective)

현재 저장소의 project-lifecycle 플러그인이 사용자가 `claude plugin add`로
설치했을 때 README가 광고하는 모든 기능(특히 SessionStart 자동 부트스트랩)이
정상 동작하도록 출시 준비 상태(production-ready)로 끌어올린다.

## 2. 현 상태 요약 (Status Snapshot)

| 영역 | 상태 | 비고 |
|------|------|------|
| `plugin.json` 매니페스트 | ✅ OK | 필수 필드(name/version/description/author/keywords) 완비. `license` 필드만 미존재. |
| 스킬 (15개) | ✅ OK | Phase 9개 + 크로스커팅 6개 모두 frontmatter+본문 완전. 참조 템플릿 모두 존재. |
| 에이전트 (14개) | ✅ OK | 페르소나·역할·도구권한 정의 완전. |
| SessionStart 훅 (소스) | ✅ OK | `hooks/hooks.json`, `hooks/bootstrap-local.sh` idempotent·git-guard·실행비트 모두 정상. |
| 문서 (README) | ⚠️ 경미 | 루트/내부 README 일관성 양호. 설치 경로 문구가 사용자 cwd에 따라 헷갈릴 수 있음. |
| **`.plugin` 아카이브** | ❌ **STALE/BROKEN** | **`hooks/` 내부 파일 부재**, mojibake 수정본 미반영, 다수 SKILL.md 구버전. |
| LICENSE / CHANGELOG | ❌ 부재 | 마켓플레이스 공개 시 필수 |

### 결론

- **소스 디렉토리** 형태로 직접 로드한다면(`claude-code-plugin/project-lifecycle/`)
  → **즉시 사용 가능**.
- **`.plugin` 아카이브로 배포**한다면 → **즉시 사용 불가**(아래 Blocker 참조).

---

## 3. 발견 사항 — 우선순위별 정리

### 🔴 BLOCKER (배포 차단 — 즉시 수정 필요)

#### B-1. `.plugin` 아카이브에 SessionStart 훅 파일이 누락됨
- 증거:
  ```
  $ unzip -o project-lifecycle.plugin -d /tmp/x
  $ diff -rq /tmp/x claude-code-plugin/project-lifecycle/
  Only in claude-code-plugin/project-lifecycle/hooks: bootstrap-local.sh
  Only in claude-code-plugin/project-lifecycle/hooks: hooks.json
  ```
- 원인: 커밋 `4f910de`(Auto-bootstrap user's project with SessionStart hook)
  이후 아카이브가 재생성되지 않음. 아카이브 내 `hooks/` 디렉토리는 빈 상태로
  들어가 있고 두 파일이 모두 빠짐.
- 영향:
  - 사용자가 `.plugin`을 설치해도 SessionStart 훅이 등록되지 않는다.
  - README와 governance 스킬 문서가 광고하는 “자동 부트스트랩(`.claude/local/plans/`
    생성, `.gitignore` 자동 등록)” 기능이 동작하지 않는다.
  - governance 스킬의 PLAN 단계가 “훅이 실행되지 못한 환경”에서 자체 수행하는
    백업 경로는 살아있으므로 완전한 기능 마비는 아니지만, 광고된 핵심 UX가 깨진다.

#### B-2. `.plugin` 아카이브가 stale — 다수 파일이 구버전
- 증거(아카이브 내 파일 timestamp 2026-04-27 vs git 커밋):
  ```
  Files ./README.md … differ
  Files ./agents/alm-manager.md … differ        (← 08f5b7b mojibake fix 미반영)
  Files ./skills/00-setup/SKILL.md … differ
  Files ./skills/01-ideation/SKILL.md … differ
  Files ./skills/02-planning/SKILL.md … differ
  Files ./skills/03-architecture/SKILL.md … differ
  Files ./skills/04-design/SKILL.md … differ
  Files ./skills/05-implementation/SKILL.md … differ
  Files ./skills/06-infra/SKILL.md … differ
  Files ./skills/07-qa/SKILL.md … differ
  Files ./skills/08-maintenance/SKILL.md … differ
  Files ./skills/gate-keeper/SKILL.md … differ
  Files ./skills/governance/SKILL.md … differ
  Files ./skills/governance/references/execution-plan-template.md … differ   (← 97c3810 mojibake fix 미반영)
  ```
- 영향: 사용자가 깨진 한글(mojibake)이 섞인 구버전 콘텐츠를 받게 된다.

### 🟡 MAJOR (배포 전 강력 권장)

#### M-1. 아카이브 빌드/검증 절차 부재
- 현재 `.plugin` 파일은 수동 zip으로 추정되며, 어떤 절차/스크립트로 만드는지
  저장소 어디에도 기록되어 있지 않다. 위 B-1, B-2가 발생한 근본 원인.
- 영향: 향후 변경마다 아카이브와 소스가 다시 어긋날 위험.

#### M-2. 루트 README 설치 경로 모호성
- 루트 `README.md:31`:
  ```bash
  claude plugin add ./claude-code-plugin/project-lifecycle.plugin
  ```
  사용자가 저장소 루트에서 실행한다는 전제가 명시되지 않아 cwd에 따라 실패 가능.
- 영향: 첫 설치 마찰. (Blocker는 아님 — 보고서 6번 항목은 “심각도 Major이지만
  기능은 동작”으로 분류)

### 🔵 MINOR (출시 후 개선 가능)

- N-1. `LICENSE` 파일 부재 (+ `plugin.json`에 `license` 필드 부재).
- N-2. `CHANGELOG.md` 부재 — v0.1 → v0.3 변경 이력 추적 불가.
- N-3. `commands/` 디렉토리 부재 — 스킬 트리거 기반 설계라 의도된 것이지만,
  `/dashboard`, `/governance` 같은 명시 슬래시 커맨드를 추후 제공하면 UX 개선.

---

## 4. 작업 항목 (Work Items)

각 작업은 “What → How → Verify → DoD”의 4요소로 정의한다.

### Task 1. SessionStart 훅을 포함해 `.plugin` 아카이브 재생성  (🔴 B-1, B-2)

- What: 최신 소스로 `claude-code-plugin/project-lifecycle.plugin`을 다시 만든다.
- How:
  ```bash
  cd claude-code-plugin
  rm -f project-lifecycle.plugin
  ( cd project-lifecycle && zip -r ../project-lifecycle.plugin . \
      -x ".DS_Store" -x "*/.DS_Store" )
  ```
  - 압축 루트가 `project-lifecycle/`의 *내용물*이 되어야 한다(현재 아카이브와
    동일한 구조: 최상위에 `agents/`, `skills/`, `hooks/`, `.claude-plugin/`, `README.md`).
- Verify:
  ```bash
  unzip -l claude-code-plugin/project-lifecycle.plugin | grep -E "hooks/(hooks\.json|bootstrap-local\.sh)"
  # → 두 파일이 모두 표시되어야 함
  diff -rq <(mkdir -p /tmp/v && cd /tmp/v && unzip -oq /home/user/shaul-plugin/claude-code-plugin/project-lifecycle.plugin && pwd | xargs -I{} echo {}) \
            claude-code-plugin/project-lifecycle/
  # → "Only in" / "differ" 가 없어야 함
  ```
- DoD: 아카이브와 소스 디렉토리가 바이트 단위로 동일(`diff -rq` 출력 0줄).

### Task 2. 아카이브 빌드 스크립트화  (🟡 M-1)

- What: `scripts/build-plugin.sh` (또는 동등) 추가, 향후 변경 후 아카이브 재생성을
  단일 명령으로 보장.
- How: 위 Task 1의 명령을 스크립트화하고 `set -eu`, 결과 파일 크기/엔트리 수
  검증 단계 포함. README에서 “수동 빌드 시 이 스크립트 사용” 명시.
- Verify: 스크립트 실행 후 Task 1의 검증 명령이 통과.
- DoD: `bash scripts/build-plugin.sh` 만으로 재생성 가능, 결과가 stale 검증을 통과.

### Task 3. 루트 README 설치 안내 명료화  (🟡 M-2)

- What: 설치 명령어가 사용자 cwd에 의존하지 않게 안내.
- How: `README.md:30-32` 섹션을 다음 형태로 수정:
  ```bash
  # 저장소 루트에서:
  claude plugin add ./claude-code-plugin/project-lifecycle.plugin
  ```
  또는 “이 저장소의 어떤 위치에서 실행하든 동작하도록 절대경로 사용” 안내 추가.
- Verify: 설치 명령 그대로 복사 → README 파트의 cwd 가정과 실제 디렉토리 구조가 일치.
- DoD: 신규 사용자가 README를 위에서 아래로 따라가서 막힘 없이 설치 완료.

### Task 4. LICENSE 추가  (🔵 N-1)

- What: 저장소 루트에 LICENSE 파일 추가, `plugin.json`에 `license` 필드 추가.
- How: 라이선스 선택(MIT 권장) → SPDX 식별자 사용. 작성 후 `plugin.json`에
  `"license": "MIT"` 한 줄 추가.
- Verify: GitHub UI에서 라이선스가 자동 인식.
- DoD: 라이선스 파일 존재 + plugin.json 갱신.

### Task 5. CHANGELOG 시드  (🔵 N-2)

- What: `CHANGELOG.md`에 0.1 → 0.3 이력을 git log 기반으로 정리.
- How: `git log --oneline 47db8dc..HEAD`를 토대로 Keep a Changelog 형식으로 작성.
- Verify: 가장 최근 항목이 v0.3.0 = 현재 plugin.json 버전과 일치.
- DoD: CHANGELOG 존재, 버전 헤더가 SemVer.

### Task 6. (선택) 자동화 검증  (🔵)

- What: `pre-commit` 또는 CI 검증 — “소스가 변경된 PR에서 `.plugin`이 stale이면
  실패”하도록 보장.
- How: GitHub Actions 워크플로우에서 Task 1의 verify 명령을 실행, 차이가 있으면
  실패. (선택 사항: 머지 시 아카이브를 자동 재빌드하여 커밋.)
- Verify: 의도적으로 소스만 바꾼 PR이 CI에서 실패해야 한다.
- DoD: 향후 동일 회귀(B-1, B-2)가 사람 손 없이 검출됨.

---

## 5. 의존성 및 리스크 (Dependencies & Risks)

| 리스크 | 확률 | 영향 | 대응 |
|--------|------|------|------|
| 아카이브 압축 형식이 Claude Code 마켓플레이스 스펙과 다를 가능성 | 낮음 | 중 | 현재 아카이브의 zip 헤더(`PK`)와 동일하게 zip 사용. 결과를 실제로 `claude plugin add` 해서 smoke test. |
| 빌드 스크립트화 후 기존 워크플로(수동 빌드)와 충돌 | 낮음 | 낮음 | README에 “수동/스크립트 양쪽 모두 동일 결과” 명시. |
| LICENSE 선택을 사용자(저작자)가 변경하고 싶을 수 있음 | 중간 | 낮음 | 본 작업에서는 “MIT 권장”만 제안하고, 실제 적용은 사용자 컨펌 후 진행. |

---

## 6. 성공 기준 (Success Criteria)

- [ ] `unzip -l claude-code-plugin/project-lifecycle.plugin` 결과에 `hooks/hooks.json`,
      `hooks/bootstrap-local.sh`가 포함된다.
- [ ] `diff -rq <archive 풀린 결과> claude-code-plugin/project-lifecycle/` 출력이 비어 있다.
- [ ] `bash scripts/build-plugin.sh` 한 줄로 위 두 조건이 재현된다.
- [ ] README의 설치 명령어가 cwd 가정 명시.
- [ ] (선택) 저장소에 `LICENSE`, `CHANGELOG.md`가 존재한다.

## 7. 검증 방법 (Verification)

1. 아카이브 내용 동일성: `diff -rq` 무차이.
2. 설치 smoke test: 임시 디렉토리에서 `git init`, 그 안에서 `claude plugin add
   <repo>/claude-code-plugin/project-lifecycle.plugin` 후 새 세션 → `.claude/local/plans/`
   디렉토리와 `.gitignore`의 `.claude/local/` 한 줄이 자동 생성된다.
3. 스킬·에이전트 1건 호출(예: `governance` 스킬) 후 본문 한글이 깨지지 않는다(mojibake 회귀 없음).

## 8. 재검증 기준 (Re-verification)

- [ ] 6번 성공 기준 모두 통과.
- [ ] B-1, B-2가 동일 절차에서 재발하지 않는다(수동 회귀 1회).
- [ ] CI(선택)가 stale 회귀를 검출 가능.
- [ ] README의 광고 기능과 실제 설치본의 동작이 일치한다.

---

## 9. 권장 진행 순서

1. (선결) 본 계획서 사용자 승인 → governance Stage 2 통과.
2. **Task 1** 실행(아카이브 재생성) — Blocker 해소, 단일 PR로 가능.
3. **Task 3** 실행(README 명료화) — 텍스트 수정, 동일 PR에 묶음.
4. **Task 2** 실행(빌드 스크립트) — 회귀 방지, 별도 PR 권장.
5. **Task 4, 5** — 출시 전 선택, 또는 v0.3.1 릴리즈와 함께.
6. **Task 6** — 운영 안정화 후 추가 도입.

## 10. 참고

- 본 계획서는 `governance` 스킬의 실행계획서 템플릿을 따른다.
- 본 계획서는 git-tracked 영역(`docs/plans/`)에 저장하여 PR/리뷰 흐름에서
  공유 가능하다. 향후 동일 성격의 계획은 `.claude/local/plans/<branch>/...` 임시 영역
  → 합의 후 `docs/plans/`로 promote하는 흐름을 권장.
