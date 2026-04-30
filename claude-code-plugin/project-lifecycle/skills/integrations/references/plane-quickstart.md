# Plane Quickstart (Cloud / Self-host)

> 본 가이드는 `/integrations` 스킬의 Step 2 (Plane 준비) 보조 자료다.
> 헌장: `docs/direction/2026-04-30-plane-integration-charter.md`.

## 옵션 A — Plane Cloud (가장 빠름)

1. https://plane.so/ → 회원가입.
2. Workspace 생성 → URL 의 slug 메모 (예: `https://app.plane.so/<slug>/`).
3. Project 생성 → URL 의 UUID 메모 (예: `https://app.plane.so/<slug>/projects/<uuid>/`).
4. Settings → API Tokens → "Add API Token" → 토큰 문자열 메모.

## 옵션 B — Self-host (권장: 데이터 주권)

```bash
git clone https://github.com/makeplane/plane plane-host
cd plane-host

# 공식 docker compose (호스트는 80 포트 사용)
docker compose -f docker-compose-hub.yml up -d

# 헬스체크 (서비스가 모두 뜨는 데 1~2분 소요)
docker compose ps
```

브라우저에서 `http://localhost/` 접속 → 첫 로그인 (이메일 OTP 또는 admin 계정 생성) →
Workspace + Project 생성 → API Token 발급. 절차는 Cloud 와 동일.

> 운영 배포는 별도 설정 (HTTPS, 도메인, 백업) 이 필요하다 — Plane 공식 문서 참조.

## 토큰 보호 체크리스트

- [ ] `.claude/local/plane.secret.json` 의 권한 600 (`chmod 600`)
- [ ] `.gitignore` 에 `.claude/` 가 들어 있음 (bootstrap-local.sh 가 자동 보장)
- [ ] secret-guard 가 동작 중 (`CLAUDE_PLUGIN_SECRET_GUARD` 가 `off` 가 아님)
- [ ] 토큰 회전 알림 — `issued_at` 을 발급일로 설정 (90일 경과 시 SessionStart 경고)
- [ ] Project-scoped token 사용 (workspace 전체 권한 X)

## 첫 push 검증 (DRY-RUN)

`.claude/integrations.json` 의 `safety.dry_run: true` 로 시작:

```bash
# 1) 시범 파일 생성
mkdir -p docs/issues
cat > docs/issues/test-sync.md <<'EOF'
# 테스트 이슈 — 통합 검증

## 설명
이 파일은 plane-sync 훅 동작 검증용이다. 정상이면 stderr 에 `DRY-RUN POST .../issues/` 가 찍힌다.
EOF

# 2) Claude 세션에서 위 파일을 한 번 Edit/Write → stderr 관찰
```

stderr 예시 (DRY-RUN):
```
[project-lifecycle/plane] 활성: workspace=test, project=..., mode=both, dry_run=True, token=file:.claude/local/plane.secret.json
[project-lifecycle/plane] DRY-RUN POST https://api.plane.so/api/v1/workspaces/test/projects/.../issues/ body={...}
```

기대 동작 확인 후 `safety.dry_run` 을 `false` 로 변경 → 다음 세션부터 실 push.

## 자주 묻는 질문

**Q. token 을 `.env` 에 둘 수 있나?**
가능. `PLANE_API_TOKEN=...` 으로 export 하면 환경변수 우선순위(2순위)로 자동 채택. 단 `.env` 자체는 secret-guard 차단 — Claude 세션 안에서 `.env` 를 *읽는* 것은 막힌다.

**Q. Plane self-host 가 죽었다 살아남으면?**
다음 PostToolUse 에 자동 재시도. 그 사이 변경된 파일은 *마지막 변경 1회분만* push 된다 (디바운스 미구현, v0.11 큐 도입 예정).

**Q. 양방향 동기화는 언제?**
v0.11+ 에서 사용자 명시 명령 (예: `/plane-pull`) 으로만 도입. 자동 pull 없음 (헌장 D3, 미래 가드 3).

**Q. Linear / Jira 도 가능한가?**
스키마 (`providers.<name>`) 는 형제 키 추가만으로 확장 가능하지만 v1 구현은 Plane 만. 다른 provider 는 별도 헌장과 함께 추후.
