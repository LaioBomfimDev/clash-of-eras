/* Browser-only lobby background. Godot owns all interface and input above this layer. */
(function installLobbyBackground(window, document) {
	"use strict";
	if (window.clashLobbyBackground) return;

	const POSTER = "media/lobby_poster.webp";
	const VIDEO = "media/lobby_loop.mp4";
	const reducedMotion = window.matchMedia ? window.matchMedia("(prefers-reduced-motion: reduce)") : null;
	const connection = window.navigator.connection || window.navigator.mozConnection || window.navigator.webkitConnection;
	let active = false;
	let eco = false;
	let revision = 0;
	let layer = null;
	let video = null;
	let canvas = null;
	let sourceAssigned = false;
	let showingVideo = false;
	let inFlight = null;
	let waitingForGesture = false;
	let mediaFailed = false;
	let lastError = "";
	let resizeObserver = null;

	function wantsVideo() {
		return active && !eco && !document.hidden && !(reducedMotion && reducedMotion.matches) && !(connection && connection.saveData) && !mediaFailed;
	}

	function showPoster() {
		showingVideo = false;
		if (video) video.style.opacity = "0";
	}

	function layout() {
		if (!layer || !canvas) return;
		// Godot's keep-aspect viewport is 1280x720, centered inside the canvas.
		const bounds = canvas.getBoundingClientRect();
		const width = Math.max(0, bounds.width);
		const height = Math.max(0, bounds.height);
		const scale = Math.min(width / 16, height / 9);
		const fittedWidth = scale * 16;
		const fittedHeight = scale * 9;
		layer.style.left = (bounds.left + (width - fittedWidth) / 2) + "px";
		layer.style.top = (bounds.top + (height - fittedHeight) / 2) + "px";
		layer.style.width = fittedWidth + "px";
		layer.style.height = fittedHeight + "px";
	}

	function initialize() {
		if (layer) return true;
		canvas = document.getElementById("canvas");
		if (!canvas || !canvas.parentNode) return false;
		layer = document.createElement("div");
		layer.id = "clash-lobby-background";
		layer.setAttribute("aria-hidden", "true");
		Object.assign(layer.style, {
			position: "fixed", display: "none", overflow: "hidden", pointerEvents: "none",
			backgroundColor: "#08040f", zIndex: "0"
		});
		const poster = document.createElement("img");
		poster.src = POSTER;
		poster.alt = "";
		poster.draggable = false;
		Object.assign(poster.style, {
			position: "absolute", inset: "0", width: "100%", height: "100%", objectFit: "contain"
		});
		video = document.createElement("video");
		video.id = "clash-lobby-video";
		video.muted = true;
		video.defaultMuted = true;
		video.playsInline = true;
		video.loop = true;
		video.controls = false;
		video.preload = "none";
		video.disablePictureInPicture = true;
		video.poster = POSTER;
		video.setAttribute("muted", "");
		video.setAttribute("playsinline", "");
		Object.assign(video.style, {
			position: "absolute", inset: "0", width: "100%", height: "100%", objectFit: "contain",
			opacity: "0", transition: "opacity 200ms ease", pointerEvents: "none"
		});
		video.addEventListener("playing", function () {
			if (!wantsVideo()) {
				video.pause();
				showPoster();
				return;
			}
			waitingForGesture = false;
			lastError = "";
			showingVideo = true;
			video.style.opacity = "1";
		});
		video.addEventListener("pause", function () {
			if (video.paused) showPoster();
		});
		video.addEventListener("error", function () {
			mediaFailed = true;
			waitingForGesture = false;
			lastError = "media:" + (video.error ? video.error.code : "unknown");
			video.pause();
			showPoster();
		});
		layer.appendChild(poster);
		layer.appendChild(video);
		canvas.parentNode.insertBefore(layer, canvas);
		if (window.ResizeObserver) {
			resizeObserver = new window.ResizeObserver(layout);
			resizeObserver.observe(canvas);
		}
		layout();
		return true;
	}

	function startVideo() {
		if (!video || !wantsVideo() || inFlight || waitingForGesture || !video.paused) return;
		if (!sourceAssigned) {
			video.src = VIDEO;
			sourceAssigned = true;
			video.load();
		}
		const ticket = revision;
		let attempt;
		try {
			attempt = video.play();
		} catch (error) {
			waitingForGesture = true;
			lastError = "play:" + (error && error.name ? error.name : "Error");
			video.pause();
			showPoster();
			return;
		}
		inFlight = Promise.resolve(attempt).then(function () {
			// A pending autoplay must never revive the video after leaving the lobby.
			if (ticket !== revision || !wantsVideo()) {
				video.pause();
				showPoster();
			}
		}, function (error) {
			if (ticket !== revision || !wantsVideo()) return;
			waitingForGesture = true;
			lastError = "play:" + (error && error.name ? error.name : "Error");
			video.pause();
			showPoster();
		}).then(function () {
			inFlight = null;
			// If the player left and re-entered while play() was pending, start a fresh attempt.
			if (ticket !== revision && wantsVideo()) startVideo();
		});
	}

	function reconcile() {
		if (!initialize()) return;
		layout();
		layer.style.display = active && !document.hidden ? "block" : "none";
		if (!wantsVideo()) {
			if (inFlight || !video.paused) video.pause();
			showPoster();
			return;
		}
		startVideo();
	}

	function environmentChanged() {
		revision += 1;
		reconcile();
	}

	window.clashLobbyBackground = {
		setActive: function (nextActive, nextEco) {
			const changed = active !== Boolean(nextActive) || eco !== Boolean(nextEco);
			active = Boolean(nextActive);
			eco = Boolean(nextEco);
			if (!changed && layer) return;
			revision += 1;
			reconcile();
		},
		getState: function () {
			return {
				active: active,
				paused: !video || video.paused,
				time: video && Number.isFinite(video.currentTime) ? video.currentTime : 0,
				ready: showingVideo && wantsVideo(),
				error: lastError
			};
		}
	};

	function retryFromGesture(event) {
		if (event.isTrusted === false || !waitingForGesture || !wantsVideo()) return;
		waitingForGesture = false;
		startVideo();
	}
	// Observe gestures without preventing default behavior or consuming Godot's input.
	document.addEventListener("pointerdown", retryFromGesture, { capture: true, passive: true });
	document.addEventListener("keydown", retryFromGesture, { capture: true, passive: true });
	document.addEventListener("visibilitychange", environmentChanged);
	window.addEventListener("resize", layout, { passive: true });
	if (window.visualViewport) window.visualViewport.addEventListener("resize", layout, { passive: true });
	if (reducedMotion) {
		if (reducedMotion.addEventListener) reducedMotion.addEventListener("change", environmentChanged);
		else if (reducedMotion.addListener) reducedMotion.addListener(environmentChanged);
	}
	if (connection && connection.addEventListener) connection.addEventListener("change", environmentChanged);
	if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", reconcile, { once: true });
	else reconcile();
})(window, document);
