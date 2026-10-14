extends SceneTree
func _init() -> void:
 var base: String = "C:/Users/m/Documents/Relic Arena MY/Guia_Godot4/revisoes/auditoria_producao_2026-10-13/exportacao/"
 var blob: PackedByteArray = FileAccess.get_file_as_bytes(base + "public_main.gdc")
 var expected: int = blob.decode_u32(8)
 var raw: PackedByteArray = blob.slice(12).decompress(expected, FileAccess.COMPRESSION_ZSTD)
 assert(raw.size() == expected)
 var dest: FileAccess = FileAccess.open(base + "public_main_tokens.bin", FileAccess.WRITE)
 dest.store_buffer(raw)
 dest.close()
 var ids: Array[String] = []
 var pos: int = 16
 for i: int in range(raw.decode_u32(0)):
  var length: int = raw.decode_u32(pos)
  pos += 4
  var s: String = ""
  for j: int in range(length):
   var word: int = raw.decode_u32(pos) ^ 0xb6b6b6b6
   s += String.chr(word)
   pos += 4
  ids.append(s)
 var ids_file: FileAccess = FileAccess.open(base + "public_main_identifiers.json", FileAccess.WRITE)
 ids_file.store_string(JSON.stringify(ids, "  "))
 ids_file.close()
 print("TOKEN_BUFFER_OK bytes=", raw.size(), " identifiers=", ids.size())
 quit(0)
