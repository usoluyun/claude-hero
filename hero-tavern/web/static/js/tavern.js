// Hero Tavern — Main JavaScript
// Pixel sprite rendering + API interaction

// Color legend for pixel patterns:
// . = transparent, s = skin, r = red, g = gold, b = blue, k = black, w = white,
// p = purple, n = brown, y = yellow, c = cyan, e = green, l = silver, d = darkred,
// u = darkblue, f = darkgreen, o = orange, a = gray

const COLOR_MAP = {
  '.': '', 's': 'skin', 'r': 'red', 'g': 'gold', 'b': 'blue', 'k': 'black',
  'w': 'white', 'p': 'purple', 'n': 'brown', 'y': 'yellow', 'c': 'cyan',
  'e': 'green', 'l': 'silver', 'd': 'darkred', 'u': 'darkblue', 'f': 'darkgreen',
  'o': 'orange', 'a': 'gray'
};

// Simplified 16x16 patterns for each character (iconic features only)
const SPRITES = {
  'nick-fury': [
    '................',
    '................',
    '.....kkkkkk.....',
    '....kssssksk....',
    '...ksskskssk....',
    '...ksssksssk....',
    '...ksssssssk....',
    '....kssssssk....',
    '.....kkkkkk.....',
    '....kkkkkkkk....',
    '...kkkkkkkkkk...',
    '...kkkllllkkk...',
    '...kkkkkkkkkk...',
    '....kk....kk....',
    '....kk....kk....',
    '................',
  ],
  'iron-man': [
    '................',
    '.....rrrrrr.....',
    '....rrrrrrrr....',
    '...rrccccccrr...',
    '...rcccccccr....',
    '...rccrrrrcr....',
    '...rcccccccr....',
    '....rrggggrr....',
    '.....rrrrrr.....',
    '....rggrrggr....',
    '...rrrrrrrrrr...',
    '...rrggrrggrr...',
    '...rrrrrrrrrr...',
    '....rr....rr....',
    '....rr....rr....',
    '................',
  ],
  'vision': [
    '................',
    '....eeeeeeg.....',
    '...eeeyeyeee....',
    '...eeeeeeeee....',
    '...eesssssee....',
    '...essssssse....',
    '...essssssse....',
    '....sssssss.....',
    '.....sssss......',
    '....ppeeeee.....',
    '...ppeeeeeepp...',
    '...ppeeeeeepp...',
    '...pppeeeeppp...',
    '....pp....pp....',
    '....pp....pp....',
    '................',
  ],
  'spider-man': [
    '................',
    '.....rrrrrr.....',
    '....rrrrrrrr....',
    '...rrkwwkwwrr...',
    '...rrkwwkwwrr...',
    '...rrrrrrrrrr...',
    '...rrrrkrrrrr...',
    '....rrrrrrrr....',
    '.....rrrrrr.....',
    '....bbbrrrrb....',
    '...bbbrrrrbbb...',
    '...bbbrrrrbbb...',
    '...bbbrrrrbbb...',
    '....bb....bb....',
    '....rr....rr....',
    '................',
  ],
  'doctor-strange': [
    '................',
    '....kkkkkkk.....',
    '...kkkkkkkkkk...',
    '...kkssskkssk...',
    '...kssskssssk...',
    '...kssssssssk...',
    '....ssssssss....',
    '.....ssssss.....',
    '....ddrrrrdd....',
    '...dddrrrrddd...',
    '...dddddddddd...',
    '...ddyyyyydd....',
    '...dddddddddd...',
    '....dd....dd....',
    '....dd....dd....',
    '................',
  ],
  'heimdall': [
    '................',
    '....gggggggg....',
    '...gggggggggg...',
    '...ggllggllgg...',
    '...ggllggllgg...',
    '...ggssssssgg...',
    '...gsssssssg....',
    '....sssssss.....',
    '.....ggggg......',
    '....gggggggg....',
    '...gggggggggg...',
    '...gggggggggg...',
    '...ggggggggg....',
    '....gg....gg....',
    '....gg....gg....',
    '...........l....',
  ],
  'rocket': [
    '................',
    '.....nnnnnn.....',
    '....nnnnnnnn....',
    '...nnkknnkkn....',
    '...nnkknnkkn....',
    '...nnnnnnnnn....',
    '...nnnkkknnn....',
    '....nnnnnnnn....',
    '..ll.nnnnnn.....',
    '.lll.nnnnnn.....',
    'lllllkkkkkk.....',
    '.lll.kkkkkk.....',
    '..ll..kkkk......',
    '.....nn..nn.....',
    '.....nn..nn.....',
    '................',
  ],
  'star-lord': [
    '................',
    '....nnnnnnnn....',
    '...nnnnnnnnnn...',
    '...nnggnnggnn...',
    '...nnggnnggnn...',
    '...nnssssnnn....',
    '...nsssssssn....',
    '....ssssssss....',
    '.....sssss......',
    '....rrnrrrr.....',
    '...rrrrrrrrrr...',
    '...rrgggrrrrr...',
    '...rrrrrrrrrr...',
    '....rr....rr....',
    '....rr....rr....',
    '................',
  ],
  'falcon': [
    '................',
    '..aa....aa......',
    '.aaaa..aaaa.....',
    '..aa..aaaa......',
    '......aa........',
    '....aaaaaaa.....',
    '...aakkkkkaaa...',
    '...aksskssak....',
    '...aksskssak....',
    '...akssssak.....',
    '....ssssss......',
    '...aaaaaaaaaa...',
    '...aaaaaaaaaa...',
    '....aa....aa....',
    '....aa....aa....',
    '................',
  ],
  'prometheus': [
    '.......oo.......',
    '......oooo......',
    '.....oooooo.....',
    '....oyyyyoo.....',
    '...kkkkkkkk.....',
    '...kssssskk.....',
    '...kssskssk.....',
    '...ksssssk......',
    '....sssss.......',
    '...kkkkkkkk.....',
    '...kkkkkkkkkk...',
    '...kkllllkkk....',
    '...kkkkkkkkkk...',
    '....kk....kk....',
    '....kk....kk....',
    '...kk......kk...',
  ],
  'atlas': [
    '....bbbbbbb.....',
    '...bbblllbbbb...',
    '..bbblllllbbb...',
    '...bbbbbbbbb....',
    '................',
    '....sssssss.....',
    '...sskkkssk.....',
    '...sskksksk.....',
    '...ssssssss.....',
    '....sssssss.....',
    '...kkkkkkkkkk...',
    '...kkkkkkkkkk...',
    '...kkkkkkkkk....',
    '....kk....kk....',
    '....kk....kk....',
    '................',
  ],
  'hephaestus': [
    '................',
    '................',
    '....ooo.........',
    '...onno.........',
    '...kkkkkkkk.....',
    '...ksssskks.....',
    '...ksksksks.....',
    '...kssssssk.....',
    '....sssssss.....',
    '...kkkkkkkkkk...',
    '...kkkkkkkkk....',
    '...kkkkkkkkkk...',
    '...kkkkkkkkk....',
    '....kk....kk....',
    '....kk....kk....',
    '......aaaaaa....',
  ],
  'hercules': [
    '................',
    '....nnnnnnn.....',
    '...nnnnnnnnnn...',
    '...nsssskssn....',
    '...sssskksss....',
    '...ssssssssss...',
    '....ssssssss....',
    '.....sssss......',
    '....gggggggg....',
    '...gggggggggg...',
    '...gggggggggg...',
    '...gggggggggg...',
    '...ggggggggg....',
    '....gg....gg....',
    '....gg....gg....',
    '................',
  ],
  'artemis': [
    '................',
    '....eeeeeee.....',
    '...eeeeeeeeee...',
    '...eessskssse...',
    '...esssksssse...',
    '...esssssssse...',
    '....sssssssss...',
    '.....ssssss.....',
    '....eeeeeeee....',
    '...eeeeeeeeee...',
    '...eeeeeeeeee...',
    '....eeeeeeeee...',
    '...nnn....nnn...',
    '....nn....nn....',
    '....ee....ee....',
    '................',
  ],
  'apollo': [
    '................',
    '....yyyyyyy.....',
    '...yyyyyyyyyy...',
    '...yysssksss....',
    '...yssskskss....',
    '...yssssssss....',
    '....ssssssss....',
    '.....sssss......',
    '....kkggkk......',
    '...kkgggkk......',
    '...kkgggkk......',
    '....kkggkk......',
    '.....kkkk.......',
    '....gg....gg....',
    '....gg....gg....',
    '................',
  ],
  'hermes': [
    '....ww..ww......',
    '...wwwwwwww.....',
    '....wwwwww......',
    '................',
    '....kkkkkkk.....',
    '...kksssskks....',
    '...ksssksssk....',
    '...ksssssssk....',
    '....ssssssss....',
    '.....sssss......',
    '....bbbbbbbb....',
    '...bbbbbbbbbb...',
    '...bbbbbbbbbb...',
    '....bb....bb....',
    '...wwww.wwww....',
    '................',
  ],
  'athena': [
    '................',
    '....lllllll.....',
    '...llllllllll...',
    '...llkkllkkll...',
    '...lksskkskll...',
    '...lksssssksl...',
    '...lkssssssl....',
    '....ssssssss....',
    '.....sssss......',
    '....bbbbbbbb....',
    '...bbbbbbbbbb...',
    '...bblllllbbb...',
    '...bbbbbbbbbb...',
    '....bb....bb....',
    '....bb....bb....',
    '................',
  ],
  'poseidon': [
    '................',
    '....bbbbbbb.....',
    '...bbbbbbbbb....',
    '...bbkkbbkkbb...',
    '...bbkkbbkkbb...',
    '...bbssssssbb...',
    '...bsssssssb....',
    '....sssssss.....',
    '.....bbbbb......',
    '....c...bbb.....',
    '...cc..bbbb.....',
    '....c.bbbbbb....',
    '...cc.bbbb.cc...',
    '....bb....bb....',
    '....bb....bb....',
    '................',
  ],
  'default': [
    '................',
    '................',
    '....kkkkkkkk....',
    '...kkkkkkkkkk...',
    '...kkssssskk....',
    '...ksssssssk....',
    '...ksssssssk....',
    '....sssssss.....',
    '.....sssss......',
    '....bbbbbbbb....',
    '...bbbbbbbbbb...',
    '...bbbbbbbbbb...',
    '...bbbbbbbbbb...',
    '....bb....bb....',
    '....bb....bb....',
    '................',
  ],
};

