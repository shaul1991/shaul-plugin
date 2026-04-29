---
name: codex-reviewer
description: >
  Phase 7 QA의 외부 Codex CLI 리뷰 백엔드. 사용자가 직접 호출하지 않으며,
  `07-qa` 스킬의 Step 0 디스패처가 review-config의 `reviewer: "codex"` 또는
  `"cross"` 값을 만났을 때만 호출된다. OpenAI Codex CLI를 Bash로 실행하여
  Phase 산출물에 대한 품질 평가를 받고, 결과를 `.claude/reviews/`에 저장한다.
metadata:
  phase: "7"
  phase_name: "QA/테스트"
  role: "reviewer-backend"
---

# Codex 리뷰어 백엔드

외부 `codex` CLI 를 호출해 Phase 산출물을 평가하는 절차적 스킬. 페르소나 기반 추론은 `quality-reviewer` 에이전트(Claude 백엔드)와 동일한 평가 프레임워크를 사용하되, 실제 평가 수행 주체가 외부 Codex 모델이라는 점만 다르다.

> ⚠️ 이 스킬은 `07-qa` 스킬이 호출하는 *내부 백엔드*이다. 사용자가 키워드로 직접 트리거하지 않는다. 사용자가 리뷰 백엔드를 바꾸려면 `.claude/review-config.json` 의 `reviewer` 값을 수정하거나 `CLAUDE_PLUGIN_REVIEWER` 환경변수를 사용한다.

## 호출 조건

`07-qa/SKILL.md` Step 0 에서 다음 중 하나로 해석되었을 때:
- `reviewer: "codex"` — 단독 실행
- `reviewer: "cross"` — Claude 리뷰 후 codex 리뷰 순차 실행 (이 스킬은 두 번째 호출에 해당)

## 전제 조건 점검 (스킬 시작 시 필수)

다음을 *순서대로* 확인하고, 실패 시 명시된 동작을 따른다.

| 점검 | 명령 | 실패 시 동작 |
|---|---|---|
| Codex CLI 설치 | `command -v codex` | "codex CLI 미설치 — Claude 리뷰로 폴백합니다." 안내 후 `quality-reviewer` 에이전트로 위임 |
| 인증 확인 | 첫 호출 stderr 에 `auth`/`login` 포함 시 | 폴백 없이 중단. "`codex login` 후 재시도" 안내. 사용자 액션이 필요하므로 자동 폴백 금지. |
| 시크릿 가드 | PreToolUse Bash 훅 | 가드가 차단하면 가드 메시지 그대로 노출. 우회 시도 절대 금지. |

## 실행 절차

### Step 1: 평가 컨텍스트 수집

대상 Phase 의 산출물 경로를 확정한다 (예: Phase 5 리뷰면 `.claude/05-implementation/`, Phase 3 면 `.claude/03-architecture/`). 해당 디렉토리의 마크다운 / 코드 파일을 읽어 컨텍스트로 삼는다.

### Step 2: 프롬프트 파일 작성

프롬프트는 *반드시 파일* 로 저장하여 codex 에 전달한다. 인라인 heredoc 으로 넣지 않는다 — `.env` 류 토큰이 명령줄에 노출되어 secret-guard 가 차단할 수 있다.

- 파일 경로: `.claude/local/codex/<phase>-<ISO8601>.prompt.md`
- 내용: `references/codex-prompt-template.md` 의 형식을 따르되, Step 1 에서 수집한 컨텍스트를 인라인 삽입
- 평가 프레임워크는 `agents/quality-reviewer.md` 의 Phase 별 체크리스트(완결성·품질·정합성·추적성)를 그대로 사용한다 — 두 백엔드의 판정 기준이 동일해야 cross 비교가 의미 있다.

### Step 3: Codex 호출

> 📌 **명령어 라인은 변경 가능성이 높으므로 *한 줄에 모아둔다*.** 설치된 `codex --help` 확인 후 정확한 verb/flag 를 결정한다.

