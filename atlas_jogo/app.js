// Clash of Eras - Atlas Visual & Mapa do Jogo

let appData = null;
let feedbacksData = {};

// Estado do Player de Animações
const playerState = {
  charKey: "barbie",
  action: "walk",
  direction: "south",
  frameIndex: 0,
  fps: 24,
  isPlaying: true,
  zoom: 2,
  bgClass: "bg-arena",
  loadedImages: [],
  lastFrameTime: 0,
  animationReqId: null
};

// Estado do Modal de Feedback Global
const modalState = {
  id: "",
  categoria: "",
  item_id: "",
  item_nome: "",
  nota: 1,
  veredito: "reprovado"
};

// Inicialização
document.addEventListener("DOMContentLoaded", async () => {
  setupTabs();
  await loadCatalog();
  await loadFeedbacks();
  initAnimationsPlayer();
  initBaseFramesView();
  initBossView();
  initMapsView();
  initVfxGallery();
  initInteractiveArena();
  setupFeedbackSystem();
  renderFeedbacksCentral();
});

// Alternância de Abas
function setupTabs() {
  const tabBtns = document.querySelectorAll(".tab-btn");
  const tabPanels = document.querySelectorAll(".tab-panel");

  tabBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      const tabId = btn.getAttribute("data-tab");
      tabBtns.forEach(b => b.classList.remove("active"));
      tabPanels.forEach(p => p.classList.remove("active"));

      btn.classList.add("active");
      const targetPanel = document.getElementById(`tab-${tabId}`);
      if (targetPanel) targetPanel.classList.add("active");

      // Redesenha canvas se necessário
      if (tabId === "mapas") {
        setTimeout(drawHexGridOverlay, 100);
      } else if (tabId === "feedbacks") {
        renderFeedbacksCentral();
      }
    });
  });
}

// Carregar Dados do Catálogo
async function loadCatalog() {
  try {
    const res = await fetch("catalogo_assets.json");
    appData = await res.json();
    console.log("Catálogo de assets carregado:", appData);
  } catch (err) {
    console.error("Erro ao carregar catalogo_assets.json:", err);
  }
}

// Carregar Feedbacks Salvos no Projeto
async function loadFeedbacks() {
  try {
    const res = await fetch("/api/feedbacks");
    if (res.ok) {
      feedbacksData = await res.json();
      console.log("Feedbacks carregados do disco:", feedbacksData);
      updateTabFeedbackCount();
    }
  } catch (err) {
    console.warn("Servidor de feedback não disponível ou sem feedbacks salvos:", err);
    feedbacksData = {};
  }
}

function updateTabFeedbackCount() {
  const count = Object.keys(feedbacksData).length;
  const countEl = document.getElementById("tab-feedback-count");
  if (countEl) countEl.textContent = count;
}

// -------------------------------------------------------------
// ABA 1: PLAYER DE MOVIMENTOS & ANIMAÇÕES
// -------------------------------------------------------------
function initAnimationsPlayer() {
  if (!appData || !appData.characters) return;

  const charListEl = document.getElementById("anim-char-list");
  charListEl.innerHTML = "";

  const charKeys = Object.keys(appData.characters);
  charKeys.forEach((key, idx) => {
    const char = appData.characters[key];
    const item = document.createElement("div");
    item.className = `char-item ${key === playerState.charKey ? "active" : ""}`;
    item.setAttribute("data-char", key);

    // Obtém avatar
    let avatarSrc = "";
    if (char.base_frames) {
      const firstVer = Object.values(char.base_frames)[0];
      if (firstVer && firstVer["south"]) avatarSrc = firstVer["south"];
    }

    item.innerHTML = `
      <div class="char-avatar">
        ${avatarSrc ? `<img src="${avatarSrc}" alt="${char.name}">` : `<span>?</span>`}
      </div>
      <div class="char-meta">
        <h4>${char.name}</h4>
        <span>${char.class}</span>
      </div>
    `;

    item.addEventListener("click", () => {
      document.querySelectorAll("#anim-char-list .char-item").forEach(i => i.classList.remove("active"));
      item.classList.add("active");
      selectCharacterForAnimation(key);
    });

    charListEl.appendChild(item);
  });

  // Configurar botões de controle
  setupPlayerControls();

  // Selecionar o primeiro personagem
  selectCharacterForAnimation(playerState.charKey);
}

function selectCharacterForAnimation(key) {
  playerState.charKey = key;
  const char = appData.characters[key];
  if (!char) return;

  document.getElementById("current-char-title").textContent = `${char.name} — Movimentos`;
  document.getElementById("current-char-origin").textContent = char.origin || "";

  // Atualizar lista de ações disponíveis
  const actionsNav = document.getElementById("action-buttons");
  actionsNav.innerHTML = "";

  const availableActions = Object.keys(char.animations || {});
  if (availableActions.length === 0) {
    actionsNav.innerHTML = `<span style="color: var(--text-muted); font-size: 13px;">Nenhuma animação disponível para este herói.</span>`;
    return;
  }

  if (!availableActions.includes(playerState.action)) {
    playerState.action = availableActions[0];
  }

  availableActions.forEach(act => {
    const btn = document.createElement("button");
    btn.className = `action-btn ${act === playerState.action ? "active" : ""}`;
    btn.textContent = getActionLabel(act);
    btn.addEventListener("click", () => {
      document.querySelectorAll("#action-buttons .action-btn").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      playerState.action = act;
      playerState.frameIndex = 0;
      loadCurrentActionFrames();
      syncInlineFeedbackPanel();
    });
    actionsNav.appendChild(btn);
  });

  loadCurrentActionFrames();
  syncInlineFeedbackPanel();
}

