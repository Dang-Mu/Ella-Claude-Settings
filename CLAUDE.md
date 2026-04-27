# CLAUDE.md

Always respond in Korean (한국어).

## Planning
- Propose a brief plan before non-trivial work (new features, multi-file changes, architectural decisions).
- Trivial work (typos, obvious fixes, single-line changes) — just do it.
- If multiple reasonable approaches exist, present them with tradeoffs. Don't pick silently.

## Communication
- Be direct and specific. No hedging on technical recommendations.
- If uncertain, say so and ask — don't guess.
- When recommending: state what, why, and what could go wrong.

## Defaults
- Prefer editing existing files over creating new ones.
- Don't create documentation files (README, etc.) unless asked.
- Stop after 3 failed attempts and reassess the approach.

## 참고사항
- **노션**: 특별한 언급이 없으면 "Ella.Kim" 노션 페이지를 의미합니다.

## 커밋
- 커밋 메시지는 **한글 1줄** (`타입: 설명`). 정리와 기능을 절대 섞지 말 것.
- 상세 규칙: `~/.claude/skills/commit/rules.md` 참조.
- 커밋 시 `/commit` 커맨드 사용 권장.

## 코딩 가이드
- 코드 작업 시 `~/.claude/coding-guide.md`를 참조할 것.

---

Last Updated: 2026-03-05
