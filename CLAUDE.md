# CLAUDE.md

Always respond in Korean (한국어).

## Planning
- Propose a brief plan before non-trivial work (new features, multi-file changes, architectural decisions).
- Trivial work (typos, obvious fixes, single-line changes) — just do it.
- If multiple reasonable approaches exist, present them with tradeoffs. Don't pick silently.

## Communication
- Be direct and specific. No hedging on technical recommendations.
- If uncertain, say so and ask — don't guess.
- When recommending: state what, why, and what could go wrong.

## Defaults
- Prefer editing existing files over creating new ones.
- Don't create documentation files (README, etc.) unless asked.
- Stop after 3 failed attempts and reassess the approach.

## 참고사항
- **노션**: 특별한 언급이 없으면 "Ella.Kim" 노션 페이지를 의미합니다.

## 커밋
- 커밋 메시지는 **한글 1줄** (`타입: 설명`). 정리와 기능을 절대 섞지 말 것.
- 상세 규칙: `~/.claude/skills/commit/rules.md` 참조.
- 커밋 시 `/commit` 커맨드 사용 권장.

## 코딩 가이드
- 코드 작업 시 `~/.claude/coding-guide.md`를 참조할 것.

## 도구 선택
- **구글**(Drive/Sheets/Gmail/Calendar/Docs/Slides/Tasks 등) 작업 → `gws` (Google Workspace CLI)
- **깃 커밋/GitHub** 작업 → `gh` (GitHub CLI)
- 두 도구 최초 인증: `Ella-Claude-Settings/connect.sh [gws|gh|all]` 실행.

## gws (Google Workspace CLI)
- gws 호출 시 **반드시** `GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file`을 prefix할 것 (settings.json env에도 설정됨).
  예: `GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file gws auth status`
- env var 없이 실행하면 Keychain으로 폴백 → backend 불일치 → 자격증명 자동 삭제 → 재로그인 루프.
- **로그인**: `gws auth login` 실행 후, 브라우저 동의 화면에서 **`Google Cloud Platform`과 `Pub/Sub` 권한 체크를 해제**할 것.
  - 이유: 이 GCP scope이 있으면 nxtcloud.kr 조직의 재인증(reauth) 정책에 걸려 주기적으로 `invalid_grant: invalid_rapt`로 만료됨. (기본 `gws auth login`은 이 2개를 포함하므로 반드시 빼야 함)
  - 정상: `gws auth status`의 scopes에 cloud-platform/pubsub이 **없음**(scope 12개).
- `invalid_rapt` 에러 = backend 문제 아님, GCP scope + 조직 reauth 정책 → 위 방법으로 재로그인.
- `Could not decrypt` 에러 = backend 불일치 → `~/.config/gws`의 자격 파일 + Keychain `gws-cli` 항목 정리 후 재로그인.
- 계정 `ella.kim@nxtcloud.kr` / GCP 프로젝트 `ella-cli` (OAuth 동의화면 Internal).

## gh (GitHub CLI)
- 여러 기기에서 같은 계정으로 gh OAuth 로그인하면 토큰이 서로 무효화됨 → **기기별 무만료 PAT** 사용.
- **등록**: 토큰을 클립보드에 복사 후 `pbpaste | gh auth login --hostname github.com --with-token` (토큰이 stdin으로만 들어가 노출 안 됨).
- PAT는 **No expiration**으로 발급할 것 (발급 기본값 30일 주의). scopes: `repo, read:org, gist, admin:public_key`.
- 웹에서 토큰을 regenerate하면 값이 바뀌므로 gh에 재등록 필요(안 하면 401 Bad credentials).
- 만료 확인: `gh api user --include | grep -i github-authentication-token-expiration` (헤더 없으면 무만료).
- 계정 `Dang-Mu`. 조직 `nxtcloud-org`는 SAML SSO 미강제.

---

Last Updated: 2026-06-30
