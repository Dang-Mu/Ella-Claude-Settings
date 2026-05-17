#!/usr/bin/env bash
# 사용법: ./run.sh <html_file>
#
# 동작:
#   1. HTML → 멀티페이지 PDF (.slide 단위)
#   2. PDF → S3 업로드 (path-style URL)
#   3. _out/<slug>/manifest.json 작성
#
# Canva 반영(import-design-from-url)은 SKILL.md에서 Claude가 담당.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

html=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) echo "Usage: $0 <html_file>"; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) html="$1"; shift ;;
  esac
done

if [[ -z "$html" ]]; then
  echo "Usage: $0 <html_file>" >&2
  exit 1
fi
if [[ ! -f "$html" ]]; then
  echo "File not found: $html" >&2
  exit 1
fi

html_abs=$(cd "$(dirname "$html")" && pwd)/$(basename "$html")
slug=$(basename "$html_abs" .html)

# 1. 의존성
if [[ ! -d "$SCRIPT_DIR/node_modules/puppeteer" ]]; then
  echo "📦 Puppeteer 설치 (최초 1회)..."
  (cd "$SCRIPT_DIR" && npm install)
fi

# 2. 렌더
echo "🎨 PDF 렌더: $html_abs"
pdf_path=$(node "$SCRIPT_DIR/render.js" "$html_abs")
if [[ -z "$pdf_path" || ! -f "$pdf_path" ]]; then
  echo "❌ PDF 렌더 실패" >&2
  exit 1
fi

# 3. 업로드
echo "☁️  S3 업로드..."
bucket="ella.kim-hosting"
region="ap-northeast-2"
ts=$(date +%s)
key="canva/${slug}/${ts}_${slug}.pdf"
aws s3 cp "$pdf_path" "s3://${bucket}/${key}" --content-type application/pdf --only-show-errors
pdf_url="https://s3.${region}.amazonaws.com/${bucket}/${key}"

# 4. 매니페스트
out_dir=$(dirname "$pdf_path")
manifest="$out_dir/manifest.json"
{
  echo "{"
  echo "  \"slug\": \"$slug\","
  echo "  \"pdf_path\": \"$pdf_path\","
  echo "  \"pdf_url\": \"$pdf_url\""
  echo "}"
} > "$manifest"

# 5. 결과
echo ""
echo "✅ 파이프라인 단계 완료"
echo "   PDF: $pdf_path"
echo "   URL: $pdf_url"
echo "   Manifest: $manifest"
