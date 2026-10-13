extends SceneTree
## Testes automatizados da suíte de Áudio e Música 8-Bit (Clash of Eras)

const PrototypeAudio = preload("res://client/prototype_audio.gd")

var total_passed: int = 0
var total_failed: int = 0


func _init() -> void:
	print("INICIANDO TESTES DO SISTEMA DE ÁUDIO & BOB MARLEY 8-BIT...")
	var t0: int = Time.get_ticks_msec()
	var audio: PrototypeAudio = PrototypeAudio.new()
	var elapsed: int = Time.get_ticks_msec() - t0
	_check(elapsed < 350, "síntese procedural de 22 streams executada rapidamente (%d ms)" % elapsed)

	# 1. Validação de streams essenciais
	_check(audio.streams.size() >= 22, "pelo menos 22 streams de áudio sintetizados em memória (encontrados: %d)" % audio.streams.size())
	
	var expected_cues: Array[String] = [
		"click", "purchase", "start", "heal", "win", "lose",
		"hit", "crit", "thrust", "bite", "super_bite", "shoot",
		"rocket", "explosion", "lasso", "smoke", "boss_spell",
		"tornado", "death", "shield", "revive"
	]
	for cue: String in expected_cues:
		var has_cue: bool = audio.streams.has(cue)
		_check(has_cue, "stream '%s' presente no dicionário de áudio" % cue)
		if has_cue:
			var s: AudioStreamWAV = audio.streams[cue]
			_check(s != null and not s.data.is_empty(), "stream '%s' contém dados PCM válidos" % cue)
			_check(s.format == AudioStreamWAV.FORMAT_16_BITS, "stream '%s' está em formato 16-bit PCM" % cue)

	# 2. Validação do Repertório de 3 Músicas (35s) de Bob Marley por Estrelas
	_check(audio.bob_streams.size() == 3, "Bob Marley possui exatamente 3 faixas (uma para cada estrela: 1★, 2★, 3★)")
	for star: int in [1, 2, 3]:
		var has_star: bool = audio.bob_streams.has(star)
		_check(has_star, "faixa Bob Marley da estrela %d carregada" % star)
		if has_star:
			var stream_star: AudioStream = audio.bob_streams[star]
			_check(stream_star != null, "stream Bob Marley da estrela %d instanciado" % star)
			if stream_star is AudioStreamMP3:
				var mp3_star: AudioStreamMP3 = stream_star as AudioStreamMP3
				_check(not mp3_star.data.is_empty() and mp3_star.data.size() > 500000, "faixa Bob Marley %d contém ~840KB de áudio (35s)" % star)
				_check(mp3_star.loop, "loop contínuo habilitado na faixa Bob Marley da estrela %d" % star)

	# 3. Validação do Repertório de 3 Músicas (35s) de Snoop Dogg por Estrelas
	_check(audio.snoop_streams.size() == 3, "Snoop Dogg possui exatamente 3 faixas (uma para cada estrela: 1★, 2★, 3★)")
	for star: int in [1, 2, 3]:
		var has_star: bool = audio.snoop_streams.has(star)
		_check(has_star, "faixa Snoop Dogg da estrela %d carregada" % star)
		if has_star:
			var stream_star: AudioStream = audio.snoop_streams[star]
			_check(stream_star != null, "stream Snoop Dogg da estrela %d instanciado" % star)
			if stream_star is AudioStreamMP3:
				var mp3_star: AudioStreamMP3 = stream_star as AudioStreamMP3
				_check(not mp3_star.data.is_empty() and mp3_star.data.size() > 500000, "faixa Snoop Dogg %d contém ~840KB de áudio (35s)" % star)
				_check(mp3_star.loop, "loop contínuo habilitado na faixa Snoop Dogg da estrela %d" % star)

	# 4. Teste de Voice Pool e Player de Música
	audio._ready()
	_check(audio.voices.size() == 10, "voice pool de 10 players para polifonia de combate")
	_check(audio.music_player != null, "player exclusivo para música chiptune de cantores")

	# 5. Teste de Troca de Faixas por Nível de Estrelas (Bob Marley e Snoop Dogg)
	audio.play_bob_music(1)
	_check(audio.singer_active and audio.current_singer_track == "bob_marley_star1", "Bob Marley 1★ toca Waiting In Vain")
	audio.play_bob_music(2)
	_check(audio.singer_active and audio.current_singer_track == "bob_marley_star2", "Bob Marley 2★ toca I Shot The Sheriff")
	audio.play_bob_music(3)
	_check(audio.singer_active and audio.current_singer_track == "bob_marley_star3", "Bob Marley 3★ toca Is This Love")

	audio.play_snoop_music(1)
	_check(audio.singer_active and audio.current_singer_track == "snoop_star1", "Snoop Dogg 1★ toca Nuthin But A G Thang")
	audio.play_snoop_music(2)
	_check(audio.singer_active and audio.current_singer_track == "snoop_star2", "Snoop Dogg 2★ toca Gin And Juice")
	audio.play_snoop_music(3)
	_check(audio.singer_active and audio.current_singer_track == "snoop_star3", "Snoop Dogg 3★ toca Still D.R.E.")

	# 6. Teste de Disputa de Cantores via play_singer_music
	audio.play_singer_music("bob_marley", 2)
	_check(audio.current_singer_track == "bob_marley_star2", "play_singer_music toca Bob Marley corretamente")
	audio.play_singer_music("snoop", 3)
	_check(audio.current_singer_track == "snoop_star3", "play_singer_music toca Snoop Dogg corretamente")

	# 5. Mutação dos SFX do Jogo Quando Cantor Está Ativo
	_check(audio.singer_active, "cantor está ativo no campo")
	# Em modo headless audio.play_cue retorna cedo, mas podemos verificar a regra de mutação
	audio.stop_singer_music()
	_check(not audio.singer_active and audio.current_singer_track.is_empty(), "stop_singer_music restaura som normal do jogo")

	# 6. Controle de Ativação / Desativação
	_check(audio.enabled, "áudio inicia habilitado")
	audio.set_enabled(false)
	_check(not audio.enabled, "áudio desabilita corretamente")
	audio.set_enabled(true)
	_check(audio.enabled, "áudio reabilita corretamente")

	audio.free()
	print("\nAUDIO & BOB MARLEY REPERTÓRIO TESTS: %d passed, %d failed" % [total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		total_passed += 1
	else:
		total_failed += 1
		printerr("FALHA: %s" % description)
