extends Node
## Efeitos sonoros de batalha e single 8-bit PCM sintetizados em memória.
## Sem downloads, sem custos, sem dependências externas; 100% retro arcade em GDScript.

const SAMPLE_RATE: int = 22050
var enabled: bool = true
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0
var music_player: AudioStreamPlayer
var bob_streams: Dictionary = {} # 1: Star1, 2: Star2, 3: Star3
var snoop_streams: Dictionary = {} # 1: Star1, 2: Star2, 3: Star3
var current_singer_track: String = ""
var singer_active: bool = false

var last_cue_times: Dictionary = {}
const CUE_COOLDOWNS: Dictionary = {
	"hit": 40,
	"thrust": 45,
	"bite": 45,
	"shoot": 50,
	"rocket": 60,
	"explosion": 80,
	"crit": 60,
	"death": 80,
	"heal": 150,
	"shield": 100,
	"lasso": 120,
	"smoke": 150,
	"boss_spell": 100,
	"tornado": 120,
	"revive": 200
}


func _init() -> void:
	_init_streams()


func _ready() -> void:
	# Voice pool para polifonia de combate sem cortes abruptos
	for index: int in range(10):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = -14.0
		add_child(player)
		voices.append(player)
	# Player exclusivo para a música dos cantores (Bob Marley, etc.)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -8.0
	add_child(music_player)


func _init_streams() -> void:
	# UI & Economia existentes
	streams["click"] = _tone(600, 0.035)
	streams["purchase"] = _tone(880, 0.09, 1.3)
	streams["start"] = _tone(320, 0.16, 2.0)
	streams["heal"] = _tone(660, 0.14, 1.25)
	streams["win"] = _tone(520, 0.23, 1.6)
	streams["lose"] = _tone(330, 0.23, 0.6)

	# Sons de Combate (Arcade 8-bit / Chiptune)
	streams["hit"] = _hit(260.0, 70.0, 0.075, 0.25)
	streams["crit"] = _crit(0.14)
	streams["thrust"] = _thrust(0.09)
	streams["bite"] = _bite(0.08, false)
	streams["super_bite"] = _bite(0.22, true)
	streams["shoot"] = _shoot(0.08)
	streams["rocket"] = _rocket(0.11)
	streams["explosion"] = _explosion(0.32, false)
	streams["lasso"] = _lasso(0.16)
	streams["smoke"] = _smoke(0.24)
	streams["boss_spell"] = _boss_spell(0.26)
	streams["tornado"] = _tornado(0.36)
	streams["death"] = _death(0.20)
	streams["shield"] = _shield(0.15)
	streams["revive"] = _revive(0.28)

	# Repertório das 3 Músicas de Bob Marley por Estrela (35 segundos cada)
	_load_bob_tracks()
	# Repertório das 3 Músicas de Snoop Dogg por Estrela (35 segundos cada)
	_load_snoop_tracks()


