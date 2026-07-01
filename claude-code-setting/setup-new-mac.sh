#!/bin/bash
set -e

# ============================================
# 새 맥북 미니 환경 세팅 스크립트
# ============================================
# 사용법:
#   1. claude-code-setting 폴더를 새 맥으로 복사 (AirDrop, USB 등)
#   2. cd ~/{복사한 경로}/claude-code-setting
#   3. chmod +x setup-new-mac.sh
#   4. ./setup-new-mac.sh
#
# 참고: 민감정보(settings.json, codex/config.toml, 인증 토큰)는 repo에 없습니다.
#       이 스크립트가 실행 중에 안내합니다. 인증은 './connect.sh all'로 진행하세요.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "========================================"
echo "  새 맥북 미니 환경 세팅 시작"
echo "========================================"

# ----- 1. Homebrew 설치 -----
echo ""
echo "[1/9] Homebrew 설치..."
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon Mac의 경우 PATH 설정
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "  -> Homebrew 이미 설치됨. 건너뜀."
fi

# ----- 2. Brewfile로 패키지 일괄 설치 -----
echo ""
echo "[2/9] Homebrew 패키지 설치 (Brewfile)..."
brew bundle --file="$SCRIPT_DIR/Brewfile"
echo "  -> 완료"

# ----- 3. Oh My Zsh 설치 -----
echo ""
echo "[3/9] Oh My Zsh 설치..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "  -> Oh My Zsh 이미 설치됨. 건너뜀."
fi

# ----- 4. Zsh 플러그인 & 테마 설치 -----
echo ""
echo "[4/9] Zsh 플러그인 & 테마 설치..."

# Powerlevel10k
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    echo "  -> Powerlevel10k 설치 완료"
else
    echo "  -> Powerlevel10k 이미 설치됨"
fi

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    echo "  -> zsh-autosuggestions 설치 완료"
else
    echo "  -> zsh-autosuggestions 이미 설치됨"
fi

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    echo "  -> zsh-syntax-highlighting 설치 완료"
else
    echo "  -> zsh-syntax-highlighting 이미 설치됨"
fi

