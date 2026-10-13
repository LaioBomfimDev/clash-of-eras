extends RefCounted
## Protocolo compartilhado entre cliente e servidor online.
## Mensagens são Dictionary codificados com var_to_bytes (sem objetos) e comprimidos.

const VERSION: int = 1
## Tempo de busca por outro jogador antes de cair contra o bot local.
const QUEUE_SECONDS: float = 20.0
## Endereço público do servidor (Render). Pode ser trocado por ?server=wss://... na versão web.
const DEFAULT_SERVER_URL: String = "wss://clash-of-eras-server.onrender.com"
const DEFAULT_PORT: int = 8910
const MAX_CLIENT_MESSAGE: int = 64 * 1024
const MAX_SERVER_MESSAGE: int = 4 * 1024 * 1024
const ALLOWED_OPERATIONS: Array[String] = ["choose_benefit", "ready", "reroll", "buy_item", "recruit",
	"upgrade_capacity", "place", "deploy", "bench", "swap", "equip", "unequip", "fuse", "dismiss", "next_round"]
## Prefixo de item ainda não confirmado: o servidor troca pelo item comprado naquela oferta.
const BOUGHT_PREFIX: String = "@offer:"


static func encode(message: Dictionary) -> PackedByteArray:
	var raw: PackedByteArray = var_to_bytes(message)
	var packed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var out: PackedByteArray = PackedByteArray()
	out.resize(4)
	out.encode_u32(0, raw.size())
	out.append_array(packed)
	return out


static func decode(bytes: PackedByteArray, max_size: int) -> Dictionary:
	if bytes.size() < 5 or bytes.size() > max_size:
		return {}
	var size: int = bytes.decode_u32(0)
	if size <= 0 or size > max_size:
		return {}
	var raw: PackedByteArray = bytes.slice(4).decompress(size, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != size:
		return {}
	var value: Variant = bytes_to_var(raw)
	return value if value is Dictionary else {}
