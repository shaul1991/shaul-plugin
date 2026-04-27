# Git 워크플로우 가이드

## 브랜치 전략

### GitHub Flow (권장 — 소규모 팀, MVP)
```
main (항상 배포 가능)
  └── feature/login-page
  └── feature/user-api
  └── fix/auth-token-expiry
```

규칙:
- `main`은 항상 배포 가능 상태
- 새 작업은 `main`에서 브랜치 생성
- PR로 리뷰 후 머지 (squash merge 권장)
- 머지 후 즉시 배포

### Git Flow (중·대규모 팀, 릴리즈 주기 있음)
```
main ─────────────────────────── (릴리즈)
  └── develop ────────────────── (개발 통합)
        └── feature/login
        └── feature/user-api
  └── release/v1.0 ──────────── (릴리즈 준비)
  └── hotfix/critical-bug ────── (긴급 수정)
```

## 브랜치 네이밍
```
<type>/<short-description>

예시:
feature/user-authentication
fix/login-redirect-loop
chore/update-dependencies
refactor/auth-service
docs/api-specification
```

## Conventional Commits

### 형식
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### 타입
| 타입 | 설명 | SemVer |
|------|------|--------|
| feat | 새 기능 추가 | MINOR |
| fix | 버그 수정 | PATCH |
| docs | 문서 변경 | - |
| style | 코드 포맷팅 (기능 변경 X) | - |
| refactor | 리팩토링 (기능 변경 X) | - |
| perf | 성능 개선 | PATCH |
| test | 테스트 추가/수정 | - |
| chore | 빌드, 도구, 의존성 변경 | - |
| ci | CI 설정 변경 | - |

### 예시
```
feat(auth): add JWT refresh token rotation

Implement automatic token refresh when access token expires.
Refresh tokens are rotated on each use for security.

Closes #42
```

### Breaking Change
```
feat(api)!: change user endpoint response format

BREAKING CHANGE: User endpoint now returns nested address object
instead of flat fields.
```

## PR 규칙

### PR 제목
Conventional Commit 형식과 동일:
```
feat(auth): implement OAuth2 login
```

### PR 본문 템플릿
```markdown
## 변경 사항
-

## 동기 / 컨텍스트
>

## 테스트
- [ ] 단위 테스트 추가
- [ ] 로컬에서 동작 확인

## 스크린샷 (UI 변경 시)

## 체크리스트
- [ ] 코드 셀프 리뷰 완료
- [ ] 린트/포맷 통과
- [ ] 타입 체크 통과
- [ ] 관련 문서 업데이트
```

## .gitignore 필수 항목
```
# 환경 변수
.env
.env.local
.env.*.local

# 의존성
node_modules/
__pycache__/
venv/

# 빌드 산출물
dist/
build/
.next/

# IDE
.idea/
.vscode/settings.json
*.swp

# OS
.DS_Store
Thumbs.db

# 로그
*.log
```
