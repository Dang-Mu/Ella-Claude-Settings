import puppeteer from 'puppeteer';
import { dirname, basename, resolve, join } from 'path';
import { mkdirSync } from 'fs';

const htmlArg = process.argv[2];
if (!htmlArg) {
  console.error('Usage: node render.js <html_file>');
  process.exit(1);
}

const htmlPath = resolve(htmlArg);
const slug = basename(htmlPath, '.html');
const outDir = resolve(dirname(htmlPath), '_out', slug);
mkdirSync(outDir, { recursive: true });

const browser = await puppeteer.launch({ headless: 'new' });
const page = await browser.newPage();
await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
await page.goto('file://' + htmlPath, { waitUntil: 'networkidle0' });

// 인쇄 모드 전용 스타일 주입:
//   - 각 .slide = 1 페이지
//   - .slide-gap 숨김
//   - 배경/색상 강제 출력
await page.addStyleTag({ content: `
  @page { size: 1920px 1080px; margin: 0; }
  @media print {
    html, body {
      width: 1920px !important;
      margin: 0 !important;
      padding: 0 !important;
      background: #0F172A !important;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    .slide-gap { display: none !important; }
    .slide {
      width: 1920px !important;
      height: 1080px !important;
      page-break-after: always;
      break-after: page;
      overflow: hidden !important;
    }
    .slide:last-of-type {
      page-break-after: auto;
      break-after: auto;
    }
  }
`});

// 로컬 폰트 안정 로딩용 짧은 지연
await new Promise(r => setTimeout(r, 500));

const pdfPath = join(outDir, `${slug}.pdf`);
await page.pdf({
  path: pdfPath,
  width: '1920px',
  height: '1080px',
  printBackground: true,
  preferCSSPageSize: true,
  margin: { top: 0, right: 0, bottom: 0, left: 0 }
});

// 페이지 수 확인 (.slide 개수)
const slideCount = await page.$$eval('.slide', els => els.length);

await browser.close();

// stdout: PDF 경로 1줄
console.log(pdfPath);
// stderr: 요약
console.error(`📄 ${slideCount} slides → ${pdfPath}`);