# ----- 5. 폰트 설치 -----
echo ""
echo "[5/9] 폰트 설치..."
mkdir -p ~/Library/Fonts
cp "$SCRIPT_DIR"/fonts/*.ttf ~/Library/Fonts/ 2>/dev/null && echo "  -> 폰트 복사 완료" || echo "  -> 복사할 폰트 없음"

# ----- 6. tmux 설치 확인 -----
echo ""
echo "[6/9] tmux 설치 확인..."
if command -v tmux &>/dev/null; then
    echo "  -> tmux 이미 설치됨: $(tmux -V)"
else
    brew install tmux
    echo "  -> tmux 설치 완료: $(tmux -V)"
fi

# ----- 7. Claude Code 설정 -----
echo ""
echo "[7/9] Claude Code 설정..."

# Claude Code 설치 확인
if ! command -v claude &>/dev/null; then
    echo "  -> Claude Code 설치 중..."
    npm install -g @anthropic-ai/claude-code
else
    echo "  -> Claude Code 이미 설치됨: $(claude --version 2>/dev/null)"
fi

mkdir -p "$HOME/.claude"

# notify.sh 복사 (작업 완료/질문 시 알림용 훅 스크립트)
cp "$SCRIPT_DIR/claude/notify.sh" "$HOME/.claude/notify.sh"
chmod +x "$HOME/.claude/notify.sh"
echo "  -> notify.sh 복사 완료"

# statusline.sh 복사 (Claude Code 상태바 표시용 스크립트)
cp "$SCRIPT_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"
echo "  -> statusline.sh 복사 완료"

# settings.json — 민감정보(OTEL 토큰 등)로 repo에 포함되지 않음. 홈 존재 확인 + 안내.
echo "  -> settings.json 은 민감정보(토큰 등)를 포함하므로 repo에 없습니다."
if [ -f "$HOME/.claude/settings.json" ]; then
    echo "     ✔ 기존 ~/.claude/settings.json 발견 — 그대로 사용합니다."
else
    echo "     ⚠ ~/.claude/settings.json 이 없습니다."
    echo "       기존 맥의 ~/.claude/settings.json 을 복사해 오거나, Claude Code 최초 실행 시 생성하세요."
fi

# LSP 플러그인 의존성 설치 (npm 전역 패키지)
if command -v npm &>/dev/null; then
    echo "  -> LSP 의존성 설치 중..."
    npm install -g pyright typescript typescript-language-server 2>/dev/null \
        && echo "    ✔ pyright, typescript-language-server 설치 완료" \
        || echo "    ✘ npm 전역 설치 실패 (나중에 수동 설치 필요)"
else
    echo "  -> npm이 없어 LSP 의존성 설치를 건너뜁니다. Node.js 설치 후 수동으로:"
    echo "     npm install -g pyright typescript typescript-language-server"
fi

# Claude Code 플러그인 설치
if command -v claude &>/dev/null; then
    echo "  -> Claude Code 플러그인 설치 중..."
    PLUGINS=(
        "code-review"
        "context7"
        "github"
        "pyright-lsp"
        "ralph-loop"
        "security-guidance"
        "typescript-lsp"
    )
    for plugin in "${PLUGINS[@]}"; do
        claude plugins install "$plugin" 2>/dev/null && echo "    ✔ $plugin" || echo "    ✘ $plugin (건너뜀)"
    done

    # planning-with-files (별도 마켓플레이스)
    claude plugins marketplace add OthmanAdi/planning-with-files 2>/dev/null
    claude plugins install planning-with-files@planning-with-files 2>/dev/null \
        && echo "    ✔ planning-with-files" || echo "    ✘ planning-with-files (건너뜀)"
else
    echo "  -> Claude Code가 설치되어 있지 않아 플러그인 설치를 건너뜁니다."
fi

# ----- 8. Codex 설치 -----
echo ""
echo "[8/9] Codex 설치 확인..."

# Codex 바이너리 설치 확인 (Brewfile의 cask "codex"로 설치되지만, 누락 시 대비)
if ! command -v codex &>/dev/null; then
    echo "  -> Codex 설치 중..."
    brew install codex
else
    echo "  -> Codex 이미 설치됨: $(codex --version 2>/dev/null)"
fi

# 지침·스킬·설정 배포는 별도 단계에서 codex-install.sh 로 진행 (claude-install.sh와 대칭)
echo "  -> Codex 지침·스킬 배포는 상위 폴더의 './codex-install.sh' 로 진행하세요."

# ----- 9. 설정 파일 복원 -----
echo ""
echo "[9/9] 설정 파일 복원..."

# .zshrc 복원 (기존 파일 백업 후)
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    echo "  -> 기존 .zshrc 백업 완료"
fi
cp "$SCRIPT_DIR/zshrc" "$HOME/.zshrc"
echo "  -> .zshrc 복원 완료"

# .p10k.zsh 복원
cp "$SCRIPT_DIR/p10k.zsh" "$HOME/.p10k.zsh"
echo "  -> .p10k.zsh 복원 완료"

# .tmux.conf 복원
if [ -f "$HOME/.tmux.conf" ]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
    echo "  -> 기존 .tmux.conf 백업 완료"
fi
cp "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
echo "  -> .tmux.conf 복원 완료"

# Karabiner 설정 복원
if [ -d "$SCRIPT_DIR/karabiner" ]; then
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/karabiner" "$HOME/.config/karabiner"
    echo "  -> Karabiner 설정 복원 완료"
fi

# ----- 완료 -----
echo ""
echo "========================================"
echo "  설치 완료!"
echo "========================================"
echo ""
echo "다음 단계:"
echo "  1. 터미널을 새로 열거나 'source ~/.zshrc'를 실행하세요."
echo "  2. 도구 인증: './connect.sh all' (gws, gh)"
echo "  3. codex 인증: 'codex login' (수동)"
echo "  4. claude 지침/스킬 배포: 상위 폴더의 './claude-install.sh'"
echo "  5. codex 지침/스킬 배포: 상위 폴더의 './codex-install.sh'"
echo ""
