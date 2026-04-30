# Claude Code / Codex dual runtime installation charter

- **작성일**: 2026-04-30
- **반영 출시**: v0.11.0
- **상태**: Active

## 사용자 원문 요구사항

> 해당 플러그인은 claude code에서 사용할 수 있는 plugin으로 만들어졌다. 팀원이 codex를 사용하므로 codex에서도 사용할 수 있는 플러그인으로 추가하고자 한다.
> - 해당 플로그인을 claude code cli에서 사용할 수 있어야 한다.
> - 해당 플러그인을 codex cli에서 사용할 수 있어야 한다.
> - 해당 플러그인을 claude code cli와 codex 둘다 병렬 사용하여 각각의 결과물을 검토&비교&병합 할 수 있어야 한다. 단 주 사용은 정하여야한다.

> claude code에서 플러그인을 설치하면 주 : claude code, 보조(옵셔널) : codex 이고, codex에서 플러그인을 설치하면 주: codex, 보조(옵셔널) : claude clode의 구조를 원한다.

> 플러그인을 설치 적용하는 sh를 만들어 어디에 설치할것이며, primary를 claude code 사용할 것인지 codex 사용할것인지 하는 방법은?

## 결정

1. 같은 플러그인 루트(`claude-code-plugin/project-lifecycle`)에 Claude Code manifest와 Codex manifest를 함께 둔다.
2. Claude Code용 `.claude-plugin/plugin.json`은 유지하고, Codex용 `.codex-plugin/plugin.json`을 추가한다.
3. 설치 적용 스크립트는 `scripts/install-project-lifecycle.sh`로 제공한다.
4. primary는 스크립트의 `--primary claude|codex` 인자로 명시한다.
5. Claude primary는 `.claude/project-lifecycle.json`, Codex primary는 `.codex/project-lifecycle.json`에 대상 프로젝트 runtime config를 쓴다.
6. `--with-secondary`는 반대 도구를 optional reviewer로 marketplace 등록까지만 수행한다.
7. Codex CLI는 marketplace 관리를 지원하지만 plugin install 서브커맨드는 제공하지 않으므로, Codex primary는 스크립트 실행 후 Codex `/plugins`에서 설치를 확정한다.
8. 자동 merge는 하지 않는다. primary runtime이 secondary 결과를 검토·비교한 뒤 최종 병합 결정을 소유한다.

## 가드레일

- 기존 Claude Code 설치 경로와 hooks 동작을 깨지 않는다.
- Codex manifest에는 Claude 전용 hook config를 연결하지 않는다.
- 다른 도구의 설정을 자동으로 primary로 바꾸지 않는다. primary 선택은 명시 입력만 따른다.
- 사용자 프로젝트에 쓰는 runtime config는 로컬 설정으로 취급하며 `.claude/` 또는 `.codex/` gitignore 라인을 보장한다.