function getActionLabel(act) {
  const map = {
    "walk": "🚶 Passada (Walk)",
    "attack": "⚔️ Ataque (Attack)",
    "stance": "🛡️ Respiração (Stance)",
    "skill": "✨ Habilidade (Skill)",
    "death": "💀 Queda (Death)",
    "stun": "💫 Tordo (Stun)",
    "buff": "🔥 Buff (Energia)"
  };
  return map[act] || act.toUpperCase();
}

function setupPlayerControls() {
  const playPauseBtn = document.getElementById("btn-play-pause");
  const prevBtn = document.getElementById("btn-prev-frame");
  const nextBtn = document.getElementById("btn-next-frame");
  const fpsSlider = document.getElementById("fps-slider");
  const fpsVal = document.getElementById("fps-val");

  playPauseBtn.addEventListener("click", () => {
    playerState.isPlaying = !playerState.isPlaying;
    playPauseBtn.textContent = playerState.isPlaying ? "⏸️ Pausar" : "▶️ Play";
    playPauseBtn.classList.toggle("active", playerState.isPlaying);
  });

  prevBtn.addEventListener("click", () => {
    playerState.isPlaying = false;
    playPauseBtn.textContent = "▶️ Play";
    playPauseBtn.classList.remove("active");
    stepFrame(-1);
  });

  nextBtn.addEventListener("click", () => {
    playerState.isPlaying = false;
    playPauseBtn.textContent = "▶️ Play";
    playPauseBtn.classList.remove("active");
    stepFrame(1);
  });

  fpsSlider.addEventListener("input", (e) => {
    playerState.fps = parseInt(e.target.value);
    fpsVal.textContent = `${playerState.fps} FPS`;
  });

  // Bússola de Direção
  const compassBtns = document.querySelectorAll("#compass-controls .compass-btn");
  compassBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      compassBtns.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      playerState.direction = btn.getAttribute("data-dir");
      loadCurrentActionFrames();
    });
  });

  // Zoom
  document.getElementById("btn-zoom-1x").addEventListener("click", (e) => setZoom(1, e.target));
  document.getElementById("btn-zoom-2x").addEventListener("click", (e) => setZoom(2, e.target));
  document.getElementById("btn-zoom-3x").addEventListener("click", (e) => setZoom(3, e.target));

  // Background
  const bgBtns = document.querySelectorAll(".controls-bar [data-bg]");
  const viewport = document.getElementById("anim-viewport");
  bgBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      bgBtns.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      const bg = btn.getAttribute("data-bg");
      viewport.className = `viewport-box ${bg}`;
    });
  });
}

function setZoom(val, activeBtn) {
  playerState.zoom = val;
  document.querySelectorAll(".controls-bar [id^='btn-zoom-']").forEach(b => b.classList.remove("active"));
  if (activeBtn) activeBtn.classList.add("active");
  const canvas = document.getElementById("anim-canvas");
  canvas.width = 128 * val;
  canvas.height = 128 * val;
}

function stepFrame(delta) {
  if (playerState.loadedImages.length === 0) return;
  const count = playerState.loadedImages.length;
  playerState.frameIndex = (playerState.frameIndex + delta + count) % count;
  renderCurrentFrame();
  updateFilmstripHighlight();
}

function loadCurrentActionFrames() {
  const char = appData.characters[playerState.charKey];
  if (!char || !char.animations) return;

  const actData = char.animations[playerState.action];
  if (!actData || !actData.directions) return;

  let framesPaths = actData.directions[playerState.direction];
  if (!framesPaths || framesPaths.length === 0) {
    const firstDir = Object.keys(actData.directions)[0];
    framesPaths = actData.directions[firstDir] || [];
  }

  playerState.loadedImages = [];
  const filmstripEl = document.getElementById("filmstrip-frames");
  filmstripEl.innerHTML = "";

  framesPaths.forEach((path, idx) => {
    const img = new Image();
    img.src = path;
    playerState.loadedImages.push(img);

    const frameThumb = document.createElement("div");
    frameThumb.className = `filmstrip-frame ${idx === playerState.frameIndex ? "active" : ""}`;
    frameThumb.setAttribute("data-index", idx);
    frameThumb.innerHTML = `
      <img src="${path}" alt="Quadro ${idx}">
      <span class="frame-index">#${idx}</span>
    `;
    frameThumb.addEventListener("click", () => {
      playerState.isPlaying = false;
      document.getElementById("btn-play-pause").textContent = "▶️ Play";
      document.getElementById("btn-play-pause").classList.remove("active");
      playerState.frameIndex = idx;
      renderCurrentFrame();
      updateFilmstripHighlight();
    });
    filmstripEl.appendChild(frameThumb);
  });

  document.querySelectorAll("#compass-controls .compass-btn").forEach(b => {
    b.classList.toggle("active", b.getAttribute("data-dir") === playerState.direction);
  });

  if (!playerState.animationReqId) {
    playerState.lastFrameTime = performance.now();
    playerState.animationReqId = requestAnimationFrame(animationLoop);
  }
}

