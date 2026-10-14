extends SceneTree
func _init() -> void:
 var base: String = "C:/Users/m/Documents/Relic Arena MY/Guia_Godot4/revisoes/auditoria_producao_2026-10-13/exportacao/"
 var pck_path: String = "C:/Users/m/Documents/Relic Arena MY/dist/index.pck"
 var loaded: bool = ProjectSettings.load_resource_pack(pck_path, true)
 assert(loaded)
 var script: Script = load("res://client/vfx_library.gd") as Script
 assert(script != null)
 var vfx: RefCounted = script.new()
 vfx.call("load_assets")
 var effects: Dictionary = vfx.get("effects")
 var report: Dictionary = {"pack_loaded":loaded,"effect_count":effects.size(),"effects":{}}
 for k: String in effects:
  var e: Dictionary = effects[k]
  var texture: Texture2D = e.get("texture") as Texture2D
  report["effects"][k] = {"path":e.get("texture_path"),"texture_loaded":texture != null,"size":str(texture.get_size()) if texture != null else "NULL","frames":e.get("frames"),"fps":e.get("fps")}
 var main: Script = load("res://client/main.gd") as Script
 report["main_loaded"] = main != null
 var selected_methods: Dictionary = {}
 for name: String in ["_draw_bob_song_buff", "_draw_bob_song_debuff", "_draw_snoop_smoke_zone_atmosphere", "_draw_world_hero_tooltip", "_draw_bob_musical_notes", "_draw_snoop_cigar"]:
  selected_methods[name] = false
 if main != null:
  for method: Dictionary in main.get_script_method_list():
   var m: String = str(method.get("name"))
   if selected_methods.has(m):
    selected_methods[m] = true
 report["main_methods"] = selected_methods
 var dest: FileAccess = FileAccess.open(base + "runtime_library_pack.json", FileAccess.WRITE)
 dest.store_string(JSON.stringify(report, "  "))
 dest.close()
 print(JSON.stringify(report))
 quit(0 if effects.size() == 17 else 1)
