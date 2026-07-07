---
name: pingpong
description: Claude ↔ Codex 자동 핑퐁 리뷰 루프 — 세션에서 브레인스토밍 후 헤드리스 루프를 백그라운드로 실행
disable-model-invocation: true
user-invocable: true
---

# /pingpong - Claude ↔ Codex 자동 핑퐁 리뷰 루프

세션 안에서 **브레인스토밍(왜·무엇·범위 확정)** 을 마친 뒤,
격리된 git worktree에서 "Codex 리뷰·수정 → Claude 리뷰·수정"을 수렴할 때까지 반복시킵니다.
루프 본체는 `~/.claude/bin/pingpong.sh`(터미널 스크립트)이며, 이 스킬은 브레인스토밍 단계를
현재 세션에서 대신 수행한 뒤 `SKIP_BRAINSTORM=1`로 스크립트를 백그라운드 실행합니다.

인자로 받은 작업 설명: `$ARGUMENTS` (없으면 STEP 1에서 사용자에게 물어봅니다).

---

## STEP 0: 사전 점검

1. `command -v pingpong.sh` — 없으면 "`claude-install.sh`로 설치가 필요합니다" 안내 후 중단.
2. `command -v codex` — 없으면 "`brew install codex && codex login` 필요" 안내 후 중단.
3. `git rev-parse --is-inside-work-tree` — git 저장소가 아니면 중단 (루프는 워크트리를 씀).
4. `git status --porcelain` 에 변경사항이 있으면, 커밋되지 않은 변경은 워크트리에 안 딸려간다는 점을
   알리고 계속할지 `AskUserQuestion`으로 확인.

---

## STEP 1: 브레인스토밍 (필수)

**`superpowers:brainstorming` 스킬을 사용해** 사용자와 함께 확정합니다:
- **왜** 하는가 (동기 — 약하면 범위 축소·연기 제안)
- **무엇을** 해결하나 (증상과 진짜 문제 구분)
- **범위** (포함 / 제외)

코드는 작성하지 않습니다. 합의가 되면 아래를 **한 문장의 작업 지시**로 압축합니다
(이게 스크립트에 넘길 `TASK` 문자열이 됩니다).

확정 후 `AskUserQuestion`으로 "이 범위로 자동 루프를 시작할까요?"를 확인합니다.
사용자가 아니라고 하면 시작하지 않습니다.

---

## STEP 2: 옵션 결정

`AskUserQuestion`으로 종료 게이트를 정합니다 (기본값 제시):

- **convergence** (기본) — 양쪽 다 고칠 게 없으면 종료
- **test** — `TEST_CMD`(예: `npm test`) 통과를 종료 조건으로. 명령을 물어봄.
- **spec** — 레포의 `SPEC_CRITERIA.md` 기준을 Codex 심판이 통과 판정. 파일 존재 확인.

`MAX_ROUNDS`(기본 5)도 필요하면 조정합니다.

---

## STEP 3: 백그라운드 실행

확정된 `TASK`와 옵션으로 스크립트를 **백그라운드로** 실행합니다.
`SKIP_BRAINSTORM=1`로 STEP 0(스크립트 내부 브레인스토밍)을 건너뜁니다.

```bash
# 예 (convergence, 기본 라운드)
SKIP_BRAINSTORM=1 pingpong.sh "확정된 작업 지시 한 문장"

# 예 (test 게이트)
SKIP_BRAINSTORM=1 GATE_MODE=test TEST_CMD="npm test" MAX_ROUNDS=8 pingpong.sh "..."
```

- **반드시 `run_in_background: true`로 실행**합니다 (루프가 수 분 이상 걸리고, 내부에서
  `claude -p`/`codex exec` 서브프로세스를 반복 호출하므로).
- 실행 직후 스크립트가 출력하는 **워크트리 경로**(`<repo>-pingpong-<타임스탬프>`)와
  **로그 디렉토리**(`<worktree>-logs/`)를 사용자에게 안내합니다.

---

## STEP 4: 진행 안내 & 마무리

1. 백그라운드 작업 ID와 로그 위치를 알립니다. 진행 확인 방법을 안내:
   - 로그: `<worktree>-logs/` 아래 라운드별 `NN-codex.log` / `NN-claude.log`
   - 커밋: `git -C <worktree> log --oneline`
2. 완료(수렴/게이트 통과/MAX_ROUNDS)되면 결과 브랜치 처리 방법을 안내:
   - 채택 → 원본 레포에서 `git merge pingpong/<타임스탬프>`
   - 폐기 → `git worktree remove <worktree> && git branch -D pingpong/<타임스탬프>`

> 이 스킬은 루프를 **대신 돌려주는 트리거**입니다. 실제 리뷰·수정은 별도 `claude`/`codex`
> 프로세스가 수행하며 별도 쿼터를 사용합니다.
