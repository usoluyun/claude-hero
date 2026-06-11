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
// Integration Layer — Session-Based Rendering
// ═══════════════════════════════════════════════════════════════════

const API_BASE = 'http://localhost:8000';
const POLL_INTERVAL = 5000;
let pollTimer = null;

const statusLabels = {
  active: '论剑',
  idle: '饮酒',
  sleeping: '打坐',
  error: '走火入魔'
};

async function fetchStatus() {
  try {
    const response = await fetch(`${API_BASE}/api/status`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const statusData = await response.json();
    
    if (statusData.sessions) {
      renderSessions(statusData.sessions);
      updateStatusCounts(statusData.status_summary);
    } else {
      console.error('API returned unexpected format — expected sessions array');
    }
    
    updateTimestamp(statusData.last_updated);
    hideError();
  } catch (error) {
    console.error('Status fetch failed:', error);
    showError('API 连接失败 — 请启动后端服务');
  }
}

async function fetchMessages() {
  try {
    const response = await fetch(`${API_BASE}/api/messages?limit=20`);
    if (!response.ok) return [];
    return await response.json();
  } catch (err) { console.error('Messages fetch failed:', err); return []; }
}

async function fetchBlocked() {
  try {
    const response = await fetch(`${API_BASE}/api/blocked`);
    if (!response.ok) return [];
    return await response.json();
  } catch (err) { console.error('Blocked fetch failed:', err); return []; }
}

async function fetchHistory() {
  try {
    const response = await fetch(`${API_BASE}/api/history`);
    if (!response.ok) return {};
    return await response.json();
  } catch (err) { console.error('History fetch failed:', err); return {}; }
}

function renderSessions(sessions) {
  const heroesContainer = document.getElementById('heroes-container');
  const deitiesContainer = document.getElementById('deities-container');
  
  if (!heroesContainer || !deitiesContainer) {
    console.error('Session containers not found');
    return;
  }
  
  heroesContainer.innerHTML = '';
  deitiesContainer.innerHTML = '';
  
  // Split into active sessions vs sleeping sessions (all agents = sleeping)
  const activeSessions = [];
  const sleepingSessions = [];
  
  sessions.forEach(session => {
    const allSleeping = !session.agents ||
                        session.agents.length === 0 ||
                        session.agents.every(a => a.status === 'sleeping');
    if (allSleeping) {
      sleepingSessions.push(session);
    } else {
      activeSessions.push(session);
    }
  });
  
  // Render active sessions (backend pre-sorts by activity_score DESC)
  activeSessions.forEach((session, idx) => {
    const card = createSessionCard(session, idx);
    if (session.source === 'claude') {
      heroesContainer.appendChild(card);
    } else {
      deitiesContainer.appendChild(card);
    }
  });
  
  // Render sleeping counter at bottom of each wing if applicable
  // Distribute sleeping sessions to the wing their source belongs to
  const heroesSleeping = sleepingSessions.filter(s => s.source === 'claude');
  const deitiesSleeping = sleepingSessions.filter(s => s.source !== 'claude');
  
  if (heroesSleeping.length > 0) {
    heroesContainer.appendChild(createSleepingCounter(heroesSleeping));
  }
  if (deitiesSleeping.length > 0) {
    deitiesContainer.appendChild(createSleepingCounter(deitiesSleeping));
  }
  
  // Empty states (only if no active sessions and no sleeping counter)
  if (heroesContainer.children.length === 0) {
    heroesContainer.innerHTML = '<div class="empty-state">暂无英雄活动</div>';
  }
  if (deitiesContainer.children.length === 0) {
    deitiesContainer.innerHTML = '<div class="empty-state">暂无神祇活动</div>';
  }
}

function createSessionCard(session, index) {
  const card = document.createElement('div');
  card.className = 'session-card';
  card.setAttribute('data-session-id', session.session_id);
  
  const dominantStatus = calculateDominantStatus(session.agents);
  card.setAttribute('data-status', dominantStatus);
  
  const allSleeping = session.agents.length === 0 || 
                      session.agents.every(a => a.status === 'sleeping');
  card.setAttribute('data-sleeping', allSleeping ? 'true' : 'false');
  
  const statusCountsText = buildStatusCountsText(session);
  
  card.innerHTML = `
    <div class="session-header">
      <div class="session-info">
        <span class="session-project">${escapeHtml(session.project_short || session.session_id.slice(0, 8))}</span>
        <span class="session-status">${statusLabels[dominantStatus] || dominantStatus}</span>
        ${statusCountsText ? `<span class="status-counts">${statusCountsText}</span>` : ''}
      </div>
      <div class="expand-icon">▸</div>
    </div>
    <div class="session-body collapsed">
      <div class="agents-preview">
        ${buildAgentsPreview(session)}
      </div>
    </div>
    <div class="session-body expanded hidden">
      <div class="agents-full-list">
      </div>
    </div>
  `;
  
  const header = card.querySelector('.session-header');
  const bodyCollapsed = card.querySelector('.session-body.collapsed');
  const bodyExpanded = card.querySelector('.session-body.expanded');
  const expandIcon = card.querySelector('.expand-icon');
  
  header.addEventListener('click', () => {
    const isExpanded = !bodyExpanded.classList.contains('hidden');
    
    if (isExpanded) {
      bodyCollapsed.classList.remove('hidden');
      bodyExpanded.classList.add('hidden');
      expandIcon.textContent = '▸';
    } else {
      bodyCollapsed.classList.add('hidden');
      bodyExpanded.classList.remove('hidden');
      expandIcon.textContent = '▾';
    }
  });
  
  // Populate agents-full-list with full agent cards
  const fullList = card.querySelector('.agents-full-list');
  if (session.agents && session.agents.length > 0) {
    session.agents.forEach(agent => {
      fullList.appendChild(createAgentCard(agent, 'full'));
    });
  } else {
    fullList.innerHTML = '<div class="agent-info"><em>无 agent 数据</em></div>';
  }
  
  return card;
}

function calculateDominantStatus(agents) {
  if (agents.length === 0) return 'sleeping';
  
  const hasError = agents.some(a => a.status === 'error');
  const hasActive = agents.some(a => a.status === 'active');
  const hasIdle = agents.some(a => a.status === 'idle');
  
  if (hasError) return 'error';
  if (hasActive) return 'active';
  if (hasIdle) return 'idle';
  return 'sleeping';
}

function buildStatusCountsText(session) {
  if (!session.agents || session.agents.length === 0) return '';
  
  const counts = { active: 0, idle: 0, sleeping: 0, error: 0 };
  session.agents.forEach(a => {
    if (counts.hasOwnProperty(a.status)) counts[a.status]++;
  });
  
  const parts = [];
  if (counts.active > 0) parts.push(`${counts.active} ${statusLabels.active}`);
  if (counts.idle > 0) parts.push(`${counts.idle} ${statusLabels.idle}`);
  if (counts.sleeping > 0) parts.push(`${counts.sleeping} ${statusLabels.sleeping}`);
  if (counts.error > 0) parts.push(`${counts.error} ${statusLabels.error}`);
  
  return parts.join(' · ');
}

function buildAgentsPreview(session) {
  if (!session.agents || session.agents.length === 0) return '无 agents';
  
  const preview = session.agents.slice(0, 3).map(a => escapeHtml(a.name)).join(', ');
  const remaining = session.agents.length > 3 ? ` +${session.agents.length - 3}` : '';
  
  return preview + remaining;
}

function createAgentCard(agent, variant = 'full') {
  const card = document.createElement('div');
  card.className = variant === 'mini' ? 'agent-mini-card' : 'agent-full-card';
  card.setAttribute('data-status', agent.status);

  const spriteId = agent.sprite_id ||
    DEITY_SPRITE_MAP[agent.name] ||
    HERO_SPRITE_MAP[agent.name] ||
    agent.name.toLowerCase().replace(/\s+/g, '-') ||
    'default';

  const spriteImg = document.createElement('img');
  spriteImg.src = `img/sprites/${spriteId}.png`;
  spriteImg.alt = agent.name;
  spriteImg.className = 'agent-sprite';
  spriteImg.width = 32;
  spriteImg.height = 32;
  spriteImg.onerror = () => {
    spriteImg.style.display = 'none';
    const fallback = createSprite(spriteId);
    fallback.classList.add('agent-sprite-fallback');
    card.insertBefore(fallback, card.firstChild);
  };

  card.appendChild(spriteImg);

  const info = document.createElement('div');
  info.className = 'agent-info';
  info.innerHTML = `
    <div class="agent-name">${escapeHtml(agent.name)}</div>
    <div class="agent-status"><span class="status-dot status-dot-${agent.status}"></span>${statusLabels[agent.status] || agent.status}</div>
  `;
  card.appendChild(info);

  if (variant === 'full') {
    const extra = document.createElement('div');
    extra.className = 'agent-extra';
    const lastActive = agent.last_active
      ? new Date(agent.last_active).toLocaleTimeString()
      : '—';
    const tokensTotal = (agent.tokens_in || 0) + (agent.tokens_out || (agent.tokens || 0));
    extra.innerHTML = `
      <div class="agent-tokens">T:${tokensTotal}</div>
      <div class="agent-last-active">${lastActive}</div>
    `;
    card.appendChild(extra);
  }

  card.addEventListener('click', (e) => {
    e.stopPropagation();
    showAgentModal(agent);
  });

  return card;
}

function createSleepingCounter(sessions) {
  const wrapper = document.createElement('div');
  wrapper.className = 'sleeping-counter collapsed';

  const header = document.createElement('div');
  header.className = 'sleeping-header';
  header.innerHTML = `
    <span class="sleeping-icon">💤</span>
    <span class="sleeping-count">${sessions.length} 个 session 在打坐</span>
    <span class="expand-icon">▸</span>
  `;
  wrapper.appendChild(header);

  const list = document.createElement('div');
  list.className = 'sleeping-list hidden';

  sessions.forEach((session, idx) => {
    const card = createSessionCard(session, idx);
    card.classList.add('sleeping-card');
    list.appendChild(card);
  });

  wrapper.appendChild(list);

  header.addEventListener('click', () => {
    const isExpanded = !list.classList.contains('hidden');
    if (isExpanded) {
      list.classList.add('hidden');
      wrapper.classList.remove('expanded');
      wrapper.classList.add('collapsed');
      header.querySelector('.expand-icon').textContent = '▸';
    } else {
      list.classList.remove('hidden');
      wrapper.classList.add('expanded');
      wrapper.classList.remove('collapsed');
      header.querySelector('.expand-icon').textContent = '▾';
    }
  });

  return wrapper;
}

function updateStatusCounts(summary) {
  if (!summary) return;
  
  const els = {
    'count-active': summary.active,
    'count-idle': summary.idle,
    'count-sleeping': summary.sleeping,
    'count-error': summary.error
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

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
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
