---
name: 00-setup
description: >
  프로젝트 초기 설정 및 컨텍스트 로딩 단계. "프로젝트 설정", "초기 설정",
  "프로젝트 시작", "환경 설정", "컨벤션 정의", "프로젝트 초기화",
  "setup", "project init", "context loading" 요청 시 사용.
metadata:
  phase: "0"
  phase_name: "초기 설정"
---

# Phase 0: 초기 설정 (Setup & Context Loading)

프로젝트를 시작하기 전, 에이전트가 일관성 있게 작동하기 위한 기본 룰과 환경을 세팅한다.
모든 Phase에 앞서 수행되어야 하며, 프로젝트의 "헌법"에 해당한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/00-setup/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
   - 목표, 범위, 실행 단계, 성공 기준을 구체적으로 기술
2. **REVIEW** — 실행계획서를 사용자에게 제시하고 명시적 수락을 받는다
   - 승인(Approved) → 실행 절차로 진행
   - 수정 요청(Revise) → 계획 수정 후 재검증
   - 거부(Rejected) → 근본적 재설계
3. **EXECUTE** — 수락된 계획에 따라 아래 실행 절차를 수행한다
4. **RE-VERIFY** — 실행 완료 후 산출물과 결과를 재검증한다
   - 성공 기준 대비 달성 여부 확인
   - 산출물 완결성 및 이전 Phase와의 정합성 검증
   - 교훈(Lessons Learned) 기록
   - 통과(Pass) → 다음 Phase 진행 / 미달(Fail) → 보완 실행 또는 계획 재수립

> ⚠️ 실행계획 수립과 수락 없이 실행에 들어가지 않는다. 실행 후 재검증 없이 다음 Phase로 넘어가지 않는다.

## 실행 절차

### Step 1: 프로젝트 메타데이터 정의
프로젝트의 기본 정보를 정의한다:

1. **프로젝트명** — 공식 이름, 코드네임 (있을 경우)
2. **프로젝트 유형** — 웹앱, 모바일앱, API, 라이브러리, CLI 도구 등
3. **팀 구성** — 역할별 인원 (또는 1인 프로젝트)
4. **타임라인** — 대략적 일정, 마일스톤 기한
5. **주요 이해관계자** — 의사결정자, 리뷰어, 최종 사용자

### Step 2: 개발 환경 컨벤션 설정
팀(또는 개인)의 작업 규칙을 정의한다:

1. **프로그래밍 언어 및 런타임** — 버전 포함 (예: Node.js 20, Python 3.12)
2. **패키지 매니저** — npm, pnpm, yarn, pip, poetry 등
3. **코드 스타일** — Prettier, ESLint, Black, Ruff 등 도구와 규칙
4. **Git 전략** — GitHub Flow, Git Flow, Trunk-based 중 선택
5. **커밋 규칙** — Conventional Commits 사용 여부 및 타입 정의
6. **브랜치 네이밍** — `feature/`, `fix/`, `chore/` 등 접두사 규칙
7. **문서 언어** — 한국어/영어/혼합

### Step 3: 프로젝트 구성 파일 생성
에이전트가 참조할 프로젝트 구성 파일을 생성한다:

1. **`.claude/CLAUDE.md`** — 에이전트에게 프로젝트 컨텍스트를 전달하는 핵심 파일
   - 프로젝트 개요, 기술 스택, 디렉토리 구조, 코딩 컨벤션 요약
   - 루트가 아닌 `.claude/CLAUDE.md`에 둔다 — Claude Code가 양쪽 모두 프로젝트 메모리로 자동 로드하므로 동작상 차이가 없으며, 프로젝트 루트는 깨끗하게 유지된다.
