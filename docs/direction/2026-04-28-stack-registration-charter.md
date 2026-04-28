# 사용자 입력 기반 기술 스택 등록·갱신 헌장

- **작성일**: 2026-04-28
- **반영 출시**: v0.5.0
- **관련 커밋**: (출시 시 추가)
- **상태**: Active

## 사용자 원문 요구사항

세션 중 사용자가 보낸 메시지를 시간순으로 보존한다(의역·축약 최소화).

### (1) 초기 요구 — 기술 스택 감지 / 다중 프로젝트 / 다른 도구 비교

> 해당 플러그인을 사용하는 사용자의 프로젝트에 대한 기술 stack 등을
> 어떻게 detect할 수 있나? 관련하여 조사가 필요하다.
>
> - 만약 사용자의 프로젝트가 php+laravel 과 kotlin+springboot 2개 혹은
>   그 이상일 경우에는 각 프로젝트별 언어와 프레임워크에 대한 detect후
>   각 프로젝트에 맞는 stack 을 관리하여야 한다.
> - 다른 플러그인이나, 다른 AI 에서는 어떻게 해당 내용을 구성할 수 있나?

### (2) 추가 요구 — 자동 detect 가 아니라 사용자 입력 우선

> 최초에는 자동으로 detect하는 구조가 아닌 사용자가 직접 언어와
> 프레임워크를 입력받아서 확인하는 방향으로 하자. 이후에는 이미 결정된
> 프로젝트이므로 작성된 내용을 기반으로 최신화 및 갱신 등을 진행하기만
> 하면 되지 않을까한다.

### (3) 1차 출시 범위 결정 (입력형 질문 응답)

> php+laravel, python+fastapi 우선 이 2가지만 범위로 한정한다.

## 도출한 원칙 (5개)

1. **detector 는 추측하지 않는다.** 권위 있는 사실(authoritative fact)은
   *언제나* 사용자 입력에서 나온다. 매니페스트를 *읽어서 추론*하는 코드는
   본 플러그인이 만들지 않는다.
2. **두 산출물의 1대1 거울.** 사람 가독 ADR(`tech-stack.md`)과 머신 가독
   미러(`.claude/local/stack.json`)는 항상 같은 내용을 다른 형태로
   기록한다. 둘 중 어느 한쪽만 갱신되는 상태를 허용하지 않는다 — 갱신은
   *항상* 03-architecture SKILL 을 통해 함께 일어난다.
3. **다중 프로젝트는 1급 시민이다.** `stack.json.projects[]` 는 길이가 1
   이상이며, 단일 프로젝트도 길이 1 의 동일 구조로 표현된다. 모노레포
   여부에 따라 스키마가 달라지지 않는다.
4. **변경 감지는 알림만, 결정은 사용자.** SessionStart 훅은 변경된
   매니페스트를 발견하면 *알리기*만 하고, 어떤 자동 갱신도 하지 않는다.
   사용자가 `/03-architecture` 를 다시 호출했을 때 *갱신 모드*로 진입해
   사용자 결정에 따라 두 산출물을 갱신한다.
5. **1차 watched 범위는 작은 화이트리스트.** 자동 변경 감지의 기본
   대상은 `composer.json`(PHP+Laravel), `pyproject.toml` /
   `requirements.txt`(Python+FastAPI) 만. 그 외 언어/프레임워크라도
   사용자는 ADR 에 자유롭게 등록할 수 있고, 단지 자동 변경 감지가
   적용되지 않을 뿐이다(`watched_manifests: []`).

## 설계 결정

