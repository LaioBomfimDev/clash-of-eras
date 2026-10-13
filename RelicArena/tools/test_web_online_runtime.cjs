// Integration smoke: two isolated Web clients against an owned local Godot server.
// Never joins the public matchmaking service. Server must listen on 127.0.0.1:8910.
const fs = require('node:fs/promises');
const path = require('node:path');
const { spawn } = require('node:child_process');
const { chromium } = require(process.env.CLASH_PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const output = path.resolve(process.argv[2]);
  const baseUrl = process.argv[3] || 'http://127.0.0.1:8766/';
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.CLASH_BROWSER_EXE, headless: true });
  const oneClient = process.argv.includes('--one-client');
  const report = { scope: `${oneClient ? 'One real Web export plus native headless peer' : 'Two real Web exports'} in desktop Chrome, loopback server. Not public Render latency or phone FPS.`, cases: [] };
  let pages = [];
  let peer;
  let peerOutput = '';
  const logs = [[], []];
  const errors = [[], []];
  try {
    const dprs = oneClient ? [2] : [1, 2];
    const contexts = await Promise.all(dprs.map(deviceScaleFactor => browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor })));
    pages = await Promise.all(contexts.map(context => context.newPage()));
    await Promise.all(pages.map(async (page, index) => {
      page.on('console', message => logs[index].push(message.text()));
      page.on('pageerror', error => errors[index].push(error.message));
      await page.addInitScript(() => {
        const NativeWebSocket = window.WebSocket;
        window.WebSocket = class extends NativeWebSocket {
          constructor(url, protocols) {
            super(String(url).startsWith('wss://clash-of-eras-server.onrender.com') ? 'ws://127.0.0.1:8910' : url, protocols);
          }
        };
      });
      await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 45000 });
      await page.waitForFunction(() => !document.querySelector('#status'), null, { timeout: 45000 });
    }));
    if (process.argv.includes('--one-client')) {
      if (!process.env.CLASH_GODOT_EXE) throw new Error('CLASH_GODOT_EXE is required for --one-client');
      peer = spawn(process.env.CLASH_GODOT_EXE, ['--headless', '--path', path.resolve(__dirname, '..'), '--script', 'res://tools/headless_web_test_peer.gd'], { windowsHide: true });
      peer.stdout.on('data', chunk => { peerOutput += chunk; });
      peer.stderr.on('data', chunk => { peerOutput += chunk; });
      peer.on('error', error => { peerOutput += error.stack; });
      await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Native peer did not reach the local queue: ' + peerOutput)), 10000);
        peer.stdout.on('data', () => {
          if (peerOutput.includes('PERF_PEER_QUEUE_READY')) { clearTimeout(timeout); resolve(); }
        });
        peer.on('exit', code => { clearTimeout(timeout); reject(new Error('Native peer exited before matchmaking: ' + code + '\n' + peerOutput)); });
      });
    }
    await Promise.all(pages.map(page => page.mouse.click(1150, 650)));
    await Promise.all(pages.map(page => page.waitForFunction(() => window.__clashPerformance?.rtt_ms >= 0, null, { timeout: 20000 })));
    for (let index = 0; index < pages.length; index++) await pages[index].screenshot({ path: path.join(output, `joined_dpr${index + 1}.png`) });
    const preparation = pages.map(page => page.waitForEvent('console', { predicate: message => message.text().includes('CLIENT_PHASE: preparation'), timeout: 15000 }));
    await Promise.all(pages.map(page => page.mouse.click(450, 350)));
    await Promise.all(preparation);
    await Promise.all(pages.map(async page => {
      for (const x of [670, 785, 900, 1015]) await page.mouse.click(x, 655);
      await page.keyboard.press('F3');
    }));
    for (let index = 0; index < pages.length; index++) await pages[index].screenshot({ path: path.join(output, `preparation_dpr${index + 1}.png`) });
    const combat = pages.map(page => page.waitForEvent('console', { predicate: message => message.text().includes('CLIENT_PHASE: combat'), timeout: 20000 }));
    await Promise.all(pages.map(page => page.mouse.click(1180, 650)));
    await Promise.all(combat);
    // Let at least two one-second diagnostic windows sample actual combat.
    await new Promise(resolve => setTimeout(resolve, 2500));
    await Promise.all(pages.map(page => page.waitForFunction(() => window.__clashPerformance?.client_cpu_ms >= 0 && window.__clashPerformance.rtt_ms >= 0, null, { timeout: 10000 })));
    const samples = await Promise.all(pages.map(page => page.evaluate(async () => {
      const result = [];
      for (let sample = 0; sample < 8; sample++) {
        result.push({ ...window.__clashPerformance });
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      return result;
    })));
    for (let index = 0; index < pages.length; index++) {
      const metrics = await pages[index].evaluate(() => window.__clashPerformance);
      await pages[index].screenshot({ path: path.join(output, `combat_dpr${index + 1}.png`) });
      const frames = samples[index].map(sample => sample.frame_ms).sort((a, b) => a - b);
      report.cases.push({ dpr: dprs[index], metrics, samples: samples[index], sampleMedianFrameMs: frames[Math.floor(frames.length / 2)],
        errors: errors[index], logs: logs[index], combatStarted: logs[index].some(line => line.includes('CLIENT_PHASE: combat')) });
    }
    if (report.cases.some(c => c.errors.length || c.logs.some(line => /SCRIPT ERROR|^ERROR:/.test(line)) || !c.combatStarted || c.metrics.rtt_ms < 0)) process.exitCode = 1;
  } catch (error) {
    report.error = error.message;
    process.exitCode = 1;
    for (let index = 0; index < pages.length; index++) {
      await pages[index].screenshot({ path: path.join(output, `failure_dpr${index + 1}.png`) }).catch(() => {});
      report.cases.push({ dpr: index + 1, errors: errors[index], logs: logs[index] });
    }
  } finally {
    if (peer) peer.kill();
    if (peerOutput) await fs.writeFile(path.join(output, 'native_peer.log'), peerOutput);
    await browser.close();
  }
  await fs.writeFile(path.join(output, 'web_online.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
})().catch(error => { console.error(error.stack); process.exitCode = 1; });
