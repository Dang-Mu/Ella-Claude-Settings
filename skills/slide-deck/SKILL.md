---
name: slide-deck
description: 1920×1080 Pretendard HTML 슬라이드 데크를 생성/편집할 때 사용. PDF→슬라이드 변환, 새 슬라이드 데크 작성, 기존 슬라이드 컴포넌트 추가/수정 시 이 스킬의 template.html과 catalog.html을 베이스로 작업할 것.
---

# slide-deck — HTML 슬라이드 데크 작성 가이드

1920×1080 Pretendard 슬라이드 데크. 다크 배경(`#020617`)에 흰 슬라이드들이 위아래로 쌓이는 레이아웃. 인쇄·`/slides`(Canva) 파이프라인과 호환.

## 파일

- `template.html` — CSS 전체 + 보일러플레이트(hero 1장 + 일반 슬라이드 1장). **새 데크 시작 시 이 파일을 사용자 작업 디렉토리로 복사**한 뒤 슬라이드 추가.
- `catalog.html` — 모든 컴포넌트 사용 예시 29슬라이드. **컴포넌트 사용법·색상 변형·배치 패턴 참고용**. 그대로 복사하지 말고 패턴만 차용.

## 사용 흐름

1. 사용자가 새 슬라이드 데크를 요청하면 `template.html`을 작업 디렉토리로 복사
2. 컴포넌트 조립이 필요할 땐 `catalog.html`에서 유사 패턴을 찾아 본문 구조만 차용
3. 마지막에 페이지 번호 등장순 재매김 (아래 스크립트)

## 컴포넌트 카탈로그

| 컴포넌트 | 클래스 | 용도 |
|---|---|---|
| 표지 | `layout-hero` | 데크 표지 / 파트 표지 |
| 콜아웃 | `block-callout` | 핵심 한 줄 강조 |
| 인용 | `block-quote` | 명언·원문 |
| 표 | `block-table` (`lg`) | 비교표·항목표 |
| 단계 | `block-steps` (`three`) | 1·2·3 프로세스 |
| 비교 | `block-compare` | 좌우 대조 |
| 셀 | `block-cells` (`three`/`lg`) | 3등분 카드 |
| 요약 | `block-summary` | 불릿 박스 |
| 불릿 | `block-bullets` | 큰 불릿 리스트 |
| 메가 | `block-mega` | "A vs B" 중앙 강조 |
| 이미지 | `block-image` | 단일 이미지 |
| 분할 | `block-split` | 텍스트+이미지 좌우 |

## 색상 변형

대부분 컴포넌트가 `amber`(기본) / `pink` / `blue` / `green` / `ink` 모디파이어 지원:
- `block-callout.pink`, `compare-card.blue`, `step-card.green`, `cell.amber`, `tag.pink` 등
- `layout-hero.part2`(blue) / `.part3`(pink) / `.part4`(green) — 표지 그라데이션

## 슬라이드 단위 사이즈 조정 (중요)

박스 내용이 슬라이드 밖으로 잘리면 **`smaller`**, 여백이 과하면 **`bigger`**:

```html
<section class="slide smaller"> <!-- table.lg, summary, compare-card 텍스트 축소 -->
<section class="slide bigger">  <!-- callout, cell, compare-card 텍스트 확대 -->
```

**전역 폰트는 절대 만지지 말 것.** 한 슬라이드만 안 맞을 땐 항상 `smaller`/`bigger`로 처리. 기본 사이즈는 다음 슬라이드들의 균형을 위해 설계되어 있음.

## 페이지 번호 재매김

슬라이드 추가/삭제 후 등장순 01부터 매기기:

```python
import re
with open(path) as f: s = f.read()
i = [0]
def r(m):
    i[0] += 1
    return f'<div class="s-page">{i[0]:02d}</div>'
s = re.sub(r'<div class="s-page">\d+</div>', r, s)
with open(path, 'w') as f: f.write(s)
```

## 출력 절대 규칙

- **메타포·비유 금지** (다리·축·묶는다 등). 직설적 표현만.
- 코드 안에 무의미한 주석 금지. 슬라이드 구역 표시 주석(`<!-- ====== 01 · 제목 ====== -->`)만 허용.
- 강조는 `<strong>` 사용. 색상 강조는 `<span class="amber|pink|blue|green">`.
- HTML은 단일 파일. 외부 CSS·JS·폰트 의존 없음(Pretendard CDN만).
