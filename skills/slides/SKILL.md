---
name: slides
description: HTML 슬라이드(여러 .slide section 포함)를 Canva 디자인으로 자동 변환. 호출 시 인자로 HTML 파일 경로를 받아 PDF 렌더 → S3 업로드 → Canva import 순으로 처리하고 새 디자인 URL을 반환합니다.
disable-model-invocation: true
user-invocable: true
---

# /slides — HTML → Canva 파이프라인

단일 HTML 파일에 여러 `<section class="slide">`를 넣으면, 각 section이 하나의 Canva 디자인 페이지로 들어간 새 디자인을 만듭니다.

## 사용법

사용자 호출:
```
/slides <html_파일_경로>
```

경로는 상대/절대 모두 허용. 상대경로면 사용자의 현재 작업 디렉토리 기준으로 해석합니다.

## 입력 HTML 규약

- 전체 1920px 너비
- 각 슬라이드: `<section class="slide">...</section>` (1920×1080)
- 슬라이드 간 시각 구분용 `.slide-gap` 허용 (인쇄 시 자동 숨김)
- 스타일 충돌 방지용 네임스페이스 클래스 권장 (`.s1`, `.s2` 등)

## 절차

### STEP 1 — HTML 경로 검증
1. 인자에서 HTML 경로 추출.
2. 상대경로면 현재 작업 디렉토리 기준 절대화 (`readlink -f` 또는 `realpath`).
3. 파일이 없으면 사용자에게 경로 확인 요청 후 중단. `.html` 확장자가 아니면 경고 후 계속.

### STEP 2 — 파이프라인 실행
Bash 도구로:
```
bash ~/.claude/skills/slides/run.sh <html_abs_path>
```

이 스크립트가 하는 일:
- Puppeteer로 HTML → 멀티페이지 PDF 렌더 (`.slide` 단위 페이지 분할)
- PDF를 S3 업로드 (`ella.kim-hosting`, path-style URL)
- `manifest.json` 작성 (`pdf_url`, `slug`, `pdf_path`)

실패하면 에러 원문 그대로 사용자에게 보여주고 중단.

### STEP 3 — manifest 읽기
Read 도구로 STEP 2 출력의 `Manifest:` 경로를 읽어 `pdf_url`, `slug` 추출.

### STEP 4 — Canva 새 디자인 생성
```
mcp__claude_ai_Canva__import-design-from-url(
  url:  {manifest.pdf_url},
  name: {manifest.slug},
  user_intent: "Import rendered slide PDF as a new Canva design via /slides skill"
)
```

응답에서 `job.result.designs[0]`의 `id`, `urls.edit_url`, `urls.view_url`, `page_count` 추출.

에러 시 원문 표시 + URL 접근성/버킷 공개 여부 점검 안내.

### STEP 5 — 결과 보고

사용자에게 아래 표 형식으로 한 번에 제공:

```
✅ Canva 디자인 생성 완료

| 항목      | 값                                         |
|-----------|-------------------------------------------|
| 디자인 ID | {id}                                      |
| 편집 URL  | {edit_url}                                |
| 보기 URL  | {view_url}                                |
| 페이지 수 | {page_count}                              |
| 원본 PDF  | {pdf_path}                                |
```

## 파일 구성

- `render.js` — HTML → PDF (Puppeteer, print CSS 주입으로 `.slide` 단위 페이지 분할)
- `run.sh` — 렌더 + S3 업로드 + manifest 작성
- `canva_insert.md` — 이 스킬의 STEP 4 상세 (대응표 포함)
- `package.json` — puppeteer 의존성 (최초 호출 시 `run.sh`가 자동 설치)

## 주의

- S3 버킷: `ella.kim-hosting` (고정). path-style URL 필수 (버킷명 점 포함 → virtual-hosted는 SSL 실패).
- `import-design-from-url`은 **항상 새 디자인**을 만듦. 기존 디자인 수정/갱신은 이 스킬 범위 밖.
- 출력 PDF/manifest는 입력 HTML 옆 `_out/<slug>/`에 저장됨 (원본 디렉토리 쓰기 가능해야 함).