func _tone(frequency: float, duration: float, end_ratio: float = 1.0) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var progress: float = float(sample) / count
		phase += TAU * lerpf(frequency, frequency * end_ratio, progress) / SAMPLE_RATE
		var envelope: float = minf(progress * 20.0, 1.0) * (1.0 - progress)
		data.encode_s16(sample * 2, int(sin(phase) * envelope * 12000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _hit(start_freq: float, end_freq: float, duration: float, noise_mix: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(start_freq, end_freq, prog * prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = (1.0 - prog) * (1.0 - prog)
		var tone: float = sin(phase)
		var noise: float = randf_range(-1.0, 1.0) * maxf(0.0, 1.0 - prog * 4.0)
		var combined: float = (tone * (1.0 - noise_mix) + noise * noise_mix) * env
		data.encode_s16(sample * 2, clampi(int(combined * 16000.0), -32000, 32000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _crit(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(360.0, 45.0, prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = (1.0 - prog)
		# Pulse wave 25% + sub-bass + estalo metálico inicial
		var pulse: float = 1.0 if fmod(phase, TAU) < TAU * 0.25 else -1.0
		var sub: float = sin(phase * 0.5)
		var crack: float = (randf_range(-1.0, 1.0) * 1.5) * maxf(0.0, 1.0 - prog * 6.0)
		var combined: float = (pulse * 0.4 + sub * 0.4 + crack * 0.5) * env
		data.encode_s16(sample * 2, clampi(int(combined * 20000.0), -32000, 32000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _thrust(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(880.0, 160.0, prog * prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = minf(prog * 15.0, 1.0) * (1.0 - prog)
		var square: float = 1.0 if fmod(phase, TAU) < TAU * 0.5 else -1.0
		var whoosh: float = randf_range(-1.0, 1.0) * (0.6 - prog * 0.5)
		var combined: float = (square * 0.45 + whoosh * 0.55) * env
		data.encode_s16(sample * 2, clampi(int(combined * 15000.0), -32000, 32000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _bite(duration: float, is_super: bool) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(680.0 if not is_super else 480.0, 90.0, prog * prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = (1.0 - prog)
		var click: float = 1.0 if fmod(phase, TAU) < TAU * 0.15 else -1.0
		var crunch: float = randf_range(-1.0, 1.0) * 0.7
		if is_super and prog > 0.4:
			crunch *= 1.4
		var combined: float = (click * 0.4 + crunch * 0.6) * env
		data.encode_s16(sample * 2, clampi(int(combined * (22000.0 if is_super else 16000.0)), -32000, 32000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _shoot(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(1050.0, 220.0, prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = 1.0 - prog
		var square: float = 1.0 if fmod(phase, TAU) < TAU * 0.25 else -1.0
		data.encode_s16(sample * 2, int(square * env * 14000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _rocket(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(240.0, 850.0, prog * prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = minf(prog * 10.0, 1.0) * (1.0 - prog * 0.6)
		var thruster: float = randf_range(-1.0, 1.0) * 0.4
		var tone: float = sin(phase) * 0.6
		data.encode_s16(sample * 2, int((tone + thruster) * env * 14000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _explosion(duration: float, _is_heavy: bool) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var lp: float = 0.0
	var phase_sub: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var env: float = (1.0 - prog) * (1.0 - prog)
		var raw_noise: float = randf_range(-1.0, 1.0)
		lp += (raw_noise - lp) * lerpf(0.35, 0.06, prog)
		phase_sub += TAU * lerpf(65.0, 30.0, prog) / SAMPLE_RATE
		var sub: float = sin(phase_sub) * 0.5
		var blast: float = (lp * 0.7 + sub * 0.5) * env
		data.encode_s16(sample * 2, clampi(int(blast * 24000.0), -31000, 31000))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _lasso(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(360.0, 1100.0, prog * 1.5) if prog < 0.7 else lerpf(1100.0, 220.0, (prog - 0.7) / 0.3)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = (1.0 - prog * 0.8)
		var tri: float = 4.0 * absf(fmod(phase / TAU, 1.0) - 0.5) - 1.0
		data.encode_s16(sample * 2, int(tri * env * 15000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _smoke(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var lp: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var env: float = sin(prog * PI)
		var raw: float = randf_range(-1.0, 1.0)
		lp += (raw - lp) * 0.12
		data.encode_s16(sample * 2, int(lp * env * 12000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _boss_spell(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var chords: Array = [622.25, 493.88, 415.30, 329.63]
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var note_idx: int = clampi(int(prog * chords.size()), 0, chords.size() - 1)
		var cur_freq: float = chords[note_idx]
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = (1.0 - prog)
		var square: float = 1.0 if fmod(phase, TAU) < TAU * 0.25 else -1.0
		data.encode_s16(sample * 2, int(square * env * 14000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _tornado(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var lp: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var env: float = sin(prog * PI)
		var sweep: float = 0.08 + 0.07 * sin(prog * TAU * 3.5)
		var raw: float = randf_range(-1.0, 1.0)
		lp += (raw - lp) * sweep
		data.encode_s16(sample * 2, int(lp * env * 16000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _death(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var vib: float = sin(prog * TAU * 12.0) * 0.08
		var cur_freq: float = lerpf(440.0, 95.0, prog) * (1.0 + vib)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = 1.0 - prog
		var square: float = 1.0 if fmod(phase, TAU) < TAU * 0.5 else -1.0
		data.encode_s16(sample * 2, int(square * env * 13000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _shield(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var cur_freq: float = lerpf(260.0, 580.0, prog)
		phase += TAU * cur_freq / SAMPLE_RATE
		var env: float = minf(prog * 12.0, 1.0) * (1.0 - prog * 0.7)
		var tri: float = 4.0 * absf(fmod(phase / TAU, 1.0) - 0.5) - 1.0
		data.encode_s16(sample * 2, int(tri * env * 14000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _revive(duration: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var notes: Array = [261.63, 329.63, 392.00, 523.25]
	var phase: float = 0.0
	for sample: int in range(count):
		var prog: float = float(sample) / count
		var note_idx: int = clampi(int(prog * notes.size()), 0, notes.size() - 1)
		phase += TAU * notes[note_idx] / SAMPLE_RATE
		var env: float = (1.0 - fmod(prog * notes.size(), 1.0)) * 0.8 + 0.2
		var square: float = 1.0 if fmod(phase, TAU) < TAU * 0.25 else -1.0
		data.encode_s16(sample * 2, int(square * env * 14000.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream


func _load_bob_tracks() -> void:
	for star: int in [1, 2, 3]:
		var path_mp3: String = "res://assets/audio/bob_marley_star%d.mp3" % star
		var stream: AudioStreamMP3 = _load_looping_track(path_mp3)
		if stream != null:
			bob_streams[star] = stream
			streams["bob_marley_star%d" % star] = stream
	if bob_streams.has(1):
		streams["bob_marley_8bit"] = bob_streams[1]


func _load_snoop_tracks() -> void:
	for star: int in [1, 2, 3]:
		var path_mp3: String = "res://assets/audio/snoop_star%d.mp3" % star
		var stream: AudioStreamMP3 = _load_looping_track(path_mp3)
		if stream != null:
			snoop_streams[star] = stream
			streams["snoop_star%d" % star] = stream


func _load_looping_track(path: String) -> AudioStreamMP3:
	# ResourceLoader follows export remaps; the raw MP3 need not be in the PCK.
	if not ResourceLoader.exists(path):
		return null
	var imported: AudioStreamMP3 = load(path) as AudioStreamMP3
	if imported == null:
		return null
	var stream: AudioStreamMP3 = imported.duplicate() as AudioStreamMP3
	stream.loop = true
	return stream


func play_cue(cue: String) -> void:
	if DisplayServer.get_name() == "headless" or not enabled or voices.is_empty() or not streams.has(cue):
		return
	# O som do jogo fica mutado quando tem algum cantor ativo na partida
	if singer_active and cue not in ["win", "lose", "click", "purchase"]:
		return
	var now: int = Time.get_ticks_msec()
	var cd: int = int(CUE_COOLDOWNS.get(cue, 25))
	if now - int(last_cue_times.get(cue, 0)) < cd:
		return
	last_cue_times[cue] = now
	var player: AudioStreamPlayer = voices[voice_index % voices.size()]
	voice_index += 1
	player.stream = streams[cue]
	player.play()


func play_bob_music(star_level: int = 1) -> void:
	var lvl: int = clampi(star_level, 1, 3)
	var track_key: String = "bob_marley_star%d" % lvl
	_play_singer_track(track_key)


func play_snoop_music(star_level: int = 1) -> void:
	var lvl: int = clampi(star_level, 1, 3)
	var track_key: String = "snoop_star%d" % lvl
	_play_singer_track(track_key)


func play_singer_music(singer_key: String, star_level: int = 1) -> void:
	if singer_key == "bob_marley":
		play_bob_music(star_level)
		return
	elif singer_key == "snoop":
		play_snoop_music(star_level)
		return
	var lvl: int = clampi(star_level, 1, 3)
	var track_key: String = "%s_star%d" % [singer_key, lvl]
	_play_singer_track(track_key)


func _play_singer_track(track_key: String) -> void:
	# A singer without a loaded track must not mute the battle's sound effects.
	if not enabled or not streams.has(track_key):
		stop_singer_music()
		return
	if current_singer_track == track_key and singer_active and is_instance_valid(music_player) and music_player.playing:
		return
	current_singer_track = track_key
	singer_active = true
	if DisplayServer.get_name() == "headless":
		return
	if is_instance_valid(music_player):
		music_player.stream = streams[track_key]
		music_player.volume_db = -8.0
		music_player.play()


func stop_singer_music() -> void:
	singer_active = false
	current_singer_track = ""
	if is_instance_valid(music_player):
		music_player.stop()


func stop_bob_music() -> void:
	stop_singer_music()


func stop_snoop_music() -> void:
	stop_singer_music()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		for voice: AudioStreamPlayer in voices:
			voice.stop()
		stop_singer_music()


func _exit_tree() -> void:
	for voice: AudioStreamPlayer in voices:
		voice.stop()
		voice.stream = null
	voices.clear()
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	singer_active = false
	current_singer_track = ""
	bob_streams.clear()
	snoop_streams.clear()
	streams.clear()
	last_cue_times.clear()
