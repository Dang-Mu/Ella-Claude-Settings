#!/usr/bin/env bash
# ============================================================================
# pingpong.sh — Claude <-> Codex 자동 핑퐁 리뷰 루프 (안전 모드)
#
#   한 라운드 = "Codex 리뷰·수정 -> Claude 리뷰·수정"
#   종료 조건(아래 셋 중 하나):
#     1) 수렴      : 한 라운드 동안 양쪽 다 고칠 게 없음
#     2) 게이트 통과: GATE_MODE=test|spec 일 때 합격
#     3) 상한 도달 : MAX_ROUNDS
#
#   격리: git worktree 로 레포 사본을 별도 디렉토리에 만들어 거기서만 작업.
#         원본 작업복사본/브랜치는 건드리지 않음.
#   권한: 안전 모드 (풀-바이패스 아님)
#         - Claude : acceptEdits + 도구 화이트리스트
#         - Codex  : --sandbox workspace-write (쓰기는 워크스페이스 한정, 기본 네트워크 차단)
#         - 심판   : --sandbox read-only (고치지 못하게)
#
#   사용법:
#     pingpong.sh "수행할 작업 설명"
#     MAX_ROUNDS=8 GATE_MODE=spec pingpong.sh "스펙 문서 보강"
#     GATE_MODE=test TEST_CMD="npm test" pingpong.sh "결제 모듈 리팩토링"
# ============================================================================
set -euo pipefail

# ===== 설정 (환경변수로 덮어쓰기 가능) =====
TASK="${1:?사용법: pingpong.sh \"수행할 작업 설명\"}"
MAX_ROUNDS=${MAX_ROUNDS:-5}

# 게이트 모드: convergence(기본) | test | spec
GATE_MODE=${GATE_MODE:-convergence}
TEST_CMD=${TEST_CMD:-"npm test"}              # GATE_MODE=test 일 때 실행할 명령
GATE_CRITERIA=${GATE_CRITERIA:-"SPEC_CRITERIA.md"}  # GATE_MODE=spec 일 때 합격 기준 문서

# 브레인스토밍 게이트 건너뛰기 (STEP 0). /pingpong 스킬처럼 이미 세션에서
# 왜·무엇·범위를 확정한 뒤 헤드리스로 루프만 돌릴 때 SKIP_BRAINSTORM=1 로 실행.
SKIP_BRAINSTORM=${SKIP_BRAINSTORM:-0}

# ===== 사전 점검 =====
command -v claude >/dev/null 2>&1 \
  || { echo "❌ 'claude' CLI 를 찾을 수 없습니다. Claude Code 설치 후 다시 시도하세요."; exit 1; }
command -v codex  >/dev/null 2>&1 \
  || { echo "❌ 'codex' CLI 를 찾을 수 없습니다. 'brew install codex' 후 'codex login' 하세요."; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "❌ git 저장소가 아닙니다. 먼저 'git init' 후 커밋 한 번 하세요."; exit 1; }

REPO_ROOT=$(git rev-parse --show-toplevel)
STAMP=$(date +%Y%m%d-%H%M%S)
BRANCH="pingpong/$STAMP"
WT_DIR="${REPO_ROOT}-pingpong-$STAMP"          # 레포 옆에 격리 워크트리

if [[ "$GATE_MODE" == "spec" && ! -f "$REPO_ROOT/$GATE_CRITERIA" ]]; then
  echo "❌ GATE_MODE=spec 인데 합격 기준 파일이 없습니다: $GATE_CRITERIA"; exit 1
fi

