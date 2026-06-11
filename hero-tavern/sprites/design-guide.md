# Pixel Sprite Component Design Guide

## Canvas
- **Resolution**: 32x32 pixels per frame
- **Sheet layout**: 96x32 = 3 frames side-by-side (frame1 | frame2 | frame3)
- **Background**: transparent
- **Palette**: max 9 colors per sprite (retro authenticity)

## Component Categories

### 1. Body Types (5 variants)
| Name | Description |
|------|-------------|
| standard | Average build |
| thin | Slender frame |
| tall | Taller than average |
| short | Compact build |
| strong | Muscular/wide |

### 2. Skin Tones (5 shades)
| Hex | Preview |
|-----|---------|
| #ffdbac | light |
| #f1c27d | tan |
| #e0ac69 | medium |
| #c68642 | olive |
| #8d5524 | dark |

### 3. Hair Colors (6 options)
black, brown, blonde, red, grey, purple

### 4. Outfits (6 styles)
- **robe**: Long flowing garment (scholars, oracles)
- **armor**: Metal chestplate + shoulders
- **suit**: Modern-style clothing
- **hood**: Cloak with hood (wizards, explorers)
- **scholar**: Traditional academic robes
- **warrior**: Battle-ready leather/metal

### 5. Accessories (7 options)
staff | sword | book | hammer | scepter | fan | none

### 6. Primary Color (16 options)
Each sprite gets one distinct primary color for instant recognition. Use the "Endesga 32" palette or "Sweetie 16".

## Animation Rules (2-3 frames per state)

### Frame 1: Idle (Standing)
- 2-frame vertical bob (1-2 pixels vertical)
- Cycle: 2 seconds total

### Frame 2: Work (Active)
- 3-frame cycle: arm up → reaching → strike
- Cycle: 1.5 seconds total

### Frame 3: Rest (Sitting/Sleeping)
- 2-frame head tilt
- Cycle: 3 seconds total

## Layering Order (back to front)
1. Body (silhouette)
2. Outfit (over body)
3. Hair (over body/neck)
4. Accessory (on top)

## File Naming
`<agent-id>.png` — e.g. `kongming.png`, `prometheus.png`

## Reference Palette
- Endesga 32: https://lospec.com/palette-list/endesga-32
- Sweetie 16: https://lospec.com/palette-list/sweetie-16
