# `.claude/` 단일 산출물 위치 및 사용자 결정 추적 헌장

- **작성일**: 2026-04-28
- **반영 출시**: v0.4.0
- **관련 커밋**: `80690c1` (Release v0.4.0: move all plugin outputs under .claude/)
- **상태**: Active

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화):

### (1) 초기 요구 — 4개 항목

> 아래는 플러그인을 설치하여 사용하는 사용자와 프로젝트 입장에서 필요한 작업 내용이다.
> - 00-setup 실행시 프로젝트의 .claude 폴더 전체를 gitignore 하라.
> - 플러그인에서 발생하는 모든 산출물은 .claude 안에 작업에 따라 폴더별로 알맞게 생성되어야한다.
> - 프로젝트에서는 최대한 프로젝트에 대한 코드만 작성되어야 한다.
> - claude code 외에 codex나 gemini등 다른 AI tool이 추가된다면 계속 추가되므로 유지보수 포인트가 쌓이게 된다.

### (2) 추가 요구 — 사용자 결정 기반 추적

> 사용자의 결정 및 필요에 의해서만 git tracking 되는 구조여야한다.

### (3) 추가 요구 — `docs/`로의 수동 승격

> 발생한 산출물에서 필요한 문서 혹은 자료 등이 있다면 docs/ 폴더로 사용자가 직접 옮겨 git tracking 되도록 할 것 이다.

## 도출한 원칙 (5개)

1. **프로젝트 루트는 프로젝트 코드만 담는다.** 플러그인이 만드는 어떤 파일도 사용자 프로젝트 루트나 `docs/` 같은 사용자 영역에 *자동으로* 떨어져선 안 된다.
2. **모든 플러그인 산출물은 `.claude/` 하위에 단계·작업별 폴더로 정리된다.** 단일 출력 영역 원칙(Single Output Surface).
3. **`.claude/` 폴더 전체를 기본 ignore한다.** `00-setup`과 SessionStart 훅이 `.gitignore`에 `.claude/` 한 줄을 등록한다.
4. **git 추적은 사용자의 명시적 결정으로만 일어난다.** 공유가 필요한 산출물은 사용자가 `.claude/` 밖(예: `docs/`)으로 직접 *이동*시킨다. `git add -f`나 un-ignore 라인은 권장하지 않는다(가능하지만 우회로 간주).
5. **도구 비종속(Tool-agnostic isolation).** 향후 Codex·Gemini 등 다른 AI 도구가 추가되어도 각 도구가 자기 폴더(`.codex/`, `.gemini/`)에만 가두면 프로젝트 트리는 여전히 깨끗하다. 이 플러그인은 자기 영역(`.claude/`) 밖에 절대 손대지 않는다.

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | `CLAUDE.md`는 루트가 아닌 `.claude/CLAUDE.md`에 둔다 | Claude Code가 양쪽 모두 프로젝트 메모리로 자동 로드함. 후자에 두면 원칙 1을 만족하면서 동작상 차이 없음. |
| D2 | `.editorconfig` 자동 생성을 제거한다 | 에디터가 루트에서 직접 읽어야 의미가 있음 → 원칙 1과 본질적 충돌. 샘플 스니펫만 `team-conventions-template.md`로 옮겨 사용자가 *옵트인* 생성. |
| D3 | 단계 폴더는 `.claude/<NN-phase>/` 직속에 둔다 (`outputs/` 같은 추가 래퍼 없음) | v0.3.x의 `docs/<NN-phase>/`와 1:1 치환되어 학습비용 최소. `local/`은 이미 형제 폴더로 존재하므로 향후 `cache/` 등 형제 추가도 자연스러움. |
| D4 | `.gitignore` 라인은 `.claude/` 한 줄 (전체 폴더). 동의어(`.claude`, `.claude/*`)는 중복으로 보지 않음 | 원칙 3 직접 구현. |
| D5 | 산출물 "승격(promotion)"은 사용자가 `.claude/` 밖으로 *이동*하는 단순 동작 | `git add -f`나 `!.claude/<path>` un-ignore보다 (a) 직관적이고, (b) 자연스럽게 추적되며, (c) 어디로 옮길지를 사용자가 결정한다는 원칙 4와 정합. |
| D6 | v0.3.x → v0.4.0 마이그레이션은 *사용자 수동* + 훅 보조(`.gitignore` 라인 자동 교체) | `docs/` 안의 어떤 파일이 플러그인 산출물이고 어떤 것이 사용자 작성물인지 구분할 수 없음 → 자동 이동 위험. 단 gitignore 라인은 명확히 플러그인 소유이므로 훅이 자동 처리. |
| D7 | SessionStart 훅이 레거시 `.claude/local/` 라인을 자동으로 `.claude/`로 교체 | 사용자가 `00-setup`을 다시 돌리지 않아도 무중단으로 v0.4.0 정합 상태에 도달. 멱등. |

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 새 기능·산출물·통합을 추가할 때 다음을 위반하면 이 문서를 먼저 수정하거나(=원칙 변경의 근거 기록) 설계를 바꾼다.

1. **신규 산출물의 위치 = `.claude/` 안.** 절대 사용자 루트나 `docs/`에 직접 쓰지 않는다.
2. **자동 git tracking 금지.** 어떤 산출물도 기본 추적 대상이 되지 않는다.
3. **기본은 ignore, 추적은 옵트인.** 새 산출물이 "팀 공유가 자연스러운" 종류라면(예: PRD), 그 추적은 사용자의 *이동* 동작으로만 일어난다는 점을 사용자 문서에 명시한다.
4. **다른 AI 도구를 가정하지 말 것.** 다른 도구의 폴더(`.codex/`, `.gemini/`)에 쓰는 통합을 만들지 않는다. 우리 플러그인의 책임은 `.claude/` 안으로 끝난다.
5. **루트 직접 생성은 `.gitignore` 한 줄 추가만 허용.** 그 외 어떤 루트 파일(`CLAUDE.md`, `.editorconfig`, README 등)도 자동 생성하지 않는다. 향후 Claude Code 표준으로 루트 위치가 강제되는 새 파일 형식이 생기면 그때 이 헌장을 갱신한다.
6. **마이그레이션은 가능한 한 자동·무중단.** 산출물 이동처럼 사용자 의도 추정이 필요한 동작은 자동화하지 않되, 마커 라인·메타데이터처럼 명확히 플러그인 소유인 것은 훅이 무중단으로 갱신한다.

## 관련 문서

- `CHANGELOG.md` `[0.4.0]` 항목 — 출시 내역 및 마이그레이션 레시피
- `claude-code-plugin/project-lifecycle/skills/governance/SKILL.md` — "왜 `.claude/` 전체를 ignore 하는가" 섹션
- `claude-code-plugin/project-lifecycle/skills/00-setup/SKILL.md` — `.gitignore` 라인 등록과 `.claude/CLAUDE.md` 생성 절차
- `claude-code-plugin/project-lifecycle/hooks/bootstrap-local.sh` — SessionStart 자동 부트스트랩 및 레거시 라인 업그레이드
- `claude-code-plugin/project-lifecycle/README.md` — "산출물 공유 (사용자 결정에 의한 추적)" 섹션 및 v0.3.x → v0.4.0 마이그레이션 안내
