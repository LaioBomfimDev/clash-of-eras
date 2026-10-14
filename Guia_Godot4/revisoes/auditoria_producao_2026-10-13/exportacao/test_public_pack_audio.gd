extends SceneTree
func _init() -> void:
 var base: String = "C:/Users/m/Documents/Relic Arena MY/Guia_Godot4/revisoes/auditoria_producao_2026-10-13/exportacao/"
 assert(ProjectSettings.load_resource_pack("C:/Users/m/Documents/Relic Arena MY/dist/index.pck", true))
 var script: Script = load("res://client/prototype_audio.gd") as Script
 var audio: Node = script.new()
 var report: Dictionary = {"bob_streams_after_real_init":audio.get("bob_streams").size(),"snoop_streams_after_real_init":audio.get("snoop_streams").size(),"tracks":[]}
 for prefix: String in ["bob_marley", "snoop"]:
  for star: int in [1, 2, 3]:
   var p: String = "res://assets/audio/%s_star%d.mp3" % [prefix, star]
   var stream: AudioStream = load(p) as AudioStream
   report["tracks"].append({"path":p,"file_access_exists":FileAccess.file_exists(p),"resource_loader_exists":ResourceLoader.exists(p),"loaded_stream_type":stream.get_class() if stream != null else "NULL","length_sec":stream.get_length() if stream != null else 0.0})
 audio.call("_load_bob_tracks")
 audio.call("_load_snoop_tracks")
 report["bob_streams_after_explicit_reload"] = audio.get("bob_streams").size()
 report["snoop_streams_after_explicit_reload"] = audio.get("snoop_streams").size()
 var dest: FileAccess = FileAccess.open(base + "audio_public_pack_failure.json", FileAccess.WRITE)
 dest.store_string(JSON.stringify(report, "  "))
 dest.close()
 audio.free()
 print(JSON.stringify(report))
 quit(0)
