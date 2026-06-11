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