function animationLoop(timestamp) {
  const elapsed = timestamp - playerState.lastFrameTime;
  const frameDuration = 1000 / playerState.fps;

  if (playerState.isPlaying && elapsed >= frameDuration) {
    playerState.lastFrameTime = timestamp - (elapsed % frameDuration);
    if (playerState.loadedImages.length > 0) {
      playerState.frameIndex = (playerState.frameIndex + 1) % playerState.loadedImages.length;
      renderCurrentFrame();
      updateFilmstripHighlight();
    }
  }

  playerState.animationReqId = requestAnimationFrame(animationLoop);
}

function renderCurrentFrame() {
  const canvas = document.getElementById("anim-canvas");
  const ctx = canvas.getContext("2d");
  ctx.imageSmoothingEnabled = false;

  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const img = playerState.loadedImages[playerState.frameIndex];
  if (img && img.complete && img.naturalWidth > 0) {
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
  }
}

function updateFilmstripHighlight() {
  document.querySelectorAll("#filmstrip-frames .filmstrip-frame").forEach((el, idx) => {
    el.classList.toggle("active", idx === playerState.frameIndex);
  });
  const total = playerState.loadedImages.length;
  document.getElementById("filmstrip-info").textContent = `Quadro: ${playerState.frameIndex + 1} / ${total}`;
}

// -------------------------------------------------------------
// SISTEMA DE FEEDBACK INLINE (ABA DE ANIMAÇÕES)
// -------------------------------------------------------------
let inlineRatingValue = 1;
let inlineVerdictValue = "reprovado";

function syncInlineFeedbackPanel() {
  const char = appData.characters[playerState.charKey];
  const charName = char ? char.name : playerState.charKey;
  const actionLabel = getActionLabel(playerState.action);

  const itemId = `anim_${playerState.charKey}_${playerState.action}`;
  document.getElementById("feedback-item-title").textContent = `Avaliar esta Animação: ${charName} (${actionLabel})`;

  const existing = feedbacksData[itemId];
  const badgeEl = document.getElementById("current-eval-badge");
  const commentEl = document.getElementById("inline-feedback-comment");

  if (existing) {
    inlineRatingValue = existing.nota || 1;
    inlineVerdictValue = existing.veredito || "reprovado";
    commentEl.value = existing.comentario || "";
    badgeEl.innerHTML = `<span class="card-rating-badge ${existing.veredito}">⭐ ${existing.nota}/5 (${existing.veredito.toUpperCase()})</span>`;
  } else {
    inlineRatingValue = 1;
    inlineVerdictValue = "reprovado";
    commentEl.value = "";
    badgeEl.innerHTML = `<span style="font-size: 11px; color: var(--text-muted);">(Ainda não avaliado)</span>`;
  }

  updateInlineStarsUI(inlineRatingValue);
  updateInlineVerdictUI(inlineVerdictValue);
}

function updateInlineStarsUI(val) {
  inlineRatingValue = val;
  const stars = document.querySelectorAll("#inline-star-rating .star");
  stars.forEach((s, idx) => {
    s.classList.toggle("active", idx < val);
  });
}

function updateInlineVerdictUI(verd) {
  inlineVerdictValue = verd;
  document.querySelectorAll("#inline-verdict-group .verdict-pill").forEach(p => {
    p.classList.toggle("active", p.getAttribute("data-verdict") === verd);
  });
}

function setupFeedbackSystem() {
  // 1. Estrelas Inline
  const inlineStars = document.querySelectorAll("#inline-star-rating .star");
  inlineStars.forEach(s => {
    s.addEventListener("click", () => {
      const starVal = parseInt(s.getAttribute("data-star"));
      updateInlineStarsUI(starVal);
    });
    s.addEventListener("mouseenter", () => {
      const starVal = parseInt(s.getAttribute("data-star"));
      inlineStars.forEach((st, idx) => st.classList.toggle("hovered", idx < starVal));
    });
    s.addEventListener("mouseleave", () => {
      inlineStars.forEach(st => st.classList.remove("hovered"));
    });
  });

  // 2. Veredito Inline
  document.querySelectorAll("#inline-verdict-group .verdict-pill").forEach(pill => {
    pill.addEventListener("click", () => {
      updateInlineVerdictUI(pill.getAttribute("data-verdict"));
    });
  });

  // 3. Botão Salvar Inline
  document.getElementById("btn-save-inline-feedback").addEventListener("click", async () => {
    const char = appData.characters[playerState.charKey];
    const charName = char ? char.name : playerState.charKey;
    const actionLabel = getActionLabel(playerState.action);
    const comment = document.getElementById("inline-feedback-comment").value.trim();

    const payload = {
      id: `anim_${playerState.charKey}_${playerState.action}`,
      categoria: "Animação (16f)",
      item_id: `${playerState.charKey}_${playerState.action}`,
      item_nome: `${charName} — ${actionLabel}`,
      nota: inlineRatingValue,
      veredito: inlineVerdictValue,
      comentario: comment || "(Sem comentário adicional)"
    };

    await postFeedback(payload);
    syncInlineFeedbackPanel();
  });

  // 4. Modal Global
  setupGlobalModal();
}