/**
 * Create a 16x16 pixel sprite element
 * @param {string} characterId - the character identifier
 * @returns {HTMLElement} the sprite container with 256 pixel divs
 */
function createSprite(characterId) {
  const container = document.createElement('div');
  container.className = 'sprite-container';

  const pattern = SPRITES[characterId] || SPRITES['default'];

  for (let row = 0; row < 16; row++) {
    for (let col = 0; col < 16; col++) {
      const px = document.createElement('div');
      px.className = 'px';
      const ch = (pattern[row] && pattern[row][col]) || '.';
      const colorClass = COLOR_MAP[ch];
      if (colorClass) {
        px.classList.add(colorClass);
      }
      container.appendChild(px);
    }
  }

  return container;
}

/**
 * Render the tavern scene with placeholder content
 */
function renderScene() {
  return document.querySelector('.tavern-scene');
}

// Hero name to sprite ID mapping
const HERO_SPRITE_MAP = {
  'Nick Fury': 'nick-fury',
  '钢铁侠': 'iron-man', 'Iron Man': 'iron-man',
  '幻视': 'vision', 'Vision': 'vision',
  '蜘蛛侠': 'spider-man', 'Spider-Man': 'spider-man',
  '奇异博士': 'doctor-strange', 'Doctor Strange': 'doctor-strange',
  '海姆达尔': 'heimdall', 'Heimdall': 'heimdall',
  '火箭浣熊': 'rocket', 'Rocket': 'rocket',
  '星爵': 'star-lord', 'Star-Lord': 'star-lord',
  '猎鹰': 'falcon', 'Falcon': 'falcon',
};

