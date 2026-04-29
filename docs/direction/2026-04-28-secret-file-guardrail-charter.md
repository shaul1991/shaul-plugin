# 시크릿 파일 접근 가드레일 헌장

- **작성일**: 2026-04-28
- **반영 출시**: v0.7.0
- **관련 커밋**: (출시 시 추가)
- **상태**: Active
- **상위 헌장**: `2026-04-28-claude-output-charter.md`(v0.4.0)

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화).

### (1) 초기 요구 — 무조건 적용 보안규칙

> .env나 .env.\*와 같이 secret 파일은 default로 접근 제한할 수 있어야한다.
> 이 규칙은 플러그인의 step과 skill 상관없이 무조건 적용되어야 할 보안규칙이다.

### (2) 추가 요구 — 사용자 정책 JSON 직접 관리

> 차단해야할 파일의 목록을 .claude 의 폴더에서 관리할 수 있어야한다.
> 2개로 나눈다. 항상 차단할 파일과 읽기전에 물어봐야할 파일을 등록하여야 한다.
> json으로 직접 관리할 수 있어야 한다.

### (3) Opt-out 결정

> env var 하나만 (`CLAUDE_PLUGIN_SECRET_GUARD=off`).

## 도출한 원칙 (5개)

1. **무조건 적용.** 본 가드는 플러그인의 어느 step·skill·에이전트에서 호출되든 *동일하게* 적용된다. skill 별 우회 경로를 만들지 않는다.
2. **두 카테고리 — 사용자 직접 편집.** `always_block`(deny) 과 `ask_before_read`(ask) 는 *사용자가 JSON 한 파일* 만 편집해서 등록·삭제한다. 카테고리를 더 늘리지 않는다(단순성). 우선순위: `always_block` > `ask_before_read`.
3. **정책 파일 위치 = `.claude/secret-guard.json`.** working state(`.claude/local/`)가 아닌 정책 영역(`.claude/` 직속). 부재 시 내장 기본값 사용.
4. **Opt-out 은 env var 하나.** `CLAUDE_PLUGIN_SECRET_GUARD=off|0|false` 일 때만 가드 우회. 세션 단위·명시적·트레이스 가능.
5. **차단/질문 결정은 도구 인터셉션으로 직접.** `permissions.deny` 를 ship 한 settings.json 은 채택하지 않는다 — 사용자 `settings.local.json` 우선순위가 plugin settings 보다 높아 *무조건 적용* 보장이 깨진다. 훅(`PreToolUse`)으로 일원화.

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | `PreToolUse` 훅 + matcher `Read|Edit|Write|Bash` | 사용자 요구 (1) — 모든 도구 호출에 적용. matcher 미스 시 훅 호출 자체가 안 일어남(`Glob/Grep/...` 자유). |
| D2 | 정책 파일 = `.claude/secret-guard.json` (직속) | 사용자 요구 (2). working state(`.claude/local/`) 가 아닌 *영구 정책* 위치. |
| D3 | 정책 파일 부재 시 내장 기본값 — `.env`, `.env.*` 차단 + 템플릿 접미사 예외 | 사용자 요구 (1) — 기본 활성. 빈 정책으로 *방어 무력화* 되지 않도록 안전 기본값. |
| D4 | 카테고리 우선순위: `always_block` > `ask_before_read` (양 카테고리 동시 매치 시 deny 우선) | 더 강한 보호가 이긴다. 안전 default. |
| D5 | 템플릿 접미사 예외(`.example`, `.sample`, `.template`, `.dist`) 양 카테고리 공통 적용 | 산업 통용 관행. 이들 파일은 일반적으로 *비밀이 아니다*. |
| D6 | 패턴 문법 = fnmatch 글롭(`*`, `?`, `[..]`) | regex 보다 사용자 가독성·예측성 우위. 충분히 표현력 있음(`.env.*`, `id_rsa*`, `*.pem`). |
| D7 | 매칭 대상 = *basename* (path 의 마지막 `/`-segment) | 디렉터리 경로 우회(`./../etc/.env`)를 자동 흡수. 사용자가 패턴에 `**/` 같은 표현을 넣을 필요 없음. |
| D8 | Bash 명령어 토큰화 → 각 토큰의 basename 추출 | `cat .env`, `source .env`, `grep KEY .env`, `cp .env /tmp/` 등 다양한 형태 흡수. shlex 우선 + 실패 시 whitespace fallback. |
| D9 | Opt-out = env var `CLAUDE_PLUGIN_SECRET_GUARD` 단독 | 사용자 답변 (3). 플래그 파일·권한 파일 우회 경로를 만들지 않는다. 우회 시 stderr 알림. |
| D10 | 정책 JSON 파싱 실패 시 *내장 기본값으로 폴백* + stderr 경고 | 잘못된 사용자 편집으로 인한 *방어 무력화* 방지. 빈 파일/오타로 가드가 풀리지 않도록. |
| D11 | python3 부재 시 graceful skip + stderr 경고 | 기존 훅 패턴 계승. 단 보안 가드 특성상 *명확한 경고*. |
| D12 | settings.json `permissions.deny` ship 안 함 | 원칙 5. 사용자 settings.local.json 이 plugin settings 우선순위보다 높아 무조건 적용 보장이 깨짐. |
| D13 | `Read/Edit/Write/Bash` 외 도구는 matcher 미스 → 훅 호출 자체 안 됨 | `Glob`, `Grep`, `WebFetch`, MCP 도구 등은 별도 영향 없음. 본 가드 범위는 *파일 콘텐츠 직접 접근* + *셸 실행*. |

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 위반 시 본 문서를 먼저 갱신하거나 설계를 바꾼다.

