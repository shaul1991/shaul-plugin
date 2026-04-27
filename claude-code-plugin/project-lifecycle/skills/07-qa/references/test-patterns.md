# 테스트 작성 패턴 & 안티패턴

## 좋은 테스트의 특징 (FIRST)
- **Fast** — 빠르게 실행
- **Independent** — 다른 테스트에 의존하지 않음
- **Repeatable** — 언제 실행해도 같은 결과
- **Self-validating** — Pass/Fail이 자동으로 결정
- **Timely** — 코드와 동시에 (또는 먼저) 작성

## 네이밍 패턴

### 추천: 행위 기반 네이밍
```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('유효한 데이터로 사용자를 생성하면 생성된 사용자를 반환한다', () => {});
    it('이메일이 중복이면 ConflictError를 던진다', () => {});
    it('이메일 형식이 올바르지 않으면 ValidationError를 던진다', () => {});
  });
});
```

### 비추천
```typescript
it('test1', () => {});
it('should work', () => {});
it('createUser test', () => {});
```

## AAA 패턴

```typescript
it('장바구니에 상품을 추가하면 총액이 업데이트된다', () => {
  // Arrange - 준비
  const cart = new Cart();
  const product = new Product({ name: '티셔츠', price: 29000 });

  // Act - 실행
  cart.addItem(product, 2);

  // Assert - 검증
  expect(cart.totalAmount).toBe(58000);
  expect(cart.itemCount).toBe(2);
});
```

## 테스트 데이터 관리

### Factory 패턴 (추천)
```typescript
// factories/user.factory.ts
const createUser = (overrides?: Partial<User>): User => ({
  id: faker.string.uuid(),
  name: faker.person.fullName(),
  email: faker.internet.email(),
  createdAt: new Date(),
  ...overrides,
});

// 사용
const user = createUser({ name: '홍길동' });
```

### Fixture 패턴
```typescript
// fixtures/users.ts
export const validUser = {
  name: '테스트 유저',
  email: 'test@example.com',
  password: 'SecureP@ss1',
};

export const invalidUser = {
  name: '',
  email: 'not-an-email',
  password: '123',
};
```

## 안티패턴

### 1. 테스트 간 의존성
```typescript
// BAD - 순서에 의존
let userId: string;
it('사용자를 생성한다', () => { userId = createUser(); });
it('생성된 사용자를 조회한다', () => { getUser(userId); }); // 위 테스트 실패 시 같이 실패

// GOOD - 독립적
it('사용자를 조회한다', () => {
  const userId = createUser(); // 자체 준비
  const user = getUser(userId);
  expect(user).toBeDefined();
});
```

### 2. 과도한 Mock
```typescript
// BAD - 모든 것을 Mock → 실제 동작 검증 못함
jest.mock('./database');
jest.mock('./cache');
jest.mock('./logger');
jest.mock('./validator');

// GOOD - 외부 의존성만 Mock
jest.mock('./external-payment-api');
// 나머지는 실제 구현 사용
```

### 3. 구현 세부사항 테스트
```typescript
// BAD - 내부 구현에 결합
expect(component.state.isLoading).toBe(true);
expect(spy).toHaveBeenCalledTimes(3);

// GOOD - 동작(결과)을 테스트
expect(screen.getByRole('progressbar')).toBeVisible();
expect(screen.getByText('로딩 중...')).toBeVisible();
```

### 4. 매직 넘버
```typescript
// BAD
expect(result).toBe(42);

// GOOD
const ANSWER_TO_EVERYTHING = 42;
expect(result).toBe(ANSWER_TO_EVERYTHING);
```

## 테스트 더블 사용 가이드

| 유형 | 용도 | 예시 |
|------|------|------|
| Stub | 미리 정해진 값 반환 | `jest.fn().mockReturnValue(42)` |
| Mock | 호출 여부/방식 검증 | `expect(mock).toHaveBeenCalledWith(...)` |
| Spy | 실제 구현 유지 + 호출 추적 | `jest.spyOn(service, 'method')` |
| Fake | 간소화된 실제 구현 | In-memory DB, Fake HTTP server |

**원칙**: Stub/Fake > Spy > Mock 순으로 선호. Mock은 최후의 수단.