2. **`.gitignore`** — 버전 관리 제외 파일 목록
   - 다음 한 줄을 반드시 포함시킨다 (플러그인 산출물 전체 보호):
     ```
     .claude/
     ```
   - 이미 동일 경로(또는 `.claude`, `.claude/*`)가 등록되어 있으면 중복 추가하지 않는다.
   - 레거시 `.claude/local/`만 있으면 `.claude/`로 교체한다 (SessionStart 훅과 동일한 동작).
   - `.gitignore` 파일이 없으면 새로 만든다.
   - 이 한 줄로 플러그인이 생성하는 모든 산출물이 git 추적에서 제외된다. 특정 산출물(예: PRD)을 팀과 공유하고 싶다면, 해당 파일을 사용자가 `.claude/` 밖(예: `docs/02-planning/prd.md`)으로 직접 이동시킨다. `git add -f` 같은 우회는 권장하지 않는다.
3. **`.claude/` 디렉토리 산출물 작성** — ALM 추적 파일과 단계 산출물을 모두 `.claude/` 하위에 생성한다.

### Step 4: ALM 추적 파일 초기화
프로젝트 수명주기 추적을 위한 기본 파일을 생성한다:

1. **`.claude/lifecycle.md`** — Phase별 진행 이력, 게이트 판정, 변경 이력
2. **`.claude/tech-debt-registry.md`** — 기술 부채 기록부 초기화
3. **`.claude/kpi-definitions.md`** — 성공 지표 정의 문서 초기화

### Step 5: 산출물 생성
- **`.claude/00-setup/project-config.md`** — 프로젝트 메타데이터 및 컨벤션
- **`.claude/00-setup/team-conventions.md`** — 팀 컨벤션 상세
- **`.claude/CLAUDE.md`** — 에이전트 컨텍스트 파일
- **`.claude/lifecycle.md`** — ALM 추적 파일
- **`.claude/tech-debt-registry.md`** — 기술 부채 기록부
- **`.claude/kpi-definitions.md`** — 성공 지표 정의서

### Step 6: knowledge 영역 권유 (v0.6.0+, 사용자 결정)

> 자동 생성하지 않는다. 단지 *권유*만 한다. 헌장 D5 — 본 플러그인은 `.claude/knowledge/` 영역도, 루트 `AGENTS.md` 도 *자동으로 만들지 않는다*. 사용자가 `/knowledge` 를 직접 호출할 때만 등록된다.

사용자에게 다음을 안내한다(이번 setup 에서는 등록하지 않아도 무방):

> "신규 입사자 온보딩과 다른 AI 도구(Cursor·Codex·Copilot 등) 싱크를 위해 *사내 3종 문서(용어집·기획요구·기술요구)* 를 별도 묶음으로 관리할 수 있습니다. PRD/설계가 어느 정도 잡힌 이후에 `/knowledge` 로 등록하시면 됩니다. 등록 후에는 루트 `AGENTS.md` 로 *수동 승격*하면 다른 AI 도구도 도달할 수 있습니다(권장)."

상세 절차는 `claude-code-plugin/project-lifecycle/skills/knowledge/SKILL.md` 와 헌장 `docs/direction/2026-04-28-three-doc-set-charter.md` 참조.

### Step 7: 시크릿 파일 가드 정책 리뷰 (v0.7.0+, 보안 의식 형성)

> Phase 0 의 보안 의식 형성 단계. 가드 자체는 *플러그인 설치만으로 이미 활성*(PreToolUse 훅) 이지만, 사용자가 *지금 한 번 명시적으로 확인*하는 게 초기 보안 사고 방지의 가장 큰 효과를 낸다. 헌장 D3·`secret-file-guardrail-charter` 참조.

#### 7-1. 가드 활성 사실 안내

사용자에게 다음을 *반드시 한 번* 알린다:

> "본 플러그인은 `Read`/`Edit`/`Write`/`Bash` 도구가 `.env`, `.env.*` 등 시크릿 파일을 만지려 시도하면 *무조건* 차단합니다. 어느 step·skill·에이전트에서 호출되든 동일하게 적용됩니다(skill 별 우회 경로 없음). `.env.example`/`.sample`/`.template`/`.dist` 같은 템플릿은 통과합니다.
>
> 정책은 별도 등록 없이도 *내장 기본값* 으로 즉시 활성됩니다. 일시 해제는 `CLAUDE_PLUGIN_SECRET_GUARD=off` env var 한 가지뿐이며, 우회 시 stderr 에 알림이 출력됩니다."