1. **무조건 적용 보장.** skill·step·agent 단위로 가드 우회 경로를 만들지 않는다. 우회는 *세션 단위 env var* 하나뿐.
2. **카테고리 추가 금지(잠정).** v0.7.0 카테고리 2개(`always_block`, `ask_before_read`)를 유지. 추가 필요 시 본 헌장 갱신 후 도입(예: `audit_log_only`).
3. **자동 콘텐츠 스캔 금지.** 본 가드는 *경로 기반*. 파일 *내용* 토큰 탐지(예: `AKIA...` AWS 키 패턴) 는 별도 라운드 — 채택 시 별도 헌장.
4. **사용자 settings.local.json 자동 수정 금지.** 우선순위 깨짐 + 사용자 영역 침범. 도구 인터셉션으로만 강제.
5. **정책 파일 위치 변경 금지.** `.claude/secret-guard.json` 고정. working state(`.claude/local/`)나 외부 영역(`docs/`, 루트)에 *기본 위치*를 두지 않는다. 사용자가 promotion(이동/심링크) 으로 팀 공유 결정.
6. **다른 AI 도구 통합 금지.** 본 가드는 Claude Code PreToolUse 훅 한정. `.cursor/rules`, `.codex/...` 같은 다른 도구의 권한 시스템에 자동 쓰지 않는다(claude-output-charter 원칙 5 계승).
7. **시크릿 파일군 자동 부풀리기 금지.** v0.7.0 기본값은 `.env`, `.env.*` 만. 다른 파일군(`id_rsa`, `*.pem`, `.aws/credentials` 등) 은 사용자가 *직접* 정책 JSON 에 추가. 플러그인 기본값 확장은 본 헌장 갱신 후에만.

## 관련 문서

- `CHANGELOG.md` `[0.7.0]` 항목 — 출시 내역.
- `claude-code-plugin/project-lifecycle/hooks/secret-guard.sh` — 본 헌장의 절차적 구현(PreToolUse 훅).
- `claude-code-plugin/project-lifecycle/hooks/secret-guard-template.json` — 사용자 정책 시작 샘플.
- `claude-code-plugin/project-lifecycle/hooks/hooks.json` — `PreToolUse` 등록.
- `docs/direction/2026-04-28-claude-output-charter.md` — 상위 출력 단일성·도구 비종속 원칙.
- Claude Code Hooks 공식 — `hookSpecificOutput.permissionDecision: allow|deny|ask`, exit code 2 = block, matcher = regex.
