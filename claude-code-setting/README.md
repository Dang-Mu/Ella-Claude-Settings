# 맥 환경 세팅 패키지

Zsh + tmux + Claude Code + Codex 환경을 새 맥으로 그대로 옮기기 위한 마이그레이션 패키지.

---

## ⚠️ 먼저 — 민감정보는 repo에 없습니다

아래 파일들은 **`.gitignore`로 제외**되어 repo에 포함되지 않습니다. 새 맥에서는 기존 맥에서 직접 복사하거나, 각 도구 최초 실행 시 생성됩니다.

| 파일 | 이유 | 새 맥에서 |
|------|------|-----------|
| `claude/settings.json` | OTEL 토큰 등 민감값 | 기존 `~/.claude/settings.json` 복사 또는 Claude Code 최초 실행 시 생성 |
| `codex/config.toml` | 개인 설정 | codex 최초 실행 시 생성 (아래 gws env 추가 필요) |
| `codex/auth.json` | ChatGPT 인증 토큰 | `codex login`으로 생성 |

설치 스크립트가 실행 중에 이들의 존재 여부를 확인하고 안내합니다.

---

## 1. 설치되는 것들

### 터미널 환경
- **Oh My Zsh** / **Powerlevel10k** — 프롬프트 테마 (현재 `ascii` 모드라 특수 폰트 없이도 동작)
- **MesloLGS NF 폰트** (4종) — p10k를 nerdfont 모드로 바꿀 때 대비용
- **tmux** — 터미널 멀티플렉서 (Claude Code Agent Teams에 필요)

### Zsh 플러그인
- **zsh-autosuggestions** / **zsh-syntax-highlighting**

### Homebrew 패키지 (Brewfile)
- **wget**, **jq** (settings.json 병합용), **git-credential-manager**, **karabiner-elements**, **codex**

### CLI 도구
- **Claude Code** (`@anthropic-ai/claude-code`) — 설정·플러그인 자동 복원
- **Codex** (brew cask) — 비민감 설정 자동 복원

---

## 2. 설치 순서

```bash
# 1) 환경 세팅 (brew, zsh, 폰트, tmux, claude, codex 설치 + 비민감 설정 복원)
cd ~/{복사한 경로}/claude-code-setting
chmod +x setup-new-mac.sh
./setup-new-mac.sh

# 2) 도구 인증 (gws, gh) — 상위 폴더의 connect.sh
cd ..
./connect.sh all

# 3) codex 인증 (수동 — claude 로그인처럼)
codex login

# 4) claude 지침/스킬 배포
./install.sh
```

> **인증은 왜 수동인가?** OAuth/PAT는 사람의 브라우저 승인·토큰 입력이 필요해 자동화할 수 없습니다. `connect.sh`는 gws/gh를 "안내 + 검증" 반자동으로 돕고, codex는 `codex login`으로 직접 진행합니다.

---

## 3. Claude Code 설정

`setup-new-mac.sh`가 `claude/`의 비민감 파일(`notify.sh`, `statusline.sh`)을 `~/.claude/`에 복사하고, 플러그인·LSP 의존성을 설치합니다.

- **settings.json**: 민감정보가 있어 repo에 없습니다. 스크립트가 `~/.claude/settings.json` 존재를 확인하고, 없으면 안내합니다. (구성: env, statusLine, enabledPlugins, permissions, hooks, teammateMode)
- **gws 안정화**: settings.json env에 `GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file`이 있어야 gws가 안 풀립니다 (`connect.sh gws`가 자동 반영).
- **notify.sh / statusline.sh**: 알림 훅 / 상태바 스크립트.

---

## 4. Codex 설정

`setup-new-mac.sh`가 codex를 설치하고 `codex/`의 비민감 설정을 `~/.codex/`에 복원합니다.

- **복원되는 것**: `AGENTS.md`(글로벌 지침), `hooks.json`, `skills/`, `agents/`, `rules/`
- **config.toml** (repo에 없음): codex에서 gws를 안정적으로 쓰려면 `[shell_environment_policy.set]`에 아래를 추가하세요 (claude settings.json env와 동일 역할):
  ```toml
  [shell_environment_policy.set]
  GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND = "file"
  ```
- **인증**: `codex login` (수동)

---

## 5. 도구 인증 (connect.sh)

상위 폴더 `Ella-Claude-Settings/connect.sh`로 gws·gh 인증을 돕습니다.

```bash
./connect.sh gws    # Google Workspace — 동의 화면에서 cloud-platform/pubsub 체크 해제
./connect.sh gh     # GitHub — 무만료 PAT 등록
./connect.sh all    # gws + gh
```

- **gws**: 동의 화면에서 `Google Cloud Platform`/`Pub/Sub` 권한을 빼야 조직 재인증 정책(invalid_rapt) 만료를 피합니다.
- **gh**: 기기별 무만료 PAT 사용 (여러 기기 OAuth 토큰 충돌 방지).
- **codex**: connect.sh에 없음 → `codex login` 수동.

---

## 6. 설치 후 점검

- [ ] 새 터미널에서 테마·플러그인 적용 확인
- [ ] `tmux --version` 출력 확인
- [ ] 한글 입력/특수문자 정상 표시
- [ ] `gws auth status` / `gh auth status` / `codex` 정상 동작
- [ ] Claude Code 작업 완료 시 macOS 알림

---

## 7. 폴더 구조

```
claude-code-setting/
├── README.md
├── .gitignore                  ← 민감파일 제외 (settings.json, codex auth.json·config.toml)
├── setup-new-mac.sh            ← 환경 세팅 (이것부터 실행)
├── Brewfile                    ← codex cask 포함
├── zshrc, p10k.zsh, .tmux.conf
├── claude/
│   ├── settings.json           ← ⚠️ .gitignore (홈에서 관리)
│   ├── notify.sh
│   └── statusline.sh
├── codex/                      ← 비민감 설정만
│   ├── AGENTS.md, hooks.json
│   ├── skills/, agents/, rules/
│   └── (auth.json·config.toml  ← ⚠️ .gitignore)
├── karabiner/
└── fonts/                      ← MesloLGS NF 4종
```

(상위 `Ella-Claude-Settings/`에 `connect.sh`, `install.sh`, `CLAUDE.md`가 있습니다.)

---

## 8. 문제 해결

| 증상 | 해결 방법 |
|------|----------|
| gws가 자꾸 풀림 (`invalid_rapt`) | 동의 화면에서 cloud-platform/pubsub 빼고 재로그인 (`connect.sh gws`) |
| gws `Could not decrypt` | `GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file` 설정 확인 |
| gh가 매일 풀림 | 기기별 무만료 PAT 사용 (`connect.sh gh`) |
| codex에서 gws 풀림 | `~/.codex/config.toml`의 `[shell_environment_policy.set]`에 backend env 추가 |
| 프롬프트 아이콘 깨짐 | `p10k configure` 실행 (MesloLGS NF 자동 설치) |
| 자동완성 안 뜸 | `source ~/.zshrc` 후 재확인 |
| Claude Code 알림 안 옴 | 시스템 설정 → 알림에서 터미널 앱 허용 |
