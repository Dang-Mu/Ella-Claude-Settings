---
description: nxtflow에 작업 내용을 동기화하고 태스크 상태를 업데이트합니다
---

# /nxtflow-sync - Nxtflow 작업 동기화

커밋된 작업 내용을 nxtflow 프로젝트에 반영합니다.
독립 실행 또는 `/commit` 완료 후 자동 체이닝으로 실행됩니다.

---

## STEP 1: 프로젝트 매칭

1. `pwd`로 현재 작업 디렉토리를 확인합니다.
2. `mcp__nxtflow__list_projects`로 프로젝트 목록을 조회합니다.
3. **cwd가 일치하는 프로젝트**를 찾습니다.
4. 매칭되는 프로젝트가 없으면:
   - `AskUserQuestion`으로 "이 디렉토리에 대한 nxtflow 프로젝트가 없습니다. 생성할까요?" 확인
   - 승인 시 `mcp__nxtflow__create_project`로 생성 (cwd 포함)
   - 거부 시 **종료**

---

## STEP 2: 최근 작업 내용 파악

1. `git log --oneline -10`으로 최근 커밋을 확인합니다.
2. 커밋 메시지들을 요약하여 "이번에 한 작업"을 파악합니다.

---

## STEP 3: 관련 태스크 조회

1. 매칭된 프로젝트의 **open 태스크**를 조회합니다:
   - `mcp__nxtflow__list_tasks` (projectId, status: ["open"])
2. 커밋 내용과 관련된 태스크가 있는지 매칭합니다.

---

## STEP 4: 태스크 상태 업데이트

### 관련 태스크가 있는 경우:
1. `AskUserQuestion`으로 사용자에게 확인합니다:
   - "이 태스크를 완료 처리할까요?" + 매칭된 태스크 목록
   - 옵션: "완료 처리" / "상태만 변경" / "건너뛰기"
2. 승인 시 `mcp__nxtflow__update_task`로 status를 `done`으로 변경합니다.

### 관련 태스크가 없는 경우:
1. `AskUserQuestion`으로 확인합니다:
   - "관련 태스크가 없습니다. 완료된 태스크를 새로 기록할까요?"
   - 옵션: "기록" / "건너뛰기"
2. 기록 시 `mcp__nxtflow__create_task`로 생성합니다:
   - subject: 커밋 메시지 기반 요약
   - projectId: 매칭된 프로젝트
   - status: done
   - contexts: ["src:claude-code", "capture:explicit", "domain:code"]

---

## STEP 5: 완료 요약

동기화 결과를 간결하게 표시합니다:

```
✓ 프로젝트: {프로젝트명}
✓ 업데이트: {태스크 제목} → done
```

---

## 주의사항

- 사용자 확인 없이 태스크를 자동 변경하지 않습니다.
- 프로젝트 매칭은 cwd 기준이 우선입니다.
- 독립 실행 시에도 동일한 워크플로우를 따릅니다.
