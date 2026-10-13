extends Node
## Efeitos PCM sintetizados em memória; sem downloads, músicas ou assets pagos.

const SAMPLE_RATE: int = 22050
var enabled: bool = true
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0


func _ready() -> void:
	streams = {"click": _tone(600, 0.035), "purchase": _tone(880, 0.09, 1.3),
		"start": _tone(320, 0.16, 2), "heal": _tone(660, 0.14, 1.25),
		"win": _tone(520, 0.23, 1.6), "lose": _tone(330, 0.23, 0.6)}
	for index: int in range(3):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -16.0
		add_child(player)
		voices.append(player)


func _tone(frequency: float, duration: float, end_ratio: float = 1.0) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var progress: float = float(sample) / count
		phase += TAU * lerpf(frequency, frequency * end_ratio, progress) / SAMPLE_RATE
		var envelope: float = minf(progress * 20, 1) * (1 - progress)
		data.encode_s16(sample * 2, int(sin(phase) * envelope * 12000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func play_cue(cue: String) -> void:
	if DisplayServer.get_name() == "headless" or not enabled or voices.is_empty() or not streams.has(cue):
		return
	var player: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice_index += 1
	player.stream = streams[cue]
	player.play()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		for voice: AudioStreamPlayer in voices:
			voice.stop()


func _exit_tree() -> void:
	for voice: AudioStreamPlayer in voices:
		voice.stop()
		voice.stream = null
	voices.clear()
	streams.clear()
