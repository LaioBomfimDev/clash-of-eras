/* Deterministic lifecycle tests; no browser, game state, credentials or network. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname, "../client/lobby_video.js"), "utf8");
let checks = 0;
function check(condition, message) { assert.ok(condition, message); checks += 1; }
function deferred() {
	let resolve, reject;
	const promise = new Promise((yes, no) => { resolve = yes; reject = no; });
	return { promise, resolve, reject };
}
async function settle() { for (let i = 0; i < 5; i += 1) await Promise.resolve(); }
class Events {
	constructor() { this.listeners = new Map(); }
	addEventListener(type, callback, options) {
		const rows = this.listeners.get(type) || [];
		rows.push({ callback, options }); this.listeners.set(type, rows);
	}
	emit(type, fields = {}) {
		for (const row of [...(this.listeners.get(type) || [])]) {
			row.callback({ type, ...fields });
			if (row.options && row.options.once) this.listeners.set(type, this.listeners.get(type).filter(item => item !== row));
		}
	}
}
class Element extends Events {
	constructor(tag) {
		super(); this.tagName = tag; this.style = {}; this.attributes = {}; this.children = [];
		this.parentNode = null; this.src = "";
	}
	setAttribute(name, value) { this.attributes[name] = value; }
	appendChild(child) { this.children.push(child); child.parentNode = this; }
	insertBefore(child, reference) {
		const index = this.children.indexOf(reference); assert.ok(index >= 0);
		this.children.splice(index, 0, child); child.parentNode = this;
	}
	getBoundingClientRect() { return this.bounds || { left: 0, top: 0, width: 1280, height: 720 }; }
}
class Video extends Element {
	constructor() { super("video"); this.paused = true; this.currentTime = 0; this.playCalls = 0; this.pauseCalls = 0; this.loadCalls = 0; this.attempts = []; }
	load() { this.loadCalls += 1; }
	play() {
		this.playCalls += 1; this.paused = false;
		const attempt = this.attempts.shift();
		if (attempt instanceof Error) throw attempt;
		return attempt ? attempt.promise : Promise.resolve();
	}
	pause() { this.pauseCalls += 1; this.paused = true; this.emit("pause"); }
	playing() { this.paused = false; this.emit("playing"); }
}
function fixture({ loading = false, reduced = false, saveData = false, missingCanvas = false } = {}) {
	const doc = new Events();
	doc.readyState = loading ? "loading" : "complete"; doc.hidden = false;
	const body = new Element("body"); const canvas = new Element("canvas"); canvas.id = "canvas";
	if (!missingCanvas) body.appendChild(canvas);
	const made = [];
	doc.getElementById = id => id === "canvas" && canvas.parentNode ? canvas : made.find(item => item.id === id) || null;
	doc.createElement = tag => { const value = tag === "video" ? new Video() : new Element(tag); made.push(value); return value; };
	const motion = new Events(); motion.matches = reduced;
	const connection = new Events(); connection.saveData = saveData;
	const win = new Events(); win.navigator = { connection }; win.matchMedia = () => motion;
	win.visualViewport = new Events();
	win.ResizeObserver = class { constructor(fn) { this.fn = fn; } observe() {} };
	const context = vm.createContext({ window: win, document: doc, Promise, Number });
	vm.runInContext(source, context);
	return { api: win.clashLobbyBackground, doc, win, motion, connection, body, canvas, made,
		get video() { return made.find(item => item.tagName === "video"); },
		get layer() { return made.find(item => item.id === "clash-lobby-background"); } };
}

(async function run() {
	{
		const f = fixture();
		check(f.layer.style.display === "none" && f.video.src === "", "Inactive initialization does not download video");
		check(f.body.children[0] === f.layer && f.body.children[1] === f.canvas, "Background is inserted behind canvas in DOM order");
		check(f.layer.style.pointerEvents === "none", "Background never intercepts input");
		check(f.video.muted && f.video.defaultMuted && f.video.playsInline && f.video.loop && f.video.preload === "none", "Inline silent lazy playback configured");
		f.api.setActive(true, true);
		check(f.layer.style.display === "block" && f.video.playCalls === 0 && f.video.src === "", "Eco mode only displays poster and does not assign video source");
		f.api.setActive(true, true);
		check(f.video.playCalls === 0 && f.video.pauseCalls === 0, "Unchanged eco state is idempotent");
		const attempt = deferred(); f.video.attempts.push(attempt);
		f.api.setActive(true, false);
		check(f.video.src === "media/lobby_loop.mp4" && f.video.loadCalls === 1 && f.video.playCalls === 1, "Video source assigned only at first animated lobby");
		check(!f.api.getState().ready && f.video.style.opacity === "0", "Poster remains while play promise is pending");
		f.video.playing(); attempt.resolve(); await settle();
		check(f.api.getState().ready && f.video.style.opacity === "1" && f.video.style.transition.includes("200ms"), "Playing reveals video with short fade");
		f.api.setActive(true, false); f.api.setActive(true, false);
		check(f.video.playCalls === 1, "Repeated active state does not restart playback");
		f.api.setActive(false, false);
		check(f.video.paused && f.layer.style.display === "none" && !f.api.getState().ready, "Leaving lobby pauses and hides video");
		f.api.setActive(false, false);
		check(f.video.pauseCalls === 1, "Repeated inactive state does not issue redundant pauses");
		f.api.setActive(true, false); f.video.playing(); await settle();
		check(f.video.loadCalls === 1 && f.video.playCalls === 2, "Returning resumes existing cached source");
		check(Object.keys(f.api.getState()).join(",") === "active,paused,time,ready,error", "Diagnostics contain only agreed playback fields");
	}
	{
		const f = fixture(); const attempt = deferred(); f.video.attempts.push(attempt);
		f.api.setActive(true, false); f.api.setActive(false, false);
		f.video.playing(); attempt.resolve(); await settle();
		check(f.video.paused && f.layer.style.display === "none" && !f.api.getState().ready, "Late play completion/playing event cannot revive exited lobby");
	}
	{
		const f = fixture(); const attempt = deferred(); f.video.attempts.push(attempt);
		f.api.setActive(true, false); f.api.setActive(false, false); f.api.setActive(true, false);
		check(f.video.playCalls === 1, "Reentry does not create competing pending play promises");
		attempt.resolve(); await settle(); f.video.playing();
		check(f.video.playCalls === 2 && !f.video.paused && f.api.getState().ready, "Reentry retries after stale pending promise settles");
	}
	{
		const f = fixture(); const attempt = deferred(); f.video.attempts.push(attempt);
		f.api.setActive(true, false);
		const error = new Error("Browser policy"); error.name = "NotAllowedError";
		f.video.paused = true; attempt.reject(error); await settle();
		check(f.api.getState().error === "play:NotAllowedError" && !f.api.getState().ready, "Autoplay rejection preserves fallback with safe error category");
		f.api.setActive(true, false); f.doc.emit("pointerdown", { isTrusted: false });
		check(f.video.playCalls === 1, "No automatic retry loop or synthetic gesture retry");
		let consumed = false;
		f.doc.emit("pointerdown", { isTrusted: true, preventDefault() { consumed = true; }, stopPropagation() { consumed = true; } });
		f.video.playing(); await settle();
		check(f.video.playCalls === 2 && f.api.getState().error === "" && !consumed, "Real gesture retries without consuming game input");
	}
	{
		const f = fixture(); const error = new Error("Synchronous policy failure"); error.name = "NotAllowedError";
		f.video.attempts.push(error); f.api.setActive(true, false);
		check(f.video.paused && f.api.getState().error === "play:NotAllowedError" && !f.api.getState().ready, "Synchronous play failure also pauses safely");
		f.doc.emit("keydown", { isTrusted: true }); f.video.playing(); await settle();
		check(f.api.getState().ready && f.video.playCalls === 2, "Keyboard gesture can recover synchronous playback rejection");
	}
	{
		const f = fixture(); const attempt = deferred(); f.video.attempts.push(attempt);
		f.api.setActive(true, false); f.api.setActive(true, true);
		f.video.playing(); attempt.resolve(); await settle();
		check(f.video.paused && !f.api.getState().ready && f.layer.style.display === "block", "Eco selected during pending autoplay cannot be undone by late completion");
		f.api.setActive(true, false); f.video.playing(); await settle();
		check(f.api.getState().ready && f.video.loadCalls === 1, "Leaving eco resumes same source without new download");
	}
	{
		const f = fixture(); f.api.setActive(true, false); f.video.playing(); await settle();
		f.doc.hidden = true; f.doc.emit("visibilitychange");
		check(f.video.paused && f.layer.style.display === "none", "Hidden tab stops video decoding request and hides layer");
		f.doc.hidden = false; f.doc.emit("visibilitychange"); f.video.playing(); await settle();
		check(f.api.getState().ready && f.layer.style.display === "block", "Visible tab resumes only active animated lobby");
		f.api.setActive(false, false); const calls = f.video.playCalls;
		f.doc.hidden = true; f.doc.emit("visibilitychange"); f.doc.hidden = false; f.doc.emit("visibilitychange");
		check(f.video.playCalls === calls && f.layer.style.display === "none", "Visibility changes cannot play outside lobby");
	}
	for (const kind of ["reduced", "saveData"]) {
		const f = fixture({ [kind]: true }); f.api.setActive(true, false);
		check(f.video.src === "" && f.video.playCalls === 0 && f.layer.style.display === "block", `${kind} displays poster without video download`);
		if (kind === "reduced") { f.motion.matches = false; f.motion.emit("change"); }
		else { f.connection.saveData = false; f.connection.emit("change"); }
		f.video.playing(); await settle();
		check(f.api.getState().ready, `${kind} change can enable animated lobby`);
		if (kind === "reduced") { f.motion.matches = true; f.motion.emit("change"); }
		else { f.connection.saveData = true; f.connection.emit("change"); }
		check(f.video.paused && !f.api.getState().ready, `${kind} change pauses active video`);
	}
	{
		const f = fixture(); f.api.setActive(true, false); f.video.playing(); await settle();
		f.video.error = { code: 3 }; f.video.emit("error");
		check(f.api.getState().error === "media:3" && f.video.paused && f.video.style.opacity === "0", "Decode failure pauses and retains poster");
		const calls = f.video.playCalls;
		f.doc.emit("pointerdown", { isTrusted: true }); f.api.setActive(false, false); f.api.setActive(true, false);
		check(f.video.playCalls === calls, "Fatal media error never causes automatic retry storm");
	}
	{
		const f = fixture(); f.canvas.bounds = { left: 10, top: 20, width: 1000, height: 1000 }; f.win.emit("resize");
		check(f.layer.style.width === "1000px" && f.layer.style.height === "562.5px" && f.layer.style.top === "238.75px", "Square viewport letterboxes centered 16:9");
		f.canvas.bounds = { left: 0, top: 0, width: 1600, height: 720 }; f.win.visualViewport.emit("resize");
		check(f.layer.style.left === "160px" && f.layer.style.width === "1280px" && f.layer.style.height === "720px", "Wide viewport aligns with Godot keep-aspect pillarbox");
	}
	{
		const f = fixture({ loading: true, missingCanvas: true }); f.api.setActive(true, false);
		check(!f.video && f.api.getState().paused, "Early bridge call before DOM is safe");
		f.body.appendChild(f.canvas); f.doc.emit("DOMContentLoaded"); await settle();
		check(f.video.playCalls === 1 && f.layer.style.display === "block", "Deferred DOM setup applies pending lobby state");
		const existing = f.api; vm.runInContext(source, vm.createContext({ window: f.win, document: f.doc, Promise, Number }));
		check(f.win.clashLobbyBackground === existing && f.made.filter(item => item.tagName === "video").length === 1, "Accidental module reloading does not duplicate background");
	}
	console.log(JSON.stringify({ checks, failures: 0, scope: "Node/mock DOM lifecycle, not browser FPS or hardware decode" }));
})().catch(error => { console.error(error); process.exitCode = 1; });