```bash
# === Codex invocation (TBD: verify against `codex --help` after install) ===
PROMPT_FILE=".claude/local/codex/<phase>-<ts>.prompt.md"
OUT_FILE=".claude/reviews/<phase>-codex-<ts>.md"
CODEX_MODEL="${CODEX_MODEL:-}"
CODEX_TIMEOUT="${CODEX_TIMEOUT:-300}"

timeout "$CODEX_TIMEOUT" codex exec ${CODEX_MODEL:+--model "$CODEX_MODEL"} < "$PROMPT_FILE" > "$OUT_FILE.body" 2> "$OUT_FILE.err"
EXIT=$?
# ============================================================================
```

호출 후 `.claude/reviews/<phase>-codex-<ts>.md` 헤더 5줄을 prepend 한다 (감사 재현용):

```
<!-- review-backend: codex -->
<!-- model: $CODEX_MODEL -->
<!-- exit-code: $EXIT -->
<!-- timestamp: <ISO8601> -->
<!-- prompt-hash: $(sha256sum < "$PROMPT_FILE" | cut -c1-12) -->

```

이후 `$OUT_FILE.body` 본문을 이어 붙이고, `$OUT_FILE.err` 의 stderr 는 별도 보존(`.claude/reviews/<phase>-codex-<ts>.err.log`).

### Step 4: 실패 분기

- `EXIT == 124` (timeout) — "codex 응답 시간 초과(${CODEX_TIMEOUT}초). `CODEX_TIMEOUT` env 로 조정 가능. 재시도 또는 Claude 폴백 권유" 안내 후 중단
- `EXIT != 0` 이고 stderr 에 `auth`/`login` — 인증 누락. 폴백 없이 중단
- `EXIT != 0` 그 외 — stderr 노출 후 사용자 판단 (재시도 / Claude 폴백 / 중단 중 선택)
- `EXIT == 0` — 본문 형식 검증: `Verdict: (Go|Iterate|No-Go)` 라인 존재 여부 확인. 없으면 "Codex 출력에 Verdict 라인 누락 — 원본을 사람이 직접 확인 필요" 경고만 추가하고 그대로 저장

### Step 5: Phase 7 핸드오프

- 단독 모드(`reviewer: "codex"`) — `.claude/reviews/<phase>-codex-<ts>.md` 의 Verdict 를 Phase 7 게이트 판정으로 사용
- Cross 모드(`reviewer: "cross"`) — 이 스킬은 codex 결과 파일까지만 생성하고 종료. 비교 파일 생성과 사람 판정 단계는 `07-qa/SKILL.md` Step 0 의 후속 단계가 수행

## 산출물

| 파일 | 내용 |
|---|---|
| `.claude/local/codex/<phase>-<ts>.prompt.md` | codex 에 전달한 프롬프트 (재현용, gitignore 대상) |
| `.claude/reviews/<phase>-codex-<ts>.md` | 평가 결과 본문 (헤더 5줄 + codex 출력) |
| `.claude/reviews/<phase>-codex-<ts>.err.log` | stderr (실패 시 디버깅용) |

## 가이드라인

- 동일한 프롬프트로 재실행 시 결과가 다를 수 있음을 사용자에게 인지시킨다 (LLM 비결정성)
- 모델·타임아웃·flag 변경은 `.claude/review-config.json` 의 `codex` 블록에서만 한다 — 스킬 내부에 하드코딩 금지
- secret-guard 차단을 우회하지 않는다. 차단되면 프롬프트에 시크릿 토큰이 들어간 것이며, 그게 정상 동작이다.

## 참고 자료

- **`references/codex-prompt-template.md`** — codex 에 전달하는 평가 프롬프트 형식
- **`../../agents/quality-reviewer.md`** — Phase 별 평가 체크리스트의 원본 (양 백엔드 공유)
- **`../07-qa/SKILL.md`** — 본 스킬을 호출하는 디스패처 (Step 0)
- **`../../hooks/review-config-template.json`** — `.claude/review-config.json` 의 시작 샘플
