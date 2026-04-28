---
name: 05-implementation
description: >
  코드 구현 단계. "코드 구현", "개발 시작", "코딩", "프로젝트 셋업",
  "보일러플레이트", "코드 작성", "implementation", "coding",
  "프로젝트 초기화", "코드 컨벤션" 요청 시 사용.
metadata:
  phase: "5"
  phase_name: "구현"
---

# Phase 5: 구현 (Implementation)

설계를 실제 코드로 전환한다. 프로젝트 초기화, 코드 컨벤션 설정, 핵심 기능 구현을 포함한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/05-implementation/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
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

## 전제 조건
- Phase 3의 기술 스택 결정 (`.claude/03-architecture/tech-stack.md`)
- Phase 3의 API 설계 (`.claude/03-architecture/api-spec.md`)
- Phase 4의 디자인 시스템 (`.claude/04-design/design-system.md`) — 선택

## 실행 절차

### Step 1: 프로젝트 초기화
기술 스택에 맞는 프로젝트 보일러플레이트를 생성:

1. **프로젝트 구조** — 디렉토리 구조 생성
2. **패키지 매니저 설정** — 의존성 정의 (package.json, requirements.txt 등)
3. **빌드 도구 설정** — 번들러, 컴파일러 설정
4. **환경 변수** — `.env.example` 생성, 변수 목록 정의

### Step 2: 개발 환경 설정
1. **코드 포맷터** — Prettier, Black 등
2. **린터** — ESLint, Ruff 등 + 규칙 설정
3. **Git 훅** — pre-commit (린트, 포맷), commit-msg (컨벤셔널 커밋)
4. **에디터 설정** — `.editorconfig`, VS Code settings
5. **타입 체크** — TypeScript strict, mypy 등

### Step 3: 코드 컨벤션 정립
`references/coding-conventions.md`를 참고하여 프로젝트에 맞는 컨벤션 문서 생성:

1. **네이밍 규칙** — 변수, 함수, 클래스, 파일명
2. **디렉토리 구조** — 기능별/계층별 조직 방식
3. **임포트 순서** — 외부 → 내부 → 상대 → 타입
4. **에러 처리** — 에러 타입 체계, 처리 패턴
5. **주석/문서화** — JSDoc, docstring 규칙

### Step 4: 핵심 기능 구현
MVP 스코프의 Must Have 기능을 구현 순서를 정한다:

1. **인증/인가** — 가장 먼저 (다른 기능의 전제조건)
2. **핵심 도메인 로직** — 비즈니스 핵심 기능
3. **CRUD 엔드포인트** — 데이터 생성/조회/수정/삭제
4. **UI 페이지** — 디자인 기반 화면 구현
5. **통합** — 프론트-백 연동, 외부 서비스 연동

각 기능은 다음 패턴으로:
```
기능 브랜치 생성 → 구현 → 단위 테스트 → 코드 리뷰 → 머지
```

### Step 5: 셀프 리뷰 (Self-Review)
에이전트가 코드를 작성한 후 스스로 컨벤션과 품질을 체크하는 필수 단계:

1. **코드 컨벤션 체크** — Step 3에서 정립한 컨벤션과 일치하는지 검증
   - 네이밍 규칙 준수 여부
   - 디렉토리 구조 규칙 준수 여부
   - 임포트 순서 준수 여부
2. **코드 품질 체크** — 린터/포맷터 실행 결과 확인
   - ESLint/Ruff 에러 0건
   - Prettier/Black 포맷팅 일치
   - 타입 에러 0건
3. **보안 체크** — 기본 보안 위반 사항 확인
   - 하드코딩된 시크릿/비밀번호 없음
   - SQL 인젝션, XSS 취약 코드 없음
   - 적절한 입력 유효성 검사
4. **테스트 체크** — 작성된 테스트의 충분성 확인
   - 핵심 비즈니스 로직에 대한 단위 테스트 존재
   - 에러/엣지 케이스 테스트 포함
   - 모든 테스트 통과
5. **문서화 체크** — 코드 문서화 상태 확인
   - 공개 API에 JSDoc/docstring 존재
   - 복잡한 로직에 설명 주석 존재
   - README/setup guide 업데이트

> 셀프 리뷰에서 발견된 문제는 즉시 수정한 후 다음 단계로 진행한다.

### Step 6: 산출물 생성
- **`.claude/05-implementation/conventions.md`** — 코딩 컨벤션
- **`.claude/05-implementation/setup-guide.md`** — 개발 환경 셋업 가이드
- **실제 프로젝트 코드** — 프로젝트 루트에 생성

## 가이드라인

- **점진적 구현** — 한 번에 하나의 기능, 작은 커밋
- **Conventional Commits** — `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`
- **브랜치 전략** — Git Flow 또는 GitHub Flow 선택 후 일관되게 적용
- **코드 리뷰** — 본인 코드도 PR로 관리, 셀프 리뷰 습관
- **기술 부채 관리** — `// TODO:` 대신 이슈 트래커에 등록
- **테스트 병행** — 구현과 동시에 단위 테스트 작성 (TDD 권장)

## 참고 자료

- **`references/coding-conventions.md`** — 범용 코딩 컨벤션 가이드
- **`references/git-workflow.md`** — Git 브랜치 전략 및 커밋 규칙