// -------------------------------------------------------------
// MODAL GLOBAL DE FEEDBACK
// -------------------------------------------------------------
function setupGlobalModal() {
  const modal = document.getElementById("global-feedback-modal");
  const closeBtn = document.getElementById("btn-close-modal");
  const cancelBtn = document.getElementById("btn-cancel-modal");
  const saveBtn = document.getElementById("btn-save-modal-feedback");

  closeBtn.addEventListener("click", () => modal.classList.remove("active"));
  cancelBtn.addEventListener("click", () => modal.classList.remove("active"));

  // Estrelas do Modal
  const modalStars = document.querySelectorAll("#modal-star-rating .star");
  modalStars.forEach(s => {
    s.addEventListener("click", () => {
      modalState.nota = parseInt(s.getAttribute("data-star"));
      updateModalStarsUI(modalState.nota);
    });
    s.addEventListener("mouseenter", () => {
      const starVal = parseInt(s.getAttribute("data-star"));
      modalStars.forEach((st, idx) => st.classList.toggle("hovered", idx < starVal));
    });
    s.addEventListener("mouseleave", () => {
      modalStars.forEach(st => st.classList.remove("hovered"));
    });
  });

  // Veredito do Modal
  document.querySelectorAll("#modal-verdict-group .verdict-pill").forEach(pill => {
    pill.addEventListener("click", () => {
      modalState.veredito = pill.getAttribute("data-verdict");
      document.querySelectorAll("#modal-verdict-group .verdict-pill").forEach(p => {
        p.classList.toggle("active", p === pill);
      });
    });
  });

  // Salvar do Modal
  saveBtn.addEventListener("click", async () => {
    const comment = document.getElementById("modal-feedback-comment").value.trim();
    const payload = {
      id: modalState.id,
      categoria: modalState.categoria,
      item_id: modalState.item_id,
      item_nome: modalState.item_nome,
      nota: modalState.nota,
      veredito: modalState.veredito,
      comentario: comment || "(Sem comentário adicional)"
    };

    await postFeedback(payload);
    modal.classList.remove("active");
  });
}

function openFeedbackModal(item) {
  modalState.id = item.id;
  modalState.categoria = item.categoria;
  modalState.item_id = item.item_id;
  modalState.item_nome = item.item_nome;

  document.getElementById("modal-item-title").textContent = `Avaliar: ${item.item_nome}`;
  document.getElementById("modal-item-subtitle").textContent = item.subtitle || `Categoria: ${item.categoria}`;

  const existing = feedbacksData[item.id];
  if (existing) {
    modalState.nota = existing.nota || 1;
    modalState.veredito = existing.veredito || "reprovado";
    document.getElementById("modal-feedback-comment").value = existing.comentario || "";
  } else {
    modalState.nota = 1;
    modalState.veredito = "reprovado";
    document.getElementById("modal-feedback-comment").value = "";
  }

  updateModalStarsUI(modalState.nota);
  document.querySelectorAll("#modal-verdict-group .verdict-pill").forEach(p => {
    p.classList.toggle("active", p.getAttribute("data-verdict") === modalState.veredito);
  });

  document.getElementById("global-feedback-modal").classList.add("active");
}

function updateModalStarsUI(val) {
  document.querySelectorAll("#modal-star-rating .star").forEach((s, idx) => {
    s.classList.toggle("active", idx < val);
  });
}