const DEITY_SPRITE_MAP = {
  'Prometheus': 'prometheus',
  'Atlas': 'atlas',
  'Hephaestus': 'hephaestus',
  'Hercules': 'hercules',
  'Artemis': 'artemis',
  'Apollo': 'apollo',
  'Hermes': 'hermes',
  'Athena': 'athena',
  'Poseidon': 'poseidon',
  'Sisyphus': 'default',
  'Metis': 'default',
  'Momus': 'default',
  'explore': 'default',
  'librarian': 'default',
  'oracle': 'default',
};

/**
 * Get sprite ID from agent name
 */
function getSpriteId(agentName, wing) {
  if (wing === 'east') {
    return HERO_SPRITE_MAP[agentName] || 'default';
  }
  return DEITY_SPRITE_MAP[agentName] || 'default';
}

// Export globally
window.renderScene = renderScene;
window.createSprite = createSprite;
window.getSpriteId = getSpriteId;
window.SPRITES = SPRITES;

// ═══════════════════════════════════════════════════════════════════
// Integration Layer — Polling + Rendering
// ═══════════════════════════════════════════════════════════════════

const API_BASE = 'http://localhost:8000';
const POLL_INTERVAL = 5000;
let pollTimer = null;

async function fetchStatus() {
  try {
    const response = await fetch(`${API_BASE}/api/status`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Status fetch failed:', error);
    showError('API 连接失败 — 请启动后端服务');
    return null;
  }
}

async function fetchMessages() {
  try {
    const response = await fetch(`${API_BASE}/api/messages?limit=20`);
    if (!response.ok) return [];
    return await response.json();
  } catch { return []; }
}

async function fetchBlocked() {
  try {
    const response = await fetch(`${API_BASE}/api/blocked`);
    if (!response.ok) return [];
    return await response.json();
  } catch { return []; }
}

async function fetchHistory() {
  try {
    const response = await fetch(`${API_BASE}/api/history`);
    if (!response.ok) return {};
    return await response.json();
  } catch { return {}; }
}

function renderAgents(status) {
  if (!status) return;

  const eastGrid = document.getElementById('east-agents');
  const westGrid = document.getElementById('west-agents');
  if (!eastGrid || !westGrid) return;

  eastGrid.innerHTML = '';
  westGrid.innerHTML = '';

  let counts = { active: 0, idle: 0, sleeping: 0, error: 0 };

  (status.east_wing || []).forEach(agent => {
    const card = createAgentCard(agent, 'east');
    eastGrid.appendChild(card);
    if (counts[agent.status] !== undefined) counts[agent.status]++;
  });

  (status.west_wing || []).forEach(agent => {
    const card = createAgentCard(agent, 'west');
    westGrid.appendChild(card);
    if (counts[agent.status] !== undefined) counts[agent.status]++;
  });

  if (eastGrid.children.length === 0) {
    eastGrid.innerHTML = '<div class="empty-state">暂无英雄活动</div>';
  }
  if (westGrid.children.length === 0) {
    westGrid.innerHTML = '<div class="empty-state">暂无神祇活动</div>';
  }

  updateStats(counts);
  updateTimestamp(status.last_updated);
  hideError();
}

function createAgentCard(agent, wing) {
  const card = document.createElement('div');
  card.className = `agent-card ${wing === 'west' ? 'west' : ''}`;
  card.setAttribute('data-status', agent.status);
  card.setAttribute('data-agent-id', agent.id);

  const spriteId = getSpriteId(agent.name, wing);
  const sprite = createSprite(spriteId);
  card.appendChild(sprite);

  const name = document.createElement('div');
  name.className = 'agent-name';
  name.textContent = agent.name;
  card.appendChild(name);

  const statusDiv = document.createElement('div');
  statusDiv.className = 'agent-status';
  const dot = document.createElement('span');
  dot.className = `status-dot ${agent.status}`;
  statusDiv.appendChild(dot);
  const statusText = document.createElement('span');
  const statusLabels = { active: '论剑', idle: '饮酒', sleeping: '打坐', error: '走火入魔' };
  statusText.textContent = statusLabels[agent.status] || agent.status;
  statusDiv.appendChild(statusText);
  card.appendChild(statusDiv);

  const tooltip = document.createElement('div');
  tooltip.className = 'tooltip';
  const lastActive = agent.last_active ? new Date(agent.last_active).toLocaleTimeString() : '未知';
  tooltip.textContent = `${agent.name} · ${statusLabels[agent.status]} · 最后活动: ${lastActive}`;
  card.appendChild(tooltip);

  card.addEventListener('click', () => showAgentModal(agent));

  return card;
}

function updateStats(counts) {
  const els = {
    'stat-active': counts.active,
    'stat-idle': counts.idle,
    'stat-sleeping': counts.sleeping,
    'stat-error': counts.error,
  };
  for (const [id, val] of Object.entries(els)) {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  }
}

function updateTimestamp(isoString) {
  const el = document.getElementById('last-updated');
  if (el && isoString) {
    el.textContent = `最后更新: ${new Date(isoString).toLocaleTimeString()}`;
  }
}

function renderMessages(messages) {
  const list = document.getElementById('message-list');
  if (!list) return;
  list.innerHTML = '';
  (messages || []).slice(0, 20).forEach(msg => {
    const li = document.createElement('li');
    const time = msg.timestamp ? new Date(msg.timestamp).toLocaleTimeString() : '';
    li.textContent = `[${time}] ${msg.agent_name}: ${msg.content}`.substring(0, 120);
    list.appendChild(li);
  });
  if (list.children.length === 0) {
    list.innerHTML = '<li class="empty">暂无消息</li>';
  }
}

function renderBlocked(blocked) {
  const list = document.getElementById('blocked-list');
  if (!list) return;
  list.innerHTML = '';
  (blocked || []).forEach(agent => {
    const li = document.createElement('li');
    li.textContent = `⚠ ${agent.agent_name} — ${agent.reason}`;
    list.appendChild(li);
  });
  if (list.children.length === 0) {
    list.innerHTML = '<li class="empty">无阻塞</li>';
  }
}

function showError(msg) {
  let el = document.getElementById('error-banner');
  if (!el) {
    el = document.createElement('div');
    el.id = 'error-banner';
    el.style.cssText = 'background:var(--status-error);color:black;padding:8px;text-align:center;font-size:12px;font-weight:bold;';
    document.body.prepend(el);
  }
  el.textContent = msg;
  el.style.display = 'block';
}

function hideError() {
  const el = document.getElementById('error-banner');
  if (el) el.style.display = 'none';
}

function showAgentModal(agent) {
  const overlay = document.getElementById('modal-overlay');
  const content = document.getElementById('modal-content');
  if (!overlay || !content) return;

  const statusLabels = { active: '论剑', idle: '饮酒', sleeping: '打坐', error: '走火入魔' };
  const lastActive = agent.last_active ? new Date(agent.last_active).toLocaleString() : '未知';
  const messages = (agent.recent_messages || []).map(m => `<div class="modal-row"><span>${m.content || ''}</span></div>`).join('');

  content.innerHTML = `
    <h3>${agent.name}</h3>
    <div class="modal-row"><span>状态</span><span>${statusLabels[agent.status] || agent.status}</span></div>
    <div class="modal-row"><span>最后活动</span><span>${lastActive}</span></div>
    <div class="modal-row"><span>Token 输入</span><span>${agent.tokens_in || 0}</span></div>
    <div class="modal-row"><span>Token 输出</span><span>${agent.tokens_out || 0}</span></div>
    ${agent.current_task ? `<div class="modal-row"><span>当前任务</span><span>${agent.current_task}</span></div>` : ''}
    <div class="modal-messages"><h4>最近消息</h4>${messages || '<div>暂无</div>'}</div>
    <button class="modal-close" onclick="closeModal()">关闭 [Esc]</button>
  `;
  overlay.classList.add('active');
}

function closeModal() {
  const overlay = document.getElementById('modal-overlay');
  if (overlay) overlay.classList.remove('active');
}

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeModal();
  if (e.key === 'r' || e.key === 'R') {
    if (!e.ctrlKey && !e.metaKey) poll();
  }
  if (e.key === '?') {
    showHelpModal();
  }
});

