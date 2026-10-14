extends SceneTree
## Can run against sources or a standalone exported PCK, with no source fallback.
var passed: int = 0
var failed: int = 0
var pack: String = ""
var output: String = ""


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--pack="):
			pack = argument.trim_prefix("--pack=")
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	passed += int(ok)
	failed += int(not ok)
	if not ok:
		push_error("EXPORTED_ASSET_FAIL: " + label)


func _run() -> void:
	if not pack.is_empty():
		if not ProjectSettings.load_resource_pack(pack, true):
			_check(false, "exported PCK mounts")
			quit(1)
			return
	var audio_script: Script = load("res://client/prototype_audio.gd") as Script
	var audio: Node = audio_script.new()
	root.add_child(audio)
	_check(audio.get("bob_streams").size() == 3, "Bob has all three exported tracks")
	_check(audio.get("snoop_streams").size() == 3, "Snoop has all three exported tracks")
	var tracks: Array[Dictionary] = []
	for prefix: String in ["bob_marley", "snoop"]:
		for star: int in [1, 2, 3]:
			var path: String = "res://assets/audio/%s_star%d.mp3" % [prefix, star]
			var key: String = "%s_star%d" % [prefix, star]
			var imported: AudioStreamMP3 = load(path) as AudioStreamMP3
			var stream: AudioStreamMP3 = audio.get("streams").get(key) as AudioStreamMP3
			_check(stream != null and stream.loop and stream.get_length() >= 34.9, key + " loads and loops for 35s")
			_check(stream != null and stream != imported, key + " owns its loop configuration")
			tracks.append({"path": path, "raw_present": FileAccess.file_exists(path),
				"resource_present": ResourceLoader.exists(path), "loaded": stream != null})
			if not pack.is_empty():
				_check(not FileAccess.file_exists(path), key + " needs no duplicate raw MP3 in export")
	audio.call("play_bob_music", 2)
	_check(audio.get("singer_active") and audio.get("current_singer_track") == "bob_marley_star2", "loaded Bob track activates music")
	audio.call("play_singer_music", "michael", 3)
	_check(not audio.get("singer_active"), "singer without track does not mute battle SFX")
	_check(str(audio.get("current_singer_track")).is_empty(), "missing track clears stale selection")
	audio.call("set_enabled", false)
	audio.call("play_snoop_music", 1)
	_check(not audio.get("singer_active"), "disabled audio stays inactive after singer update")
	audio.call("set_enabled", true)
	audio.call("play_snoop_music", 3)
	_check(audio.get("singer_active") and audio.get("current_singer_track") == "snoop_star3", "re-enabled loaded Snoop track activates")
	audio.queue_free()
	var view_script: Script = load("res://client/main.gd") as Script
	var view: Node = view_script.new()
	root.add_child(view)
	view.set_process(false)
	var note: Texture2D = view.get("bob_reggae_note_tex") as Texture2D
	var leaf: Texture2D = view.get("cannabis_leaf_tex") as Texture2D
	_check(note != null and note.get_width() == 64, "Bob uses existing detailed 64px art")
	_check(leaf != null and leaf.get_width() == 64, "Snoop uses existing detailed 64px art")
	_check(view.has_method("_draw_bob_song_buff") and view.has_method("_draw_bob_song_debuff"), "Bob buff/debuff drawers exported")
	_check(view.has_method("_draw_snoop_smoke_zone_atmosphere"), "Snoop atmosphere drawer exported")
	view.queue_free()
	await process_frame
	var report: Dictionary = {"passed": passed, "failed": failed, "pack": pack, "tracks": tracks,
		"scope": "resource loading and presentation contracts, not audible browser playback or balance"}
	if not output.is_empty():
		var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  ") + "\n")
	print("EXPORTED_ASSET_RESULT: " + JSON.stringify(report))
	quit(int(failed > 0))
