from PIL import Image, ImageDraw
import yaml
import os

# Load mapping with proper error handling
try:
    with open('sprites/mapping.yaml', 'r') as f:
        mapping = yaml.safe_load(f)
except FileNotFoundError:
    print("Error: sprites/mapping.yaml not found")
    exit(1)

# Canvas dimensions
WIDTH = 96
HEIGHT = 32
FRAME_WIDTH = 32

# Endesga 32 palette subset (max 9 colors per sprite + transparent)
PALETTE = {
    'transparent': (0, 0, 0, 0),
    'outline': (41, 54, 64, 255),           # Dark outline
    'skin_light': (255, 219, 172, 255),      # #ffdbac
    'skin_tan': (241, 194, 125, 255),        # #f1c27d
    'skin_medium': (224, 172, 105, 255),     # #e0ac69
    'skin_olive': (198, 134, 66, 255),       # #c68642
    'skin_dark': (141, 85, 36, 255),         # #8d5524
    'hair_black': (30, 30, 30, 255),
    'hair_brown': (120, 80, 40, 255),
    'hair_blonde': (220, 180, 100, 255),
    'hair_red': (180, 80, 60, 255),
    'hair_grey': (160, 160, 160, 255),
    'hair_purple': (128, 64, 128, 255),
    'white': (255, 255, 255, 255),
    'light_grey': (200, 200, 200, 255),
    'dark_grey': (80, 80, 80, 255),
    'black': (20, 20, 20, 255),
    'accent_gold': (220, 180, 40, 255),
    'accent_silver': (180, 180, 200, 255),
    'accent_bronze': (160, 100, 60, 255),
}


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def create_base_body(skin_tone='light'):
    """Create base body silhouette"""
    body = Image.new('RGBA', (FRAME_WIDTH, HEIGHT), PALETTE['transparent'])
    draw = ImageDraw.Draw(body)
    
    skin = PALETTE[f'skin_{skin_tone}']
    
    # Head (8x8 centered)
    draw.ellipse([12, 4, 20, 12], fill=skin, outline=PALETTE['outline'])
    
    # Body (torso 12x12)
    draw.rectangle([10, 12, 22, 24], fill=skin, outline=PALETTE['outline'])
    
    # Arms
    draw.rectangle([8, 14, 10, 22], fill=skin, outline=PALETTE['outline'])
    draw.rectangle([22, 14, 24, 22], fill=skin, outline=PALETTE['outline'])
    
    # Legs
    draw.rectangle([12, 24, 14, 28], fill=skin, outline=PALETTE['outline'])
    draw.rectangle([18, 24, 20, 28], fill=skin, outline=PALETTE['outline'])
    
    return body