# ===== STEP 0: 브레인스토밍 게이트 =====
# 자동 루프 진입 전, 사람과 함께 '왜·무엇·범위'를 확정한다 (작업 원칙 ✅1).
# 증상과 진짜 문제를 구분하고, 동기가 약하면 범위를 줄이거나 멈춘다.
# SKIP_BRAINSTORM=1 이면 이 단계를 건너뛴다 (호출 측에서 이미 확정한 경우).
if [[ "$SKIP_BRAINSTORM" != "1" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  STEP 0: 브레인스토밍 (필수)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "자동 리뷰 루프 진입 전, 인터랙티브 브레인스토밍으로 '왜·무엇·범위'를 확정합니다."
  echo

  claude "다음은 자동 리뷰 루프에 넣기 직전 단계다. brainstorming 스킬을 사용해 사용자와 함께 '왜 하는가 / 무엇을 해결하나 / 범위(포함·제외)'를 확정하라. 증상과 진짜 문제를 구분하고, 동기가 약하면 범위 축소·연기를 제안하라. 코드는 작성하지 말고 합의된 내용을 마지막에 요약만 하라. 작업: $TASK"

  echo
  read -rp "브레인스토밍으로 왜·무엇·범위가 확정됐습니까? 자동 루프를 시작할까요? [y/N] " _ok
  [[ "$_ok" =~ ^[Yy]$ ]] || { echo "🛑 미확정 — 루프를 시작하지 않습니다."; exit 1; }
else
  echo "▶ SKIP_BRAINSTORM=1 — 브레인스토밍 단계 건너뜀 (호출 측에서 범위 확정 완료)"
fi

# ===== 격리 워크트리 생성 후 그 안으로 이동 =====
echo "▶ 격리 워크트리 생성: $WT_DIR  (브랜치 $BRANCH)"
git worktree add -b "$BRANCH" "$WT_DIR" >/dev/null
cd "$WT_DIR"

# 로그는 레포 '밖'에 기록 — git이 전혀 추적하지 않으므로 커밋/머지에 절대 안 섞임.
# 워크트리를 삭제해도 로그는 남아 사후 추적 가능.
LOG_DIR="${WT_DIR}-logs"; mkdir -p "$LOG_DIR"

# ===== 헬퍼 =====
commit_if_changed () {   # 변경 있으면 커밋하고 0(=변경됨), 없으면 1
  [[ -n "$(git status --porcelain)" ]] || return 1
  git add -A && git commit -q -m "$1"; return 0
}

run_claude () {          # $1=프롬프트  — 안전 모드
  claude -p "$1" \
    --permission-mode acceptEdits \
    --allowedTools "Bash,Read,Edit,Write,Grep,Glob"
}

run_codex () {           # $1=프롬프트  — 쓰기 가능 샌드박스
  codex exec --sandbox workspace-write "$1"
}

gate_passed () {         # 0=통과(루프 종료) / 1=미통과(계속)
  local n="$1"
  case "$GATE_MODE" in
    convergence)
      return 1 ;;        # 별도 게이트 없음 — 수렴 판정으로만 종료
    test)
      echo "▶ 테스트 게이트: $TEST_CMD"
      if bash -c "$TEST_CMD" >"$LOG_DIR/$n-gate.log" 2>&1; then
        echo "  ✅ 테스트 통과"; return 0
      else
        echo "  ❌ 테스트 실패 (로그: $LOG_DIR/$n-gate.log)"; return 1
      fi ;;
    spec)
      echo "▶ 스펙 게이트 심판 (read-only)"
      local v
      v=$(codex exec --sandbox read-only \
        "현재 작업 결과물을 '$GATE_CRITERIA' 의 모든 기준에 비춰 평가하라. 절대 수정하지 말고 평가만 하라. 모든 기준 충족이면 마지막 줄에 정확히 'GATE: PASS', 하나라도 미충족이면 'GATE: FAIL — <미충족 항목>' 을 출력하라." \
        | tee "$LOG_DIR/$n-gate.log" | tail -1)
      if [[ "$v" == "GATE: PASS"* ]]; then
        echo "  ✅ 스펙 게이트 통과"; return 0
      else
        echo "  ❌ 미통과: $v"; LAST_GATE_REASON="$v"; return 1
      fi ;;
  esac
}

LAST_GATE_REASON=""

# ===== 0라운드: Claude 초기 작업 =====
echo "===== Round 0 : 초기 작업 (Claude) ====="
run_claude "다음 작업을 수행하라: $TASK" | tee "$LOG_DIR/00-claude-init.log"
commit_if_changed "claude: 초기 작업" || echo "  (변경 없음)"

# ===== 핑퐁 루프 =====
for ((r=1; r<=MAX_ROUNDS; r++)); do
  echo "===== Round $r / $MAX_ROUNDS ====="
  n=$(printf '%02d' "$r")
  hint=""
  [[ -n "$LAST_GATE_REASON" ]] && hint=" 참고로 직전 게이트 미통과 사유: $LAST_GATE_REASON"

  echo "▶ Codex 리뷰+수정"
  run_codex "직전 커밋의 변경(git diff HEAD~1)을 리뷰하라. 버그·품질·누락을 찾고 문제가 있으면 직접 수정하라. 고칠 게 전혀 없으면 아무 파일도 바꾸지 말고 'REVIEW: APPROVED' 만 출력하라.$hint" \
    | tee "$LOG_DIR/$n-codex.log"
  codex_changed=false; commit_if_changed "codex: round $r 리뷰 수정" && codex_changed=true

  echo "▶ Claude 리뷰+수정"
  run_claude "Codex가 방금 수정한 변경(git diff HEAD~1)을 리뷰하라. 회귀나 잘못된 수정이 있으면 고쳐라. 고칠 게 없으면 'REVIEW: APPROVED' 만 출력하고 아무것도 바꾸지 마라.$hint" \
    | tee "$LOG_DIR/$n-claude.log"
  claude_changed=false; commit_if_changed "claude: round $r 리뷰 수정" && claude_changed=true

  # --- 종료 판정 ---
  if gate_passed "$n"; then
    echo "✅ 게이트 통과로 종료 (라운드 $r)"; break
  fi
  if ! $codex_changed && ! $claude_changed; then
    echo "✅ 수렴: 양쪽 모두 수정할 게 없음 (라운드 $r 종료)"; break
  fi
  [[ $r -eq $MAX_ROUNDS ]] && echo "⚠️ MAX_ROUNDS($MAX_ROUNDS) 도달 — 미수렴 상태로 종료"
done

# ===== 마무리 안내 =====
echo
echo "──────────────────────────────────────────────"
echo "끝. 작업 위치 : $WT_DIR"
echo "    브랜치   : $BRANCH"
echo "    로그     : $LOG_DIR/   (레포 밖 — 워크트리 삭제해도 보존됨)"
echo
git log --oneline -n 20
echo "──────────────────────────────────────────────"
echo "결과 확인 후 처리:"
echo "  • 채택 → 원본 레포에서:  git merge $BRANCH"
echo "  • 폐기 → git worktree remove \"$WT_DIR\" && git branch -D $BRANCH"
