# 디자인 시스템

## 1. 색상 (Colors)

### Primary
```css
--color-primary-50: #eff6ff;
--color-primary-100: #dbeafe;
--color-primary-500: #3b82f6;
--color-primary-600: #2563eb;
--color-primary-700: #1d4ed8;
--color-primary-900: #1e3a8a;
```

### Secondary
```css
--color-secondary-500: ;
--color-secondary-600: ;
```

### Neutral (Gray)
```css
--color-gray-50: #f9fafb;
--color-gray-100: #f3f4f6;
--color-gray-200: #e5e7eb;
--color-gray-300: #d1d5db;
--color-gray-400: #9ca3af;
--color-gray-500: #6b7280;
--color-gray-600: #4b5563;
--color-gray-700: #374151;
--color-gray-800: #1f2937;
--color-gray-900: #111827;
```

### Semantic
```css
--color-success: #22c55e;
--color-warning: #f59e0b;
--color-error: #ef4444;
--color-info: #3b82f6;
```

## 2. 타이포그래피 (Typography)

### 폰트 패밀리
```css
--font-sans: 'Pretendard', -apple-system, BlinkMacSystemFont, sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', monospace;
```

### 크기 스케일
| 이름 | 크기 | 행간 | 용도 |
|------|------|------|------|
| xs | 12px / 0.75rem | 16px | 보조 텍스트, 캡션 |
| sm | 14px / 0.875rem | 20px | 부제, 레이블 |
| base | 16px / 1rem | 24px | 본문 |
| lg | 18px / 1.125rem | 28px | 강조 본문 |
| xl | 20px / 1.25rem | 28px | 소제목 (h4) |
| 2xl | 24px / 1.5rem | 32px | 섹션 제목 (h3) |
| 3xl | 30px / 1.875rem | 36px | 페이지 부제목 (h2) |
| 4xl | 36px / 2.25rem | 40px | 페이지 제목 (h1) |

### 굵기
```css
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

## 3. 간격 (Spacing)

8px 기반 시스템:
```css
--space-1: 4px;    /* 0.25rem */
--space-2: 8px;    /* 0.5rem */
--space-3: 12px;   /* 0.75rem */
--space-4: 16px;   /* 1rem */
--space-5: 20px;   /* 1.25rem */
--space-6: 24px;   /* 1.5rem */
--space-8: 32px;   /* 2rem */
--space-10: 40px;  /* 2.5rem */
--space-12: 48px;  /* 3rem */
--space-16: 64px;  /* 4rem */
```

## 4. 둥글기 (Border Radius)
```css
--radius-sm: 4px;
--radius-md: 8px;
--radius-lg: 12px;
--radius-xl: 16px;
--radius-full: 9999px;
```

## 5. 그림자 (Shadows)
```css
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
--shadow-md: 0 4px 6px rgba(0,0,0,0.07);
--shadow-lg: 0 10px 15px rgba(0,0,0,0.1);
--shadow-xl: 0 20px 25px rgba(0,0,0,0.1);
```

## 6. 브레이크포인트 (Breakpoints)
| 이름 | 크기 | 용도 |
|------|------|------|
| sm | 640px | 모바일 (가로) |
| md | 768px | 태블릿 |
| lg | 1024px | 데스크톱 (소) |
| xl | 1280px | 데스크톱 (대) |
| 2xl | 1536px | 와이드 |

## 7. 컴포넌트 상태
모든 인터랙티브 컴포넌트는 다음 상태를 정의:

| 상태 | 설명 |
|------|------|
| Default | 기본 상태 |
| Hover | 마우스 오버 |
| Focus | 키보드 포커스 (포커스 링 필수) |
| Active | 클릭/터치 중 |
| Disabled | 비활성화 (opacity 0.5, cursor not-allowed) |
| Loading | 로딩 중 (스피너 또는 스켈레톤) |
| Error | 에러 상태 (빨간색 테두리 + 메시지) |
