# 팀 컨벤션 (Team Conventions)

> **적용일**: YYYY-MM-DD
> **최종 수정일**: YYYY-MM-DD

---

## 1. 코드 스타일

### 포맷팅
| 항목 | 규칙 |
|------|------|
| 들여쓰기 | 스페이스 2 / 스페이스 4 / 탭 |
| 줄 바꿈 | LF |
| 최대 줄 길이 | 80 / 100 / 120 |
| 파일 끝 빈 줄 | 있음 |
| 세미콜론 (JS/TS) | 있음 / 없음 |
| 따옴표 | 작은따옴표 / 큰따옴표 |

### 도구
| 도구 | 용도 | 설정 파일 |
|------|------|----------|
| Prettier / Black | 포맷터 | `.prettierrc` / `pyproject.toml` |
| ESLint / Ruff | 린터 | `.eslintrc` / `ruff.toml` |
| TypeScript | 타입 체크 | `tsconfig.json` |

### `.editorconfig` (선택, 사용자 직접 생성)

플러그인은 `.editorconfig`를 자동 생성하지 않는다. 이 파일은 에디터가 프로젝트 루트에서 직접 읽어야 의미가 있어 "루트는 프로젝트 코드만"이라는 원칙과 충돌하기 때문이다. 필요하면 사용자가 다음 스니펫을 참고해 직접 프로젝트 루트에 `.editorconfig`를 생성한다:

```ini
root = true

[*]
charset = utf-8
indent_style = space
indent_size = 2
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
```

---

## 2. 네이밍 규칙

| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수 | camelCase | `userName` |
| 함수 | camelCase | `getUserById` |
| 클래스/컴포넌트 | PascalCase | `UserProfile` |
| 상수 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 파일명 (컴포넌트) | PascalCase | `UserProfile.tsx` |
| 파일명 (유틸) | kebab-case | `date-utils.ts` |
| 디렉토리 | kebab-case | `user-management/` |
| DB 테이블 | snake_case | `user_profiles` |
| DB 컬럼 | snake_case | `created_at` |
| API 엔드포인트 | kebab-case | `/api/user-profiles` |
| 환경 변수 | UPPER_SNAKE_CASE | `DATABASE_URL` |

---

## 3. Git 컨벤션

### 브랜치 전략
- [ ] GitHub Flow (main + feature branches)
- [ ] Git Flow (main + develop + feature/release/hotfix)
- [ ] Trunk-based (main + short-lived branches)

### 브랜치 네이밍
```
feature/기능명       — 신규 기능
fix/버그명           — 버그 수정
chore/작업명         — 설정, 의존성
docs/문서명          — 문서 작업
refactor/대상        — 리팩토링
```

### 커밋 메시지 (Conventional Commits)
```
<타입>(<범위>): <제목>

[본문]

[꼬리말]
```

**타입:**
| 타입 | 용도 |
|------|------|
| feat | 신규 기능 |
| fix | 버그 수정 |
| docs | 문서 변경 |
| style | 코드 포맷팅 (기능 변경 없음) |
| refactor | 리팩토링 |
| test | 테스트 추가/수정 |
| chore | 빌드, 설정, 의존성 |
| perf | 성능 개선 |
| ci | CI/CD 설정 |

---

## 4. 코드 리뷰

| 항목 | 규칙 |
|------|------|
| PR 크기 | 300줄 이하 권장, 500줄 이상 분리 |
| 리뷰어 수 | 최소 1명 (1인 프로젝트: 셀프 리뷰) |
| 머지 방식 | Squash / Rebase / Merge Commit |
| 머지 조건 | 리뷰 승인 + CI 통과 |
| 셀프 머지 | 허용 / 불허 |

---

## 5. 문서화

| 항목 | 규칙 |
|------|------|
| 문서 언어 | 한국어 / 영어 / 혼합 |
| 코드 주석 언어 | 한국어 / 영어 |
| API 문서 | 코드 주석(JSDoc/docstring) / OpenAPI |
| README | 프로젝트 루트에 필수 |
| 변경 로그 | CHANGELOG.md 유지 여부 |

---

## 6. 에러 처리

| 항목 | 규칙 |
|------|------|
| 에러 타입 | 커스텀 에러 클래스 정의 |
| 에러 코드 | 영역별 코드 체계 (AUTH_001, DB_001 등) |
| 로깅 | 에러 레벨 구분 (ERROR > WARN > INFO > DEBUG) |
| 사용자 메시지 | 기술 정보 노출 금지 |

---

*이 컨벤션은 프로젝트 시작 시 합의하며, 변경 시 팀 전체의 동의를 거친다.*