async function postFeedback(payload) {
  try {
    const res = await fetch("/api/feedback", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    if (res.ok) {
      feedbacksData[payload.id] = payload;
      updateTabFeedbackCount();
      showToast(`Avaliação salva: ${payload.item_nome} (⭐ ${payload.nota}/5)`);
      renderFeedbacksCentral();
    } else {
      showToast("Erro ao gravar feedback no servidor.", true);
    }
  } catch (err) {
    console.error("Erro no postFeedback:", err);
    showToast("Erro ao conectar ao servidor local.", true);
  }
}

function showToast(text, isError = false) {
  const toast = document.getElementById("toast-notification");
  const toastText = document.getElementById("toast-text");
  toastText.textContent = text;
  toast.style.borderColor = isError ? "var(--accent-red)" : "var(--accent-green)";
  toast.classList.add("active");
  setTimeout(() => {
    toast.classList.remove("active");
  }, 3500);
}

// -------------------------------------------------------------
// ABA 2: FRAMES BASE & COMPARAÇÕES
// -------------------------------------------------------------
function initBaseFramesView() {
  if (!appData || !appData.characters) return;

  const selector = document.getElementById("base-char-selector");
  selector.innerHTML = "";

  const charKeys = Object.keys(appData.characters);
  charKeys.forEach(key => {
    const char = appData.characters[key];
    const btn = document.createElement("button");
    btn.className = `action-btn ${key === "barbie" ? "active" : ""}`;
    btn.textContent = char.name;
    btn.addEventListener("click", () => {
      document.querySelectorAll("#base-char-selector .action-btn").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      renderBaseFramesForCharacter(key);
    });
    selector.appendChild(btn);
  });

  renderBaseFramesForCharacter("barbie");
}

function renderBaseFramesForCharacter(key) {
  const char = appData.characters[key];
  if (!char) return;

  document.getElementById("base-char-name").textContent = `${char.name} — Frames Base Estáticos`;
  document.getElementById("base-char-detail").textContent = `Origem: ${char.origin} | Classe: ${char.class}`;

  const container = document.getElementById("versions-container");
  container.innerHTML = "";

  if (!char.base_frames || Object.keys(char.base_frames).length === 0) {
    container.innerHTML = `<p style="color: var(--text-muted); padding: 20px;">Nenhum frame base cadastrado para este personagem.</p>`;
    return;
  }

  const versionKeys = Object.keys(char.base_frames);
  versionKeys.forEach(verKey => {
    const verData = char.base_frames[verKey];
    const box = document.createElement("div");
    box.className = "card";
    box.style.background = "#0f1118";
    box.style.marginBottom = "20px";

    const itemId = `base_${key}_${verKey.replace(/\s+/g, '_')}`;
    const existing = feedbacksData[itemId];
    const badgeHtml = existing ? `<span class="card-rating-badge ${existing.veredito}">⭐ ${existing.nota}/5 (${existing.veredito.toUpperCase()})</span>` : "";

    box.innerHTML = `
      <div class="card-title" style="color: var(--accent-blue); font-size: 15px;">
        <div style="display: flex; align-items: center; gap: 10px;">
          <span>Versão: ${verKey}</span>
          ${badgeHtml}
        </div>
        <button class="btn-rate-quick" id="btn-rate-${itemId}">⭐ Avaliar esta Versão</button>
      </div>
      <div class="rotations-grid" id="rot-grid-${key}-${verKey.replace(/\s+/g, '-')}"></div>
    `;

    container.appendChild(box);

    box.querySelector(`#btn-rate-${itemId}`).addEventListener("click", () => {
      openFeedbackModal({
        id: itemId,
        categoria: "Frames Base / Modelo",
        item_id: `${key}_${verKey}`,
        item_nome: `${char.name} (${verKey})`,
        subtitle: `Origem: ${char.origin}`
      });
    });

    const rotGrid = box.querySelector(".rotations-grid");
    Object.keys(verData).forEach(dir => {
      const imgPath = verData[dir];
      const card = document.createElement("div");
      card.className = "rotation-card";
      card.innerHTML = `
        <div class="img-box">
          <img src="${imgPath}" alt="${dir}">
        </div>
        <span>${getDirName(dir)}</span>
      `;
      rotGrid.appendChild(card);
    });
  });
}

function getDirName(dir) {
  const map = {
    "south": "Sul (Frente)",
    "south-east": "Sudeste",
    "east": "Leste",
    "north-east": "Nordeste",
    "north": "Norte (Costas)",
    "north-west": "Noroeste",
    "west": "Oeste",
    "south-west": "Sudoeste"
  };
  return map[dir] || dir;
}

// -------------------------------------------------------------
// ABA 3: BOSS & MONSTROS
// -------------------------------------------------------------
function initBossView() {
  if (!appData || !appData.boss) return;

  // Interatividade da Nova Boss Bar de Ferro e Fogo
  const slider = document.getElementById("sim-boss-hp-slider");
  const fillClipper = document.getElementById("sim-boss-bar-fill-clipper");
  const hpText = document.getElementById("sim-boss-bar-hp-text");
  const hpVal = document.getElementById("sim-boss-hp-val");
  const rateBtn = document.getElementById("btn-rate-boss-bar");

  if (slider && fillClipper && hpText && hpVal) {
    slider.addEventListener("input", (e) => {
      const pct = parseInt(e.target.value);
      fillClipper.style.width = `${pct}%`;
      const currentHp = Math.round(pct * 100);
      hpText.textContent = `${currentHp.toLocaleString('pt-BR')} / 10.000 (${pct}%)`;
      hpVal.textContent = `${pct}% HP`;
      if (pct <= 40) {
        hpVal.style.color = "var(--accent-red)";
        hpVal.textContent = `${pct}% HP (FÚRIA!)`;
      } else {
        hpVal.style.color = "var(--text-gold)";
      }
    });
  }

  if (rateBtn) {
    rateBtn.addEventListener("click", () => {
      openFeedbackModal({
        id: "ui_boss_bar_ferro_fogo",
        categoria: "Interface / HUD de Combate",
        item_id: "boss_bar_ferro_fogo",
        item_nome: "Barra de Vida do Boss (Ferro Forjado e Fogo)",
        subtitle: "Inspirada na referência: moldura pontiaguda de ferro e preenchimento de fogo"
      });
    });
  }

  const officialGrid = document.getElementById("boss-official-grid");
  officialGrid.innerHTML = `
    <div class="boss-card highlight">
      <div class="img-box">
        <span class="boss-badge">Oficial (Idle / HUD)</span>
        <img src="../RelicArena/assets/characters/boss_dev/game_ready/idle_south.png" alt="Pose 1A Frontal">
      </div>
      <h3>Pose 1A — Frontal Oficial (Idle)</h3>
      <p>Regata preta, bermuda, chinelo e braço tatuado à mostra. Recorte 100% limpo sem sombras de chão.</p>
      <button class="btn-rate-quick" onclick="openFeedbackModal({ id: 'boss_pose_1a', categoria: 'Boss Dev', item_id: 'pose_1a', item_nome: 'Boss Dev — Pose 1A (Idle Frontal)' })">⭐ Avaliar Pose 1A</button>
    </div>

    <div class="boss-card highlight">
      <div class="img-box">
        <span class="boss-badge">Oficial (Cast Frente)</span>
        <img src="../RelicArena/assets/characters/boss_dev/game_ready/cast_south_east.png" alt="Pose 2C Cast Leste">
      </div>
      <h3>Pose 2C — Conjuração de Frente (Cast)</h3>
      <p>Apontando para a frente/direita com braço musculoso esticado para conjurar Fogo Vermelho e Fogo Roxo.</p>
      <button class="btn-rate-quick" onclick="openFeedbackModal({ id: 'boss_pose_2c', categoria: 'Boss Dev', item_id: 'pose_2c', item_nome: 'Boss Dev — Pose 2C (Cast Frente)' })">⭐ Avaliar Pose 2C</button>
    </div>

    <div class="boss-card highlight">
      <div class="img-box">
        <span class="boss-badge">Oficial (Cast Costas)</span>
        <img src="../RelicArena/assets/characters/boss_dev/game_ready/cast_north.png" alt="Pose Costas Norte">
      </div>
      <h3>Pose Costas Norte — Conjuração para Cima</h3>
      <p>Disparada quando o Boss se teletransporta para a parte inferior da arena e mira nos heróis para cima.</p>
      <button class="btn-rate-quick" onclick="openFeedbackModal({ id: 'boss_pose_costas', categoria: 'Boss Dev', item_id: 'pose_costas_norte', item_nome: 'Boss Dev — Pose Costas Norte' })">⭐ Avaliar Pose Costas</button>
    </div>
  `;

  // Mobs
  const mobsGrid = document.getElementById("mobs-grid");
  mobsGrid.innerHTML = "";
  const mobs = appData.boss.mobs || {};
  Object.keys(mobs).forEach(k => {
    const mob = mobs[k];
    const card = document.createElement("div");
    card.className = "boss-card";
    const itemId = `mob_${k}`;
    card.innerHTML = `
      <div class="img-box">
        <img src="${mob.file}" alt="${mob.name}">
      </div>
      <h3>${mob.name}</h3>
      <p>Lacaio sombrio invocado no fundo da arena (fileiras 6 e 7) com provocação (aggro/taunt).</p>
      <button class="btn-rate-quick" onclick="openFeedbackModal({ id: '${itemId}', categoria: 'Monstros / Mobs', item_id: '${k}', item_nome: '${mob.name}' })">⭐ Avaliar este Monstro</button>
    `;
    mobsGrid.appendChild(card);
  });

  // VFX do Boss
  const bossVfxGrid = document.getElementById("boss-vfx-grid");
  bossVfxGrid.innerHTML = "";
  const vfxBoss = appData.boss.vfx || {};
  Object.keys(vfxBoss).forEach(k => {
    const frames = vfxBoss[k];
    const card = document.createElement("div");
    card.className = "vfx-card";
    const itemId = `boss_vfx_${k}`;
    card.innerHTML = `
      <div class="anim-box">
        <img src="${frames[0]}" style="max-height: 90px; image-rendering: pixelated;">
      </div>
      <h4>${k.replace(/_/g, ' ').toUpperCase()}</h4>
      <button class="btn-rate-quick" onclick="openFeedbackModal({ id: '${itemId}', categoria: 'Magias do Boss', item_id: '${k}', item_nome: '${k.replace(/_/g, ' ').toUpperCase()}' })">⭐ Avaliar Magia</button>
    `;
    bossVfxGrid.appendChild(card);
  });
}

// -------------------------------------------------------------
// ABA 4: MAPAS & ARENAS
// -------------------------------------------------------------
function initMapsView() {
  const toggle = document.getElementById("toggle-hex-grid");
  const canvas = document.getElementById("hex-canvas");

  toggle.addEventListener("change", () => {
    canvas.style.display = toggle.checked ? "block" : "none";
  });

  const mapImg = document.getElementById("main-map-img");
  mapImg.onload = () => {
    drawHexGridOverlay();
  };
}

function drawHexGridOverlay() {
  const mapImg = document.getElementById("main-map-img");
  const canvas = document.getElementById("hex-canvas");
  if (!mapImg || !canvas) return;

  canvas.width = mapImg.clientWidth || 1000;
  canvas.height = mapImg.clientHeight || 560;

  const ctx = canvas.getContext("2d");
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  ctx.strokeStyle = "rgba(197, 160, 89, 0.45)";
  ctx.lineWidth = 1.5;

  const rows = 8;
  const cols = 8;
  const startX = canvas.width * 0.16;
  const startY = canvas.height * 0.22;
  const hexW = (canvas.width * 0.68) / cols;
  const hexH = (canvas.height * 0.58) / rows;

  for (let r = 0; r < rows; r++) {
    const isEnemy = r < 4;
    ctx.strokeStyle = isEnemy ? "rgba(230, 57, 70, 0.4)" : "rgba(0, 180, 216, 0.4)";

    for (let c = 0; c < cols; c++) {
      const offsetX = (r % 2 === 1) ? hexW * 0.5 : 0;
      const cx = startX + c * hexW + offsetX;
      const cy = startY + r * hexH;

      ctx.beginPath();
      ctx.ellipse(cx, cy, hexW * 0.42, hexH * 0.38, 0, 0, Math.PI * 2);
      ctx.stroke();
    }
  }
}

// -------------------------------------------------------------
// ABA 5: SKILLS & EFEITOS VISUAIS (VFX)
// -------------------------------------------------------------
function initVfxGallery() {
  if (!appData || !appData.vfx) return;

  const gallery = document.getElementById("vfx-gallery-grid");
  gallery.innerHTML = "";

  const vfxKeys = Object.keys(appData.vfx);
  vfxKeys.forEach(k => {
    const vfx = appData.vfx[k];
    const card = document.createElement("div");
    card.className = "vfx-card";
    const itemId = `vfx_${k}`;

    if (vfx.sheet) {
      const canvasId = `vfx-canvas-${k}`;
      card.innerHTML = `
        <div class="anim-box">
          <canvas id="${canvasId}" width="96" height="96" class="pixel-canvas"></canvas>
        </div>
        <h4>${vfx.name}</h4>
        <button class="btn-rate-quick" onclick="openFeedbackModal({ id: '${itemId}', categoria: 'Efeitos Visuais (Skills)', item_id: '${k}', item_nome: '${vfx.name}' })">⭐ Avaliar este Efeito</button>
      `;
      gallery.appendChild(card);
      startSpriteSheetLoop(canvasId, vfx.sheet, vfx.frames_count || 12, vfx.frame_width || 96, vfx.frame_height || 96, vfx.fps || 16);
    } else if (vfx.file) {
      card.innerHTML = `
        <div class="anim-box">
          <img src="${vfx.file}" style="max-height: 80px; image-rendering: pixelated;">
        </div>
        <h4>${vfx.name}</h4>
        <button class="btn-rate-quick" onclick="openFeedbackModal({ id: '${itemId}', categoria: 'Efeitos Visuais (VFX)', item_id: '${k}', item_nome: '${vfx.name}' })">⭐ Avaliar este Efeito</button>
      `;
      gallery.appendChild(card);
    }
  });
}

function startSpriteSheetLoop(canvasId, sheetSrc, frameCount, frameW, frameH, fps) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  ctx.imageSmoothingEnabled = false;

  const img = new Image();
  img.src = sheetSrc;
  let currentFrame = 0;
  let lastTime = performance.now();

  function loop(time) {
    if (time - lastTime >= 1000 / fps) {
      lastTime = time;
      currentFrame = (currentFrame + 1) % frameCount;
      if (img.complete && img.naturalWidth > 0) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const cols = Math.floor(img.naturalWidth / frameW) || 1;
        const col = currentFrame % cols;
        const row = Math.floor(currentFrame / cols);
        ctx.drawImage(img, col * frameW, row * frameH, frameW, frameH, 0, 0, canvas.width, canvas.height);
      }
    }
    requestAnimationFrame(loop);
  }

  img.onload = () => {
    requestAnimationFrame(loop);
  };
}

