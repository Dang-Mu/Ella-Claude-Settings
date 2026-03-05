---
name: init
description: 코딩 세션 초기화 — 프로젝트 CLAUDE.md 생성, Git/Nxtflow 상태 확인
disable-model-invocation: true
user-invocable: true
---

# /init - 코딩 세션 초기화

---

## STEP 1: 프로젝트 CLAUDE.md 확인/생성

1. `pwd`로 현재 작업 디렉토리를 확인합니다.
2. 프로젝트 루트에 `.claude/CLAUDE.md` 또는 `CLAUDE.md`가 있는지 확인합니다.
3. **이미 있으면** → STEP 2로 진행합니다.
4. **없으면** → 아래 절차로 생성합니다:

### 프로젝트 스캔

다음을 확인하여 프로젝트 정보를 수집합니다:
- `package.json` (name, scripts, dependencies)
- `pyproject.toml`, `Cargo.toml`, `go.mod` 등 언어별 설정 파일
- 디렉토리 구조 (`ls src/`, `ls app/` 등 주요 폴더)
- `README.md` (있으면 프로젝트 설명 참고)

### CLAUDE.md 생성

수집된 정보가 **있으면**:

```markdown
# {프로젝트명}

{한 줄 설명}

## Stack
- {감지된 기술 스택}

## Commands
- `{감지된 스크립트들}`

## Structure
- `{주요 디렉토리 설명}`

---

{~/.claude/coding-guide.md 내용 전체 삽입}
```

수집된 정보가 **없으면**:

```markdown
# {디렉토리명}

---

{~/.claude/coding-guide.md 내용 전체 삽입}
```

`~/.claude/coding-guide.md`를 읽어서 생성할 CLAUDE.md의 맨 아래에 그대로 삽입합니다.

---

## STEP 2: Git 상태 확인

1. `git rev-parse --is-inside-work-tree`로 git 저장소 여부를 확인합니다.
2. **git 저장소가 아니면**:
   - `git init`을 실행하여 로컬 저장소를 생성합니다.
   - `.gitignore`가 없으면 기본 `.gitignore`를 생성합니다 (node_modules, .env 등 프로젝트 스택에 맞게).
   - 초기 커밋: `git add -A && git commit -m "init: 프로젝트 초기화"`
3. **git 저장소이면**:
   - `git branch --show-current` — 현재 브랜치
   - `git status --short` — 변경사항
   - `git log --oneline -5` — 최근 커밋

---

## STEP 3: Nxtflow 태스크 확인

1. `mcp__nxtflow__list_projects`로 프로젝트 목록 조회
2. cwd가 일치하는 프로젝트를 찾습니다.
3. 매칭되면 → `mcp__nxtflow__list_tasks` (projectId, status: ["open"])로 태스크 조회
4. 매칭 안 되면 → "nxtflow 프로젝트 미연동" 표시

---

## STEP 4: 상황 요약

아래 형식으로 요약을 출력합니다:

```
── init ──────────────────
프로젝트: {이름} ({CLAUDE.md 생성됨/기존})
브랜치:   {현재 브랜치}
변경사항: {n files changed / clean}
nxtflow:  {태스크 목록 또는 미연동}
───────────────────────────
```

open 태스크가 있으면 "어떤 태스크를 진행할까요?" 를 `AskUserQuestion`으로 확인합니다.
없으면 "새 작업을 시작하세요." 로 마무리합니다.
