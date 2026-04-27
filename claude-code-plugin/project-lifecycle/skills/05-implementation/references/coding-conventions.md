# 코딩 컨벤션 가이드

## 네이밍 규칙

### JavaScript / TypeScript
| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수 / 함수 | camelCase | `getUserById`, `isActive` |
| 클래스 / 타입 / 인터페이스 | PascalCase | `UserService`, `CreateUserDto` |
| 상수 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `API_BASE_URL` |
| 파일명 (컴포넌트) | PascalCase | `UserProfile.tsx` |
| 파일명 (유틸/서비스) | kebab-case | `auth-service.ts` |
| 디렉토리 | kebab-case | `user-profile/` |
| enum 값 | PascalCase | `UserRole.Admin` |
| 불리언 | is/has/can/should 접두사 | `isLoading`, `hasPermission` |

### Python
| 대상 | 규칙 | 예시 |
|------|------|------|
| 변수 / 함수 | snake_case | `get_user_by_id` |
| 클래스 | PascalCase | `UserService` |
| 상수 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 모듈 / 패키지 | snake_case | `auth_service.py` |
| private | 언더스코어 접두사 | `_internal_method` |

## 디렉토리 구조 패턴

### 기능 기반 (Feature-based) — 권장
```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── types/
│   │   └── index.ts
│   └── user/
│       ├── components/
│       ├── hooks/
│       ├── services/
│       ├── types/
│       └── index.ts
├── shared/
│   ├── components/
│   ├── hooks/
│   ├── utils/
│   └── types/
└── app/
    ├── routes/
    └── config/
```

### 계층 기반 (Layer-based)
```
src/
├── controllers/
├── services/
├── repositories/
├── models/
├── middleware/
├── utils/
└── config/
```

## 에러 처리 패턴

### 커스텀 에러 클래스
```typescript
class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    message: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// 구체 에러
class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super('NOT_FOUND', 404, `${resource} with id ${id} not found`);
  }
}
```

### API 에러 응답 포맷
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "입력값이 유효하지 않습니다",
    "details": [
      { "field": "email", "message": "유효한 이메일 형식이 아닙니다" }
    ]
  }
}
```

## 임포트 순서
1. 외부 라이브러리 (react, express, lodash)
2. 내부 패키지 (@/shared, @/features)
3. 상대 경로 (../utils, ./types)
4. 타입 전용 임포트 (type { User })
5. 스타일/에셋 (./styles.css)

각 그룹 사이에 빈 줄 한 줄.

## 주석 규칙
- **코드가 "무엇"을 하는지는 코드로** — 변수명, 함수명으로 의도 표현
- **"왜" 이렇게 했는지만 주석으로** — 비즈니스 규칙, 우회 사유
- **TODO 금지** — 이슈 트래커에 등록 (불가피 시 이슈 번호 포함: `// TODO(#123): ...`)
- **JSDoc/docstring** — 공개 API, 복잡한 함수에 작성