def apply_outfit(body, outfit_type, primary_color):
    """Apply outfit over body"""
    draw = ImageDraw.Draw(body)
    
    primary = hex_to_rgb(primary_color)
    primary_rgba = primary + (255,)
    
    # Darker shade for details
    detail = tuple(max(0, c - 40) for c in primary) + (255,)
    
    if outfit_type == 'robe':
        # Long flowing robe
        draw.rectangle([10, 12, 22, 24], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([12, 24, 14, 28], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([18, 24, 20, 28], fill=primary_rgba, outline=PALETTE['outline'])
        # Belt
        draw.rectangle([10, 18, 22, 19], fill=detail)
        
    elif outfit_type == 'armor':
        # Metal chestplate with shoulders
        draw.rectangle([10, 12, 22, 20], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([8, 14, 10, 18], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([22, 14, 24, 18], fill=primary_rgba, outline=PALETTE['outline'])
        # Armor details
        draw.rectangle([14, 14, 18, 16], fill=detail)
        draw.rectangle([10, 20, 22, 21], fill=detail)
        
    elif outfit_type == 'warrior':
        # Battle-ready leather/metal
        draw.rectangle([10, 12, 22, 22], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([12, 22, 14, 24], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([18, 22, 20, 24], fill=primary_rgba, outline=PALETTE['outline'])
        # Straps
        draw.line([12, 14, 20, 14], fill=detail, width=1)
        draw.line([12, 18, 20, 18], fill=detail, width=1)
        
    elif outfit_type == 'scholar':
        # Traditional academic robes
        draw.rectangle([10, 12, 22, 24], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([12, 24, 14, 28], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([18, 24, 20, 28], fill=primary_rgba, outline=PALETTE['outline'])
        # Collar detail
        draw.polygon([(14, 12), (16, 16), (18, 12)], fill=detail)
        
    elif outfit_type == 'hood':
        # Cloak with hood
        draw.rectangle([10, 12, 22, 24], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([12, 24, 14, 28], fill=primary_rgba, outline=PALETTE['outline'])
        draw.rectangle([18, 24, 20, 28], fill=primary_rgba, outline=PALETTE['outline'])
        # Hood over head
        draw.arc([11, 3, 21, 9], 180, 0, fill=PALETTE['outline'], width=2)
        draw.rectangle([11, 3, 21, 6], fill=primary_rgba)


def apply_hair(body, hair_color, hair_style='short'):
    """Apply hair over body"""
    draw = ImageDraw.Draw(body)
    
    hair = PALETTE[f'hair_{hair_color}']
    
    if hair_style == 'short':
        # Short hair on top
        draw.rectangle([12, 4, 20, 7], fill=hair)
    elif hair_style == 'long':
        # Long flowing hair
        draw.rectangle([12, 4, 20, 10], fill=hair)
        draw.rectangle([11, 10, 12, 14], fill=hair)
        draw.rectangle([20, 10, 21, 14], fill=hair)
    elif hair_style == 'bun':
        # Topknot/bun
        draw.rectangle([12, 4, 20, 7], fill=hair)
        draw.ellipse([14, 2, 18, 6], fill=hair)
    elif hair_style == 'none':
        # Bald
        pass


def apply_accessory(body, accessory_type):
    """Apply weapon or tool"""
    draw = ImageDraw.Draw(body)
    
    if accessory_type == 'fan':
        # Feather fan (right hand)
        draw.polygon([(24, 16), (28, 12), (28, 20)], 
                    fill=PALETTE['accent_gold'], outline=PALETTE['outline'])
        
    elif accessory_type == 'sword':
        # Long sword (right side)
        draw.rectangle([25, 8, 27, 24], fill=PALETTE['accent_silver'], outline=PALETTE['outline'])
        draw.rectangle([24, 22, 28, 24], fill=PALETTE['accent_bronze'])
        
    elif accessory_type == 'staff':
        # Wooden staff (right hand)
        draw.rectangle([25, 6, 27, 28], fill=PALETTE['hair_brown'], outline=PALETTE['outline'])
        draw.ellipse([24, 4, 28, 8], fill=PALETTE['accent_gold'])
        
    elif accessory_type == 'book':
        # Book (left hand)
        draw.rectangle([4, 16, 8, 20], fill=PALETTE['hair_brown'], outline=PALETTE['outline'])
        draw.rectangle([5, 17, 7, 19], fill=PALETTE['white'])
        
    elif accessory_type == 'hammer':
        # Blacksmith hammer (right hand)
        draw.rectangle([25, 14, 27, 26], fill=PALETTE['hair_brown'], outline=PALETTE['outline'])
        draw.rectangle([23, 14, 29, 18], fill=PALETTE['dark_grey'], outline=PALETTE['outline'])
        
    elif accessory_type == 'scepter':
        # Royal scepter (right hand)
        draw.rectangle([25, 10, 27, 26], fill=PALETTE['accent_gold'], outline=PALETTE['outline'])
        draw.ellipse([24, 8, 28, 12], fill=PALETTE['accent_gold'])
        draw.ellipse([25, 9, 27, 11], fill=(255, 220, 180, 255))


def apply_animation(frame_idx, base_sprite):
    """Apply animation to frame"""
    frame = base_sprite.copy()
    draw = ImageDraw.Draw(frame)
    
    if frame_idx == 0:
        # Idle frame - no changes
        pass
    elif frame_idx == 1:
        # Work frame - arms up, action pose
        # Shift arms up
        for x in range(8, 11):
            for y in range(14, 22):
                pixel = frame.getpixel((x, y))
                if pixel[3] > 0:  # Not transparent
                    frame.putpixel((x, y - 2), pixel)
                    frame.putpixel((x, y), PALETTE['transparent'])
                    
        for x in range(22, 25):
            for y in range(14, 22):
                pixel = frame.getpixel((x, y))
                if pixel[3] > 0:
                    frame.putpixel((x, y - 2), pixel)
                    frame.putpixel((x, y), PALETTE['transparent'])
                    
    elif frame_idx == 2:
        # Rest frame - sitting pose
        # Shift body down
        for y in range(HEIGHT - 1, -1, -1):
            for x in range(FRAME_WIDTH):
                pixel = frame.getpixel((x, y))
                if pixel[3] > 0 and y + 2 < HEIGHT:
                    frame.putpixel((x, y + 2), pixel)
                    frame.putpixel((x, y), PALETTE['transparent'])
    
    return frame


def parse_role_key(role_name):
    """Parse role name to determine characteristics"""
    # Heroes
    if 'kongming' in role_name:
        return {'skin': 'light', 'hair': 'black', 'hair_style': 'bun', 
                'outfit': 'robe', 'accessory': 'fan'}
    elif 'wenyuan' in role_name:
        return {'skin': 'tan', 'hair': 'black', 'hair_style': 'short',
                'outfit': 'warrior', 'accessory': 'sword'}
    elif 'zichang' in role_name:
        return {'skin': 'medium', 'hair': 'black', 'hair_style': 'bun',
                'outfit': 'scholar', 'accessory': 'book'}
    elif 'xiren' in role_name:
        return {'skin': 'olive', 'hair': 'black', 'hair_style': 'short',
                'outfit': 'armor', 'accessory': 'hammer'}
    elif 'xuancheng' in role_name:
        return {'skin': 'light', 'hair': 'black', 'hair_style': 'bun',
                'outfit': 'scholar', 'accessory': 'book'}
    elif 'pengju' in role_name:
        return {'skin': 'tan', 'hair': 'black', 'hair_style': 'short',
                'outfit': 'warrior', 'accessory': 'sword'}
    elif 'ziwen' in role_name:
        return {'skin': 'light', 'hair': 'black', 'hair_style': 'long',
                'outfit': 'robe', 'accessory': 'staff'}
    elif 'zhenghe' in role_name:
        return {'skin': 'tan', 'hair': 'black', 'hair_style': 'short',
                'outfit': 'robe', 'accessory': 'scepter'}
    elif 'xiake' in role_name:
        return {'skin': 'medium', 'hair': 'brown', 'hair_style': 'short',
                'outfit': 'hood', 'accessory': 'staff'}
    # Deities
    elif 'prometheus' in role_name:
        return {'skin': 'olive', 'hair': 'red', 'hair_style': 'long',
                'outfit': 'robe', 'accessory': 'scepter'}
    elif 'sisyphus' in role_name:
        return {'skin': 'tan', 'hair': 'brown', 'hair_style': 'short',
                'outfit': 'warrior', 'accessory': 'none'}
    elif 'atlas' in role_name:
        return {'skin': 'medium', 'hair': 'black', 'hair_style': 'short',
                'outfit': 'armor', 'accessory': 'none'}
    elif 'hephaestus' in role_name:
        return {'skin': 'olive', 'hair': 'red', 'hair_style': 'short',
                'outfit': 'armor', 'accessory': 'hammer'}
    elif 'oracle' in role_name:
        return {'skin': 'light', 'hair': 'purple', 'hair_style': 'long',
                'outfit': 'hood', 'accessory': 'staff'}
    elif 'explore' in role_name:
        return {'skin': 'tan', 'hair': 'brown', 'hair_style': 'short',
                'outfit': 'hood', 'accessory': 'staff'}
    elif 'librarian' in role_name:
        return {'skin': 'light', 'hair': 'grey', 'hair_style': 'bun',
                'outfit': 'scholar', 'accessory': 'book'}


def generate_sprite_sheet(role_name, primary_color):
    """Generate 3-frame sprite sheet"""
    sheet = Image.new('RGBA', (WIDTH, HEIGHT), PALETTE['transparent'])
    
    # Parse role characteristics
    config = parse_role_key(role_name)
    
    # Create base body
    base = create_base_body(config['skin'])
    
    # Apply outfit
    apply_outfit(base, config['outfit'], primary_color)
    
    # Apply hair
    apply_hair(base, config['hair'], config['hair_style'])
    
    # Apply accessory
    apply_accessory(base, config['accessory'])
    
    # Generate 3 animation frames
    for i in range(3):
        frame = apply_animation(i, base)
        sheet.paste(frame, (i * FRAME_WIDTH, 0))
    
    return sheet


def count_colors(image):
    """Count unique colors in image"""
    colors = set()
    for x in range(image.width):
        for y in range(image.height):
            pixel = image.getpixel((x, y))
            if pixel[3] > 0:  # Not transparent
                colors.add(pixel[:3])  # Ignore alpha
    return len(colors)


def main():
    """Main generation function"""
    output_dir = 'web/static/img/sprites'
    os.makedirs(output_dir, exist_ok=True)
    
    # Combine heroes and deities
    all_roles = {}
    all_roles.update(mapping.get('heroes', {}))
    all_roles.update(mapping.get('deities', {}))
    
    print(f"Generating {len(all_roles)} sprite sheets...")
    
    for role_name, config in all_roles.items():
        primary_color = config['primary_color']
        
        # Generate sprite sheet
        sheet = generate_sprite_sheet(role_name, primary_color)
        
        # Verify color count
        color_count = count_colors(sheet)
        if color_count > 9:
            print(f"Warning: {role_name} has {color_count} colors (max 9)")
        
        # Save
        output_path = os.path.join(output_dir, f"{role_name}.png")
        sheet.save(output_path)
        print(f"Generated {role_name}.png ({color_count} colors)")
    
    print(f"\nAll sprites generated in {output_dir}/")


if __name__ == '__main__':
    main()
