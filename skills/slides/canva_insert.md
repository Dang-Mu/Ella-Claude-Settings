# Canva 반영 절차 (새 디자인 생성 전용)

> `run.sh`가 만든 `manifest.json`을 Canva에 import하여 새 디자인을 만드는 절차.
> `/slides` 스킬의 STEP 4에서 참조됨.

## 입력 형식

`manifest.json`:
```json
{
  "slug": "...",
  "pdf_path": "...",
  "pdf_url": "https://s3..."
}
```

## 절차

단 하나의 MCP 호출로 완료:

```
mcp__claude_ai_Canva__import-design-from-url(
  url:  manifest.pdf_url,
  name: manifest.slug,
  user_intent: "Import rendered slide PDF as a new Canva design"
)
→ job.result.designs[0] = { id, title, urls: { edit_url, view_url }, page_count }
```

PDF의 각 페이지가 Canva 디자인 페이지로 들어옴. 각 페이지는 단일 이미지 요소 — 사용자가 크기/위치만 조정.

## 보고 형식

사용자에게 다음을 표로 제공:

| 항목 | 값 |
|---|---|
| 디자인 ID | `{id}` |
| 편집 URL | `{edit_url}` |
| 보기 URL | `{view_url}` |
| 페이지 수 | `{page_count}` (manifest의 PDF 페이지 수와 일치해야 정상) |

## 실패 시나리오별 대응

| 상황 | 대응 |
|---|---|
| `import-design-from-url`가 에러 | 원문 그대로 표시 + URL 접근성 확인 안내 |
| 페이지 수 불일치 | PDF와 디자인 페이지 수 둘 다 제시하고 사용자 판단 요청 |
| S3 URL 접근 실패 | path-style 형식 여부(`https://s3.{region}.amazonaws.com/...`) 점검 안내 |

## 주의

- PDF URL은 공개 접근 가능해야 함 — 현재 `ella.kim-hosting` 버킷은 열려 있음 (검증됨)
- 버킷명에 점(.)이 있어서 **path-style URL 필수**. virtual-hosted는 SSL 실패
- `import-design-from-url`은 **항상 새 디자인**을 만듦. 기존 디자인 갱신 불가
