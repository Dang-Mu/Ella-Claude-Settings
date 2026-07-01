#!/usr/bin/env bash
set -euo pipefail

# Codex 설정 설치 스크립트 (codex-install.sh)
# ~/.codex/ 디렉토리에 Codex용 지침·스킬·설정을 복사합니다.
# (Claude용은 별도: claude-install.sh)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/claude-code-setting/codex"   # 비민감 codex 설정 소스
CODEX_DIR="$HOME/.codex"
BACKUP_DIR="$CODEX_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# 복사할 파일/디렉토리 목록 (SRC 기준)
FILES=(
  "AGENTS.md"
  "hooks.json"
  "coding-guide.md"
)

DIRS=(
  "skills"
  "agents"
  "rules"
)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Codex 설정 설치 (~/.codex)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "설치 경로: $CODEX_DIR"
echo "소스:      $SRC"
echo ""

if [ ! -d "$SRC" ]; then
  error "codex 소스 디렉토리가 없습니다: $SRC"
  exit 1
fi

# ~/.codex 디렉토리 확인
if [ ! -d "$CODEX_DIR" ]; then
  warn "~/.codex 디렉토리가 없습니다. 생성합니다."
  mkdir -p "$CODEX_DIR"
  info "~/.codex 생성 완료"
fi

# 백업 함수
backup_if_exists() {
  local target="$1"
  if [ -e "$CODEX_DIR/$target" ]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$target")"
    cp -r "$CODEX_DIR/$target" "$BACKUP_DIR/$target"
    return 0
  fi
  return 1
}

# 기존 파일 백업 필요 여부
NEED_BACKUP=false
for f in "${FILES[@]}"; do
  [ -e "$CODEX_DIR/$f" ] && NEED_BACKUP=true && break
done
if ! $NEED_BACKUP; then
  for d in "${DIRS[@]}"; do
    [ -d "$CODEX_DIR/$d" ] && NEED_BACKUP=true && break
  done
fi

if $NEED_BACKUP; then
  warn "기존 설정 파일을 백업합니다 → $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  for f in "${FILES[@]}"; do
    backup_if_exists "$f" && info "  백업: $f"
  done
  for d in "${DIRS[@]}"; do
    backup_if_exists "$d" && info "  백업: $d/"
  done
  echo ""
fi

# 파일 복사
echo "파일 설치 중..."
for f in "${FILES[@]}"; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$CODEX_DIR/$f"
    info "$f"
  else
    warn "$f 없음 — 건너뜀"
  fi
done

# 디렉토리 복사 (skills/commit·init 등)
for d in "${DIRS[@]}"; do
  if [ -d "$SRC/$d" ]; then
    mkdir -p "$CODEX_DIR/$d"
    cp -r "$SRC/$d/." "$CODEX_DIR/$d/"
    info "$d/"
  fi
done

# config.toml 안내 (개인 설정이라 repo에 없음)
echo ""
warn "config.toml 은 개인 설정으로 repo에 없습니다."
if [ -f "$CODEX_DIR/config.toml" ]; then
  info "  기존 ~/.codex/config.toml 발견 — 그대로 사용합니다."
else
  warn "  ~/.codex/config.toml 이 없습니다. codex 최초 실행 시 생성됩니다."
fi
echo "  ※ codex에서 gws를 안정적으로 쓰려면 config.toml의 [shell_environment_policy.set]에"
echo "     GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND = \"file\" 을 추가하세요. (gws backend 폴백 방지)"

# 완료
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}설치 완료!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "설치된 항목:"
echo "  ~/.codex/AGENTS.md"
echo "  ~/.codex/hooks.json"
echo "  ~/.codex/coding-guide.md"
echo "  ~/.codex/skills/  (commit, init)"
echo "  ~/.codex/agents/"
echo "  ~/.codex/rules/"
if $NEED_BACKUP; then
  echo ""
  echo "백업 위치: $BACKUP_DIR"
fi
echo ""
echo "다음: Codex 인증은 'codex login' 으로 직접(수동) 진행하세요."
echo ""
