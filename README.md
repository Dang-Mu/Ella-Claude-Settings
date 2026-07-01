# ella-claude-settings

Claude Code 사용을 위한 개인 설정 파일 모음입니다.
프로젝트별 CLAUDE.md 생성, 커밋 워크플로우, 코딩 가이드 등을 표준화합니다.

## 구조

```
.
├── claude-install.sh      # Claude 설정 설치 (→ ~/.claude/)
├── codex-install.sh       # Codex 설정 설치 (→ ~/.codex/, commit·init 스킬 포함)
├── CLAUDE.md              # 글로벌 지시사항 (한국어 응답, 커밋 규칙 등)
├── coding-guide.md        # 코딩 가이드 (Tidy First, 코드 스타일)
└── skills/
    ├── commit/
    │   ├── SKILL.md       # /commit — 대화형 커밋 가이드
    │   └── rules.md       # 커밋 메시지 규칙 (한글, 타입별 분류)
    ├── init/
    │   └── SKILL.md       # /init — 코딩 세션 초기화
    ├── slide-deck/
    │   ├── SKILL.md       # 1920×1080 Pretendard HTML 슬라이드 데크 작성
    │   ├── template.html  # 슬라이드 템플릿
    │   └── catalog.html   # 컴포넌트 카탈로그
    └── slides/
        ├── SKILL.md       # /slides — HTML → Canva 디자인 파이프라인
        ├── render.js      # HTML → PDF (Puppeteer)
        ├── run.sh         # 렌더 + S3 업로드 + manifest
        ├── canva_insert.md
        ├── package.json   # puppeteer 의존성 (최초 호출 시 자동 설치)
        └── package-lock.json
```

> 교육보조 도구(출석부 생성 등)는 별도 저장소 [`edu-assistant/`](../edu-assistant/)에서 관리합니다.

## 설정 파일 설명

### CLAUDE.md
모든 프로젝트에 적용되는 글로벌 규칙:
- 한국어 응답
- 비자명한 작업 전 계획 제안
- 커밋 메시지: 한글 1줄 (`타입: 설명`)
- 정리(tidy)와 기능(feat) 커밋 분리

### coding-guide.md
코딩 철학과 스타일 가이드:
- **Tidy First** (Kent Beck) — 정리 먼저, 기능은 그 다음
- **Make it Work → Right → Fast** — 순서 엄수
- 함수 20줄 이하, 중첩 3단계 이하, Guard Clause 선호
- 커밋 전 자가 점검 체크리스트

## 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/init` | 프로젝트 AGENTS.md 생성, Git 상태 확인 |
| `/commit` | 변경사항 분석 → 타입별 분류 → 대화형 커밋 |
| `/slides` | HTML 슬라이드 → PDF 렌더 → S3 업로드 → Canva 디자인 생성 |
| `slide-deck` | 1920×1080 Pretendard HTML 슬라이드 데크 작성 (모델 자동 호출) |

## 설치

```bash
git clone https://github.com/<your-username>/ella-claude-settings.git
cd ella-claude-settings
./claude-install.sh   # Claude 설정 → ~/.claude/
./codex-install.sh    # Codex 설정 → ~/.codex/ (commit·init 스킬 포함)
```

각 스크립트가 해당 도구의 홈 디렉토리에 설정을 복사합니다.
- 기존 파일이 있으면 `~/.claude/backups/` · `~/.codex/backups/` 에 자동 백업

### 수동 설치

`~/.claude/` 디렉토리에 아래 파일을 직접 배치해도 됩니다:
- `CLAUDE.md` → `~/.claude/CLAUDE.md`
- `coding-guide.md` → `~/.claude/coding-guide.md`
- `skills/` → `~/.claude/skills/`

## 사용법

### 새 프로젝트에서
```bash
# Claude Code에서 /init 실행 → AGENTS.md 자동 생성 (CLAUDE.md는 심링크)
```

## 워크플로우

```
/init → 코딩 → /commit
```

1. `/init`으로 세션 시작 (AGENTS.md 확인/생성, Git 연동)
2. 코딩 작업 수행
3. `/commit`으로 Tidy First 순서에 따라 커밋