| ID | 결정 | 근거 |
|----|------|------|
| D1 | 자동 detect 코드를 만들지 않는다(매니페스트 파서 미도입) | 원칙 1. 사용자 요구 (2). 추측의 false positive 보다 사용자 입력의 권위가 우선. |
| D2 | 산출물은 두 파일 — `tech-stack.md`(사람) + `.claude/local/stack.json`(머신) | 원칙 2. SKILL.md, 다른 단계, 훅이 *읽어 쓸* 머신 형태가 별도로 필요. ADR 본문 파싱은 fragile. |
| D3 | 두 파일 모두 `.claude/` 안. 자동 git tracking 없음 | 04-charter(2026-04-28-claude-output-charter) 의 원칙 1·2·3·4 와 정합. 외부 공유는 사용자 *이동* 으로만. |
| D4 | `stack.json.projects[]` 단일 배열 구조. 단일/다중 프로젝트 동일 스키마 | 원칙 3. 사용자 핵심 요구(다중 프로젝트별 분리 관리)와 직접 정합. |
| D5 | 자동 변경 감지는 *sha256 비교* + *알림만* (자동 갱신 없음) | 원칙 4. 헌장 04 의 D5(추적은 사용자 *이동*)와 같은 정신. |
| D6 | watched_manifests 1차 화이트리스트 = composer.json, pyproject.toml, requirements.txt | 원칙 5. 사용자 결정 Q3 (php+laravel, python+fastapi 만). |
| D7 | 변경 감지 훅(`stack-watch.sh`)은 `bootstrap-local.sh` 옆에 두고 동일 SessionStart 슬롯에 추가 | 신규 skill / MCP / sub-agent 도입 없이 *플러그인 책임의 최소 확장*. 기존 git 가드 패턴 재사용. |
| D8 | 등록 모드와 갱신 모드의 분기는 `.claude/local/stack.json` 의 *존재* 여부 | 단일 진입점(`/03-architecture`)이 상태에 따라 다른 흐름을 타도록 단순화. |
| D9 | python3 의존(JSON 파싱·sha256). 부재 시 graceful skip(안내 후 종료) | 표준 macOS·Linux 환경 가정. 외부 의존(jq) 추가 없이 stdlib 만. |

## 미래 변경 시 지킬 것

이 헌장은 후속 변경에 대한 **불변 가드레일**이다. 다음을 위반하면 본
문서를 먼저 갱신하거나(=원칙 변경의 근거 기록) 설계를 바꾼다.

1. **자동 추측 금지.** 사용자에게 묻지 않고 매니페스트에서 언어·
   프레임워크를 추론해 ADR 에 *기록*하지 않는다. 1차 범위 확장은
   *변경 감지(=알림)* 의 watched 범위만 늘리는 형태로만 한다.
2. **두 파일 동기화 강제.** `tech-stack.md` 만 갱신되거나 `stack.json`
   만 갱신되는 경로를 만들지 않는다. SKILL 이 항상 둘을 같이 쓴다.
3. **자동 갱신 금지.** SessionStart 훅이 직접 `stack.json` 을 쓰는
   경로는 만들지 않는다. 훅의 책임은 *읽고 알리는* 것까지.
4. **루트 / `docs/` 직접 생성 금지.** 04-charter 의 원칙 1·5 그대로 —
   본 기능도 어떤 파일도 사용자 루트나 `docs/` 에 자동 생성하지 않는다.
5. **watched 범위 확장 시 점진성.** 새 언어/프레임워크의 자동 변경
   감지를 추가할 때는 *외부 룰 파일*(`hooks/stack-rules.json`)로 분리
   가능 여부를 검토. 3종 이상 추가될 때 분리 시점.

## 관련 문서

- `CHANGELOG.md` `[0.5.0]` 항목 — 출시 내역 및 마이그레이션 안내
- `claude-code-plugin/project-lifecycle/skills/03-architecture/SKILL.md` —
  Step 1 등록·갱신 흐름과 두 파일 작성 절차
- `claude-code-plugin/project-lifecycle/skills/03-architecture/references/stack-json-template.json` —
  `stack.json` 스키마 v1 예시 (다중 프로젝트 포함)
- `claude-code-plugin/project-lifecycle/hooks/stack-watch.sh` —
  SessionStart 변경 감지 훅
- `docs/direction/2026-04-28-claude-output-charter.md` — 본 헌장이
  계승하는 상위 원칙(`.claude/` 단일 산출물, 자동 git tracking 금지 등)