function showHelpModal() {
  const overlay = document.getElementById('modal-overlay');
  const content = document.getElementById('modal-content');
  if (!overlay || !content) return;
  content.innerHTML = `
    <h3>⌨️ 快捷键</h3>
    <div class="modal-row"><span>R</span><span>手动刷新</span></div>
    <div class="modal-row"><span>?</span><span>显示帮助</span></div>
    <div class="modal-row"><span>Esc</span><span>关闭弹窗</span></div>
    <div class="modal-row"><span>点击角色</span><span>查看详情</span></div>
    <button class="modal-close" onclick="closeModal()">关闭</button>
  `;
  overlay.classList.add('active');
}

async function poll() {
  const [status, messages, blocked] = await Promise.all([
    fetchStatus(),
    fetchMessages(),
    fetchBlocked(),
  ]);
  renderAgents(status);
  renderMessages(messages);
  renderBlocked(blocked);
}

function init() {
  if (!document.getElementById('last-updated')) {
    const header = document.querySelector('.tavern-header');
    if (header) {
      const el = document.createElement('div');
      el.id = 'last-updated';
      el.style.cssText = 'font-size:10px;color:var(--paper-cream);opacity:0.7;margin-top:4px;';
      header.appendChild(el);
    }
  }

  poll();

  if (pollTimer) clearInterval(pollTimer);
  pollTimer = setInterval(poll, POLL_INTERVAL);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

window.init = init;
window.poll = poll;
window.closeModal = closeModal;
window.showAgentModal = showAgentModal;
