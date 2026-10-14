const fs = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require(process.env.CLASH_PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const out = path.resolve(process.argv[2]);
  await fs.mkdir(out, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.CLASH_BROWSER_EXE, headless: true });
  const report = { scope: 'Real Chrome compendium navigation; no matchmaking', errors: [], screenshots: [] };
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    page.on('pageerror', error => report.errors.push(error.message));
    page.on('console', msg => { if (/SCRIPT ERROR|^ERROR:/.test(msg.text())) report.errors.push(msg.text()); });
    await page.goto(process.argv[3] || 'http://127.0.0.1:8771/');
    await page.waitForFunction(() => !document.querySelector('#status') && window.clashLobbyBackground?.getState().active, null, { timeout: 45000 });
    await page.mouse.click(170, 650);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(out, 'galeria.png') });
    report.screenshots.push('galeria.png');
    for (const [key, x] of [['snoop', 538], ['bob', 930]]) {
      await page.mouse.click(x, 383);
      await page.waitForTimeout(1800);
      await page.screenshot({ path: path.join(out, key + '_ficha.png') });
      report.screenshots.push(key + '_ficha.png');
      await page.mouse.click(135, 48);
      await page.waitForTimeout(300);
    }
    if (report.errors.length) throw new Error('Godot/browser errors detected');
  } catch (error) { report.failure = error.stack; process.exitCode = 1; }
  finally { await browser.close(); }
  await fs.writeFile(path.join(out, 'browser.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report));
})();