// -------------------------------------------------------------
// ABA 6: ARENA DO JOGO (MAPA INTERATIVO)
// -------------------------------------------------------------
function initInteractiveArena() {
  if (!appData || !appData.characters) return;

  const picker = document.getElementById("arena-char-picker");
  picker.innerHTML = "";

  let selectedChar = "barbie";

  Object.keys(appData.characters).forEach(key => {
    const char = appData.characters[key];
    const btn = document.createElement("button");
    btn.className = `action-btn ${key === selectedChar ? "active" : ""}`;
    btn.textContent = char.name;
    btn.addEventListener("click", () => {
      document.querySelectorAll("#arena-char-picker .action-btn").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      selectedChar = key;
    });
    picker.appendChild(btn);
  });

  const gridContainer = document.getElementById("interactive-grid-cells");
  gridContainer.innerHTML = "";

  for (let r = 0; r < 8; r++) {
    const rowEl = document.createElement("div");
    rowEl.className = "interactive-row";

    for (let c = 0; c < 8; c++) {
      const cell = document.createElement("div");
      cell.className = "hex-cell";
      cell.setAttribute("data-row", r);
      cell.setAttribute("data-col", c);

      cell.addEventListener("click", () => {
        placeHeroOnHex(cell, selectedChar);
      });

      rowEl.appendChild(cell);
    }
    gridContainer.appendChild(rowEl);
  }

  setTimeout(() => {
    const centerPlayerCell = document.querySelector(".hex-cell[data-row='5'][data-col='3']");
    if (centerPlayerCell) placeHeroOnHex(centerPlayerCell, "barbie");

    const centerPlayerCell2 = document.querySelector(".hex-cell[data-row='5'][data-col='4']");
    if (centerPlayerCell2) placeHeroOnHex(centerPlayerCell2, "ken");

    const bossCell = document.querySelector(".hex-cell[data-row='1'][data-col='4']");
    if (bossCell) placeHeroOnHex(bossCell, "boss_dev");
  }, 200);
}