#### 7-2. 정책 커스터마이즈 의향 확인

사용자에게 묻는다 — *지금 이 순간* 추가로 보호하고 싶은 파일이 있는가?

> "기본값 외에 다음과 같은 파일도 *지금* 정책에 추가할까요? (선택 사항):
> - 항상 차단할 파일(`always_block`) — 추가 후 차단 즉시 적용
> - 읽기 전 사용자 확인이 필요한 파일(`ask_before_read`) — 추가 후 도구 호출 시 인라인 프롬프트
>
> 흔한 후보:
> - SSH 키: `id_rsa`, `id_rsa.*`, `id_ed25519`, `id_ed25519.*`
> - 인증서·키: `*.pem`, `*.key`, `*.p12`, `*.pfx`
> - 클라우드 자격 증명: `.aws/credentials`, `.gcloud/credentials*.json`, `gcp-key*.json`
> - 패키지 매니저 토큰: `.npmrc`, `.netrc`, `.yarnrc`
>
> 추가하고 싶으면 어느 카테고리에 어떤 패턴을 넣을지 알려주세요. 추가하지 않으면 *내장 기본값으로* 진행합니다."

#### 7-3. 정책 파일 작성 분기

- **사용자가 추가 항목 제시** → `claude-code-plugin/project-lifecycle/hooks/secret-guard-template.json` 을 시작점으로 삼아 `.claude/secret-guard.json` 을 작성한다. 사용자가 명시한 항목만 반영(추측 X). `$examples` 블록은 제거. 작성 후 사용자에게 결과 표를 보여주고 *명시적 확인* 을 받는다.
- **사용자가 추가 안 함** → `.claude/secret-guard.json` 을 *만들지 않는다*. 내장 기본값이 그대로 적용된다(헌장 D3). 사용자에게 한 줄 안내: "필요해지면 언제든 `.claude/secret-guard.json` 을 직접 생성·편집해서 정책을 추가할 수 있습니다."

#### 7-4. 우회 메커니즘 인식 강화

세팅 종료 직전 한 줄 더:

> "정당한 사유로 일시 해제가 필요할 때만 `CLAUDE_PLUGIN_SECRET_GUARD=off claude` 로 세션을 시작하세요. 세션 종료 시 자동 복원되며, 우회 사실은 stderr 로 매 호출마다 알려지므로 추적 가능합니다."

> 참고: `.editorconfig` 자동 생성은 v0.4.0에서 제거되었다. 에디터 설정은 프로젝트 루트에 있어야 의미가 있고, 이는 "루트는 프로젝트 코드만"이라는 원칙과 충돌하기 때문이다. 필요하면 사용자가 직접 루트에 생성한다 — 샘플 스니펫은 `references/team-conventions-template.md` 참조.

## 가이드라인

- Phase 0은 다른 모든 Phase의 전제 조건이다 — 반드시 먼저 수행
- CLAUDE.md는 프로젝트 진행에 따라 지속적으로 업데이트해야 한다
- 컨벤션은 처음에 정하고, 변경 시 반드시 팀 합의를 거친다
- 1인 프로젝트라도 컨벤션을 문서화한다 — 미래의 자신을 위해
- "나중에 정하자"는 가장 비싼 선택 — 초기 10분 투자가 이후 10시간을 절약한다

## 참고 자료

- **`references/project-config-template.md`** — 프로젝트 설정 템플릿
- **`references/team-conventions-template.md`** — 팀 컨벤션 정의 템플릿
- **`../../hooks/secret-guard-template.json`** — Step 7-3 의 정책 작성 시작 샘플
- **`../../../../docs/direction/2026-04-28-secret-file-guardrail-charter.md`** — Step 7 의 상위 헌장
