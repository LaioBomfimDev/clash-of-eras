// Usage: node measure_web_runtime.cjs URL OUTPUT_DIRECTORY
// Uses an isolated browser, never the user's profile. Does not join public matches.
const fs = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require(process.env.CLASH_PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const url = process.argv[2];
  const output = path.resolve(process.argv[3]);
  const expectCapped = process.argv.includes('--expect-capped');
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CLASH_BROWSER_EXE || undefined,
    headless: true,
  });
  const report = { url, at: new Date().toISOString(), scope: 'Isolated desktop Chrome landing page. Browser rAF measures the page main thread, NOT Godot render FPS or phone performance.', cases: [] };
  try {
    for (const dpr of [1, 2]) {
      const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: dpr });
      const page = await context.newPage();
      const errors = [];
      const consoleLines = [];
      page.on('pageerror', error => errors.push(error.message));
      page.on('console', message => {
        if (consoleLines.length < 100) consoleLines.push(message.type() + ': ' + message.text());
      });
      const start = performance.now();
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 45000 });
      let ready = true;
      try { await page.waitForFunction(() => !document.querySelector('#status'), null, { timeout: 45000 }); }
      catch { ready = false; }
      const readyMs = performance.now() - start;
      const metrics = await page.evaluate(async () => {
        const gaps = [];
        const longTasks = [];
        let observer;
        try {
          observer = new PerformanceObserver(list => list.getEntries().forEach(e => longTasks.push(e.duration)));
          observer.observe({ type: 'longtask', buffered: false });
        } catch {}
        await new Promise(resolve => {
          let previous = 0;
          const started = performance.now();
          function frame(now) {
            if (previous) gaps.push(now - previous);
            previous = now;
            if (now - started > 3000) resolve(); else requestAnimationFrame(frame);
          }
          requestAnimationFrame(frame);
        });
        observer?.disconnect();
        const sorted = gaps.slice().sort((a, b) => a - b);
        const canvas = document.querySelector('canvas');
        return { crossOriginIsolated, dpr: devicePixelRatio, hardwareConcurrency: navigator.hardwareConcurrency,
          canvas: canvas ? { width: canvas.width, height: canvas.height, cssWidth: canvas.clientWidth, cssHeight: canvas.clientHeight } : null,
          browserRafSamples: gaps.length, browserRafMeanMs: gaps.reduce((a, b) => a + b, 0) / Math.max(1, gaps.length),
          browserRafP95Ms: sorted[Math.floor(sorted.length * 0.95)] || 0, longTasks,
          godotMetrics: window.__clashPerformance || null,
          resources: performance.getEntriesByType('resource').filter(e => /\.(wasm|pck|js)(\?|$)/.test(e.name)).map(e => ({ name: new URL(e.name).pathname, durationMs: e.duration, transferSize: e.transferSize })) };
      });
      await page.screenshot({ path: path.join(output, `landing_dpr${dpr}.png`) });
      const checks = [];
      if (expectCapped) {
        checks.push({ name: 'release starts without page or Godot script errors', ok: ready && errors.length === 0 && !consoleLines.some(line => /SCRIPT ERROR|(^|: )ERROR:/.test(line)) });
        checks.push({ name: 'backing buffer is capped at 1280x720', ok: metrics.canvas?.width <= 1280 && metrics.canvas?.height <= 720 });
        checks.push({ name: 'numeric diagnostics are present', ok: typeof metrics.godotMetrics?.client_cpu_ms === 'number' && metrics.godotMetrics.render_width > 0 });
        await page.setViewportSize({ width: 720, height: 1280 });
        await page.waitForFunction(() => { const c = document.querySelector('canvas'); return c && c.height > c.width && c.height <= 720; }, null, { timeout: 5000 });
        const portrait = await page.evaluate(() => ({ width: document.querySelector('canvas').width, height: document.querySelector('canvas').height }));
        checks.push({ name: 'portrait resize keeps orientation and cap', ok: portrait.height > portrait.width && portrait.height <= 720 });
        await page.screenshot({ path: path.join(output, `portrait_dpr${dpr}.png`) });
        if (checks.some(c => !c.ok)) process.exitCode = 1;
      }
      report.cases.push({ dpr, ready, readyMs, metrics, checks, errors, consoleLines });
      await context.close();
    }
  } finally { await browser.close(); }
  await fs.writeFile(path.join(output, 'runtime.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report.cases.map(c => ({ dpr: c.dpr, ready: c.ready, readyMs: c.readyMs, metrics: c.metrics, errors: c.errors })), null, 2));
})().catch(error => { console.error(error.stack); process.exitCode = 1; });
