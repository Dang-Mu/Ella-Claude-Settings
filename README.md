# ella-claude-settings

Claude Code 사용을 위한 개인 설정 파일 모음입니다.
프로젝트별 CLAUDE.md 생성, 커밋 워크플로우, 코딩 가이드 등을 표준화합니다.

## 구조

```
.
├── install.sh             # 설치 스크립트 (→ ~/.claude/ 복사)
├── CLAUDE.md              # 글로벌 지시사항 (한국어 응답, 커밋 규칙 등)
├── coding-guide.md        # 코딩 가이드 (Tidy First, 코드 스타일)
├── commands/
│   └── nxtflow-sync.md    # /nxtflow-sync — 작업 내용 nxtflow 동기화
└── skills/
    ├── commit/
    │   ├── SKILL.md       # /commit — 대화형 커밋 가이드
    │   └── rules.md       # 커밋 메시지 규칙 (한글, 타입별 분류)
    └── init/
        └── SKILL.md       # /init — 코딩 세션 초기화
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
| `/init` | 프로젝트 CLAUDE.md 생성, Git/Nxtflow 상태 확인 |
| `/commit` | 변경사항 분석 → 타입별 분류 → 대화형 커밋 |
| `/nxtflow-sync` | 커밋 내용을 nxtflow 태스크에 동기화 |

## 설치

```bash
git clone https://github.com/<your-username>/ella-claude-settings.git
cd ella-claude-settings
./install.sh
```

스크립트가 `~/.claude/` 디렉토리에 설정 파일을 복사합니다.
- 기존 파일이 있으면 `~/.claude/backups/` 에 자동 백업
- `nxtflow-sync` 등 개인 서비스 의존 파일은 선택적으로 설치

### 수동 설치

`~/.claude/` 디렉토리에 아래 파일을 직접 배치해도 됩니다:
- `CLAUDE.md` → `~/.claude/CLAUDE.md`
- `coding-guide.md` → `~/.claude/coding-guide.md`
- `commands/` → `~/.claude/commands/`
- `skills/` → `~/.claude/skills/`

## 사용법

### 새 프로젝트에서
```bash
# Claude Code에서 /init 실행 → CLAUDE.md 자동 생성
```

## 워크플로우

```
/init → 코딩 → /commit → /nxtflow-sync
```

1. `/init`으로 세션 시작 (CLAUDE.md 확인, Git/Nxtflow 연동)
2. 코딩 작업 수행
3. `/commit`으로 Tidy First 순서에 따라 커밋
4. `/nxtflow-sync`로 태스크 상태 반영 (커밋 완료 시 자동 체이닝)