function placeHeroOnHex(cell, charKey) {
  const char = appData.characters[charKey];
  if (!char) return;

  let imgSrc = "";
  if (char.base_frames) {
    const firstVer = Object.values(char.base_frames)[0];
    if (firstVer && firstVer["south"]) imgSrc = firstVer["south"];
  }

  if (imgSrc) {
    cell.innerHTML = `<img src="${imgSrc}" alt="${char.name}" title="${char.name} (${char.class})">`;
  }
}

// -------------------------------------------------------------
// ABA 7: CENTRAL CONSOLIDADA DE NOTAS & FEEDBACKS
// -------------------------------------------------------------
function renderFeedbacksCentral() {
  const items = Object.values(feedbacksData);
  const total = items.length;

  let reprovados = 0;
  let ajustes = 0;
  let aprovados = 0;
  let sumNotas = 0;

  items.forEach(it => {
    if (it.veredito === "reprovado") reprovados++;
    else if (it.veredito === "ajustar") ajustes++;
    else if (it.veredito === "aprovado") aprovados++;
    sumNotas += (it.nota || 0);
  });

  const media = total > 0 ? (sumNotas / total).toFixed(1) : "0.0";

  document.getElementById("metric-total").textContent = total;
  document.getElementById("metric-reprovados").textContent = reprovados;
  document.getElementById("metric-ajustes").textContent = ajustes;
  document.getElementById("metric-aprovados").textContent = aprovados;
  document.getElementById("metric-media").textContent = `${media} ★`;

  const tbody = document.getElementById("feedbacks-table-body");
  if (total === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" style="text-align: center; color: var(--text-muted); padding: 30px;">
          Nenhuma avaliação registrada ainda. Navegue pelas abas e avalie os heróis, movimentos e mapas!
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = "";
  items.sort((a, b) => (b.timestamp || "").localeCompare(a.timestamp || "")).forEach(it => {
    const tr = document.createElement("tr");

    let verdictClass = it.veredito || "reprovado";
    let verdictLabel = "🔴 Refazer";
    if (verdictClass === "ajustar") verdictLabel = "🟡 Ajustar";
    else if (verdictClass === "aprovado") verdictLabel = "🟢 Aprovado";

    tr.innerHTML = `
      <td><strong>${it.item_nome || it.item_id}</strong></td>
      <td><span style="color: var(--text-muted);">${it.categoria || "Geral"}</span></td>
      <td><strong style="color: #fbbf24;">${it.nota} ★</strong></td>
      <td><span class="card-rating-badge ${verdictClass}">${verdictLabel}</span></td>
      <td>${it.comentario || "-"}</td>
      <td style="color: var(--text-muted); font-size: 11px;">${it.timestamp || "-"}</td>
      <td>
        <button class="btn-ctrl" style="padding: 4px 8px; font-size: 11px; color: var(--accent-red);" onclick="deleteFeedback('${it.id}')">Excluir</button>
      </td>
    `;
    tbody.appendChild(tr);
  });

  // Botões de ação da tabela
  document.getElementById("btn-copy-feedbacks-summary").onclick = copyFeedbacksSummary;
  document.getElementById("btn-clear-feedbacks").onclick = clearAllFeedbacks;
}

async function deleteFeedback(id) {
  if (!confirm(`Deseja remover a avaliação do item ${id}?`)) return;
  try {
    const res = await fetch(`/api/feedback?id=${encodeURIComponent(id)}`, { method: "DELETE" });
    if (res.ok) {
      delete feedbacksData[id];
      updateTabFeedbackCount();
      renderFeedbacksCentral();
      showToast("Avaliação removida.");
    }
  } catch (err) {
    console.error("Erro ao deletar feedback:", err);
  }
}

async function clearAllFeedbacks() {
  if (!confirm("Tem certeza que deseja apagar todos os feedbacks registrados?")) return;
  const ids = Object.keys(feedbacksData);
  for (const id of ids) {
    await fetch(`/api/feedback?id=${encodeURIComponent(id)}`, { method: "DELETE" });
  }
  feedbacksData = {};
  updateTabFeedbackCount();
  renderFeedbacksCentral();
  showToast("Todos os feedbacks foram limpos.");
}

function copyFeedbacksSummary() {
  const items = Object.values(feedbacksData);
  if (items.length === 0) {
    showToast("Nenhum feedback para copiar.", true);
    return;
  }

  let text = "### 📋 Resumo das Avaliações e Feedbacks do Usuário:\n\n";
  items.forEach(it => {
    text += `- **${it.item_nome}** (${it.categoria}): Nota ${it.nota}/5 [${it.veredito.toUpperCase()}]\n`;
    text += `  *Comentário:* ${it.comentario}\n\n`;
  });

  navigator.clipboard.writeText(text).then(() => {
    showToast("Resumo copiado para a área de transferência! Pode colar no chat.");
  }).catch(() => {
    alert("Resumo gerado:\n\n" + text);
  });
}
