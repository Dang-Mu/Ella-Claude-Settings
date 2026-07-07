#!/usr/bin/env bash
set -euo pipefail

# ella-claude-settings 설치 스크립트
# ~/.claude/ 디렉토리에 Claude Code 설정 파일을 복사합니다.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

# 복사할 파일/디렉토리 목록
FILES=(
  "CLAUDE.md"
  "coding-guide.md"
)

DIRS=(
  "skills/commit"
  "skills/init"
  "skills/pingpong"
  "skills/slide-deck"
  "skills/slides"
)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ella-claude-settings 설치"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "설치 경로: $CLAUDE_DIR"
echo ""

# ~/.claude 디렉토리 확인
if [ ! -d "$CLAUDE_DIR" ]; then
  warn "~/.claude 디렉토리가 없습니다. 생성합니다."
  mkdir -p "$CLAUDE_DIR"
  info "~/.claude 생성 완료"
fi

# 백업 함수
backup_if_exists() {
  local target="$1"
  if [ -e "$CLAUDE_DIR/$target" ]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$target")"
    cp -r "$CLAUDE_DIR/$target" "$BACKUP_DIR/$target"
    return 0
  fi
  return 1
}

# 기존 파일 백업
NEED_BACKUP=false
for f in "${FILES[@]}"; do
  [ -e "$CLAUDE_DIR/$f" ] && NEED_BACKUP=true && break
done
if ! $NEED_BACKUP; then
  for d in "${DIRS[@]}"; do
    [ -d "$CLAUDE_DIR/$d" ] && NEED_BACKUP=true && break
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
  cp "$SCRIPT_DIR/$f" "$CLAUDE_DIR/$f"
  info "$f"
done

# 디렉토리 복사
for d in "${DIRS[@]}"; do
  mkdir -p "$CLAUDE_DIR/$d"
  cp -r "$SCRIPT_DIR/$d/." "$CLAUDE_DIR/$d/"
  info "$d/"
done

# 실행 스크립트 설치 (~/.claude/bin) + PATH 보장
echo ""
echo "실행 스크립트 설치 중..."
backup_if_exists "bin/pingpong.sh" && info "  백업: bin/pingpong.sh"
mkdir -p "$CLAUDE_DIR/bin"
cp "$SCRIPT_DIR/bin/pingpong.sh" "$CLAUDE_DIR/bin/pingpong.sh"
chmod +x "$CLAUDE_DIR/bin/pingpong.sh"
info "bin/pingpong.sh"

ZSHRC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/.claude/bin:$PATH"'
if [ -f "$ZSHRC" ] && grep -qF '.claude/bin' "$ZSHRC"; then
  info "PATH 이미 설정됨 (~/.claude/bin)"
else
  {
    echo ""
    echo "# ─── Claude 실행 스크립트 (ella-claude-settings) ───"
    echo "$PATH_LINE"
  } >> "$ZSHRC"
  warn "~/.zshrc 에 PATH 추가함 → 새 셸을 열거나 'source ~/.zshrc' 실행"
fi

# 완료
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}설치 완료!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "설치된 파일:"
echo "  ~/.claude/CLAUDE.md"
echo "  ~/.claude/coding-guide.md"
echo "  ~/.claude/skills/commit/"
echo "  ~/.claude/skills/init/"
echo "  ~/.claude/skills/pingpong/"
echo "  ~/.claude/skills/slide-deck/"
echo "  ~/.claude/skills/slides/"
echo "  ~/.claude/bin/pingpong.sh   (호출: pingpong.sh \"작업 설명\")"
if $NEED_BACKUP; then
  echo ""
  echo "백업 위치: $BACKUP_DIR"
fi
echo ""
