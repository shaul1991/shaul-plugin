---
name: 06-infra
description: >
  인프라 및 DevOps 셋업 단계. "인프라 설정", "CI/CD 파이프라인", "배포 설정",
  "Docker 설정", "클라우드 셋업", "모니터링", "로깅",
  "infrastructure", "devops", "deployment" 요청 시 사용.
metadata:
  phase: "6"
  phase_name: "인프라/DevOps"
---

# Phase 6: 인프라 / DevOps (Infrastructure)

애플리케이션을 안정적으로 빌드, 배포, 운영하기 위한 인프라와 자동화 파이프라인을 구성한다.

## 필수: Plan → Review → Execute → Re-verify

**이 Phase를 시작하기 전에 반드시 거버넌스 프로세스를 따른다.**

1. **PLAN** — 실행계획서를 작성한다 (`governance` 스킬의 `references/execution-plan-template.md` 참조)
   - `.claude/local/plans/<sanitized-branch>/06-infra/execution-plan.md`로 저장 (브랜치별 작업 영역, gitignore 대상)
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
- Phase 3의 기술 스택 및 배포 구조 (`.claude/03-architecture/tech-stack.md`)
- Phase 5의 프로젝트 코드가 기본 구조 갖춤

## 실행 절차

### Step 1: 컨테이너화
1. **Dockerfile 작성** — 멀티스테이지 빌드, 최소 이미지
2. **docker-compose.yml** — 로컬 개발 환경 (앱 + DB + 캐시 등)
3. **.dockerignore** — 불필요한 파일 제외

Dockerfile 베스트 프랙티스:
- 멀티스테이지 빌드로 이미지 크기 최소화
- non-root 사용자로 실행
- `COPY package*.json` 먼저 → `npm install` → `COPY .` (레이어 캐싱)
- health check 포함

### Step 2: CI/CD 파이프라인
사용하는 도구(GitHub Actions, GitLab CI 등)에 맞게 파이프라인 구성:

**CI (Continuous Integration):**
1. 코드 체크아웃
2. 의존성 설치 (캐시 활용)
3. 린트 & 포맷 체크
4. 타입 체크
5. 단위 테스트
6. 통합 테스트
7. 빌드
8. (선택) 보안 스캔

**CD (Continuous Deployment):**
1. Docker 이미지 빌드 & 푸시
2. 스테이징 배포
3. 스모크 테스트
4. (수동 승인)
5. 프로덕션 배포
6. 헬스 체크
7. (실패 시) 자동 롤백

### Step 3: 환경 구성
각 환경별 설정을 분리:

| 환경 | 용도 | 특성 |
|------|------|------|
| local | 개발자 로컬 | Docker Compose, 핫 리로드 |
| dev | 개발 통합 | 자동 배포, 테스트 데이터 |
| staging | 릴리즈 전 검증 | 프로덕션과 동일 구성 |
| production | 실 서비스 | 고가용성, 모니터링 |

### Step 4: 모니터링 & 로깅
1. **APM** — 애플리케이션 성능 모니터링 (Datadog, New Relic, Grafana)
2. **로깅** — 구조화된 로그, 중앙 집중 수집 (ELK, CloudWatch)
3. **알림** — 임계치 기반 알림 (PagerDuty, Slack webhook)
4. **업타임 모니터링** — 외부 헬스체크 (UptimeRobot, Pingdom)

로깅 레벨 정의:
| 레벨 | 용도 | 프로덕션 |
|------|------|---------|
| ERROR | 즉시 대응 필요한 에러 | O |
| WARN | 잠재적 문제 | O |
| INFO | 주요 비즈니스 이벤트 | O |
| DEBUG | 디버깅 정보 | X |
| TRACE | 상세 추적 | X |

### Step 5: 보안 기본 설정
1. **시크릿 관리** — 환경 변수, Secret Manager
2. **HTTPS** — SSL 인증서 (Let's Encrypt, ACM)
3. **CORS** — 허용 오리진 설정
4. **Rate Limiting** — API 요청 제한
5. **WAF** — 웹 방화벽 (필요 시)

### Step 6: 산출물 생성
- **`.claude/06-infra/infrastructure.md`** — 인프라 구성 문서
- **`.claude/06-infra/ci-cd.md`** — CI/CD 파이프라인 문서
- **`.claude/06-infra/monitoring.md`** — 모니터링/알림 설정
- **인프라 코드** — Dockerfile, docker-compose.yml, CI/CD 설정 파일

## 가이드라인

- **IaC (Infrastructure as Code)** — 인프라 변경은 코드로 관리
- **환경 동일성** — dev/staging/prod 간 차이 최소화
- **시크릿은 코드에 절대 포함하지 않음** — .env는 .gitignore에
- **점진적 구축** — MVP에서는 단순하게 시작 (PaaS → 필요 시 K8s)
- **배포는 자동화, 롤백은 즉시 가능하게**
- **비용 모니터링** — 클라우드 예산 알림 설정

## 참고 자료

- **`references/dockerfile-templates.md`** — 언어별 Dockerfile 템플릿
- **`references/ci-cd-templates.md`** — CI/CD 파이프라인 템플릿
- **`references/iac-templates.md`** — IaC (Infrastructure as Code) 템플릿
