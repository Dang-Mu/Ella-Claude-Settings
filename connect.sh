#!/usr/bin/env bash
set -euo pipefail

# connect.sh — 유용한 도구(gws, gh) 인증 연결
# 사용법: ./connect.sh [gws|gh|all]
#   gws : Google Workspace CLI 인증 (구글 작업용)
#   gh  : GitHub CLI 인증 (깃 커밋/GitHub 작업용)
#   all : 둘 다

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
step()  { echo -e "${BLUE}[→]${NC} $1"; }

SETTINGS="$HOME/.claude/settings.json"
ZSHRC="$HOME/.zshrc"

# gws backend를 file로 고정 (Keychain 폴백 불일치 방지) — .zshrc + settings.json env 둘 다
ensure_gws_backend() {
  if ! grep -q "GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND" "$ZSHRC" 2>/dev/null; then
    printf '\n# gws 자격증명 암호화 키를 파일로 고정 (Keychain 폴백 불일치로 인한 인증 풀림 방지)\nexport GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file\n' >> "$ZSHRC"
    info ".zshrc에 GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file 추가"
  else
    info ".zshrc backend 설정 이미 있음"
  fi
  if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
    tmp="$(mktemp)"
    jq '.env.GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND = "file"' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    info "settings.json env에 backend=file 반영"
  else
    warn "jq 없거나 settings.json 없음 → settings.json env는 수동 추가 필요"
  fi
}

connect_gws() {
  step "gws (Google Workspace CLI) 연결"
  command -v gws >/dev/null 2>&1 || { error "gws 미설치. 먼저 설치하세요."; return 1; }
  ensure_gws_backend
  echo ""
  warn "곧 열리는 브라우저 동의 화면에서 아래 2개 권한의 체크를 ❌ 해제하세요:"
  echo "      • Google Cloud Platform 데이터 보기/관리 (cloud-platform)"
  echo "      • Pub/Sub 관련 권한 (pubsub)"
  echo "    (이 GCP 권한이 있으면 조직 재인증 정책에 걸려 주기적으로 인증이 풀립니다)"
  echo ""
  read -rp "$(echo -e "${YELLOW}[?]${NC}") 준비되면 Enter (브라우저 로그인 시작) "
  GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file gws auth login || { error "gws 로그인 실패"; return 1; }
  echo ""
  step "scope 검증 중..."
  bad=$(GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file gws auth status 2>/dev/null \
        | grep -oE "cloud-platform|pubsub" | sort -u | tr '\n' ' ')
  if [ -n "$bad" ]; then
    warn "아직 GCP scope 포함됨: ${bad}→ 동의 화면에서 체크 해제 후 'connect.sh gws' 재실행 권장"
  else
    info "cloud-platform/pubsub 없음 — 재인증 정책 회피 OK"
  fi
}

connect_gh() {
  step "gh (GitHub CLI) 연결"
  command -v gh >/dev/null 2>&1 || { error "gh 미설치. 먼저 설치하세요."; return 1; }
  echo ""
  echo "  1) https://github.com/settings/tokens/new 에서 PAT(classic) 발급:"
  echo "     • Note: gh-cli-$(hostname -s 2>/dev/null || echo this-mac)"
  echo "     • Expiration: No expiration   (기본값 30일 주의!)"
  echo "     • Scopes: repo, read:org, gist, admin:public_key"
  echo "  2) 발급된 토큰(ghp_...)을 클립보드에 복사"
  echo ""
  read -rp "$(echo -e "${YELLOW}[?]${NC}") 토큰을 클립보드에 복사했으면 Enter "
  pbpaste | gh auth login --hostname github.com --with-token || { error "gh 등록 실패"; return 1; }
  echo ""
  step "토큰 검증 중..."
  if gh api user >/dev/null 2>&1; then
    exp=$(gh api user --include 2>/dev/null | grep -i "github-authentication-token-expiration" || true)
    if [ -z "$exp" ]; then
      info "로그인 OK / 만료 없음 (무만료 토큰)"
    else
      warn "로그인 OK이나 만료 설정됨: ${exp}→ No expiration으로 재발급 권장"
    fi
  else
    error "토큰 검증 실패 (Bad credentials? 토큰 값/scope 확인)"
  fi
}

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "사용법: $0 [gws|gh|all]"
  read -rp "무엇을 연결할까요? [gws/gh/all] " TARGET
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  도구 인증 연결 (connect)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

case "$TARGET" in
  gws) connect_gws ;;
  gh)  connect_gh ;;
  all) connect_gws; echo ""; connect_gh ;;
  *)   error "알 수 없는 대상: '$TARGET' (gws | gh | all 중 하나)"; exit 1 ;;
esac

echo ""
info "완료."
