#!/usr/bin/env python3
"""
Sprite generator for HorseShooter game
Creates pixel art sprites programmatically using PIL
Slapstick comedy style - exaggerated, cartoonish, non-violent
"""

from PIL import Image, ImageDraw
import os
import math

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SPRITE_DIR = os.path.join(PROJECT_ROOT, "assets", "sprites")

def create_directory():
    """Create assets directory if it doesn't exist"""
    os.makedirs(SPRITE_DIR, exist_ok=True)


def draw_pixel_rect(draw, x, y, w, h, color):
    """Draw a rectangle in pixel-art style"""
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def create_player_sprite():
    """Create a readable female gunslinger sprite (32x32)."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    skin = (193, 145, 114)
    hair = (53, 28, 16)
    hair_highlight = (96, 54, 30)
    coat_dark = (42, 27, 23)
    coat_light = (70, 46, 36)
    scarf = (151, 43, 28)
    pants = (54, 54, 62)
    boots = (24, 18, 16)
    metal = (120, 124, 132)

    draw.ellipse([9, 8, 22, 21], fill=hair)
    draw.polygon([(9, 13), (6, 27), (10, 29), (13, 15)], fill=hair)
    draw.polygon([(22, 13), (25, 27), (21, 29), (18, 15)], fill=hair)
    draw.line([(12, 10), (10, 25)], fill=hair_highlight, width=1)
    draw.line([(19, 10), (21, 25)], fill=hair_highlight, width=1)

    draw.ellipse([11, 9, 20, 18], fill=skin)
    draw.line([(13, 13), (15, 12)], fill=(32, 18, 12), width=1)
    draw.line([(18, 13), (16, 12)], fill=(32, 18, 12), width=1)
    draw.line([(13, 17), (18, 16)], fill=(74, 36, 28), width=1)

    draw.polygon([(10, 18), (21, 18), (24, 28), (18, 31), (14, 31), (8, 28)], fill=coat_dark)
    draw.polygon([(12, 18), (19, 18), (21, 27), (16, 30), (11, 27)], fill=coat_light)
    draw.rectangle([11, 18, 20, 20], fill=scarf)
    draw.line([(12, 19), (18, 27)], fill=(196, 146, 82), width=1)

    draw.polygon([(9, 20), (5, 24), (6, 27), (10, 24)], fill=skin)
    draw.polygon([(21, 20), (26, 20), (27, 23), (22, 24)], fill=skin)

    draw.rectangle([12, 27, 15, 31], fill=pants)
    draw.rectangle([17, 27, 20, 31], fill=pants)
    draw.rectangle([11, 30, 16, 32], fill=boots)
    draw.rectangle([16, 30, 21, 32], fill=boots)

    draw.rectangle([24, 19, 30, 21], fill=metal)
    draw.rectangle([22, 20, 25, 24], fill=(56, 40, 34))
    draw.rectangle([28, 18, 31, 22], fill=(156, 110, 66))

    img.save(os.path.join(SPRITE_DIR, "player.png"))
    print("Created player.png")


def create_horse_sprite():
    """Create cartoon horse sprites (48x32) - slapstick style with googly eyes"""
    # Multiple colors for variety
    colors = [
        (139, 69, 19),  # Brown
        (255, 255, 255),  # White
        (128, 128, 128),  # Gray
        (0, 0, 0),  # Black
    ]

    for i, color in enumerate(colors):
        img = Image.new("RGBA", (48, 32), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Body (oval-ish rectangle)
        draw_pixel_rect(draw, 8, 14, 24, 12, color)
        # Add shading
        draw_pixel_rect(draw, 10, 16, 20, 8, tuple(max(0, c - 30) for c in color))

        # Neck
        draw_pixel_rect(draw, 26, 6, 8, 10, color)
        # Mane (comic style - spiky)
        mane_color = (50, 50, 50) if color != (0, 0, 0) else (80, 80, 80)
        draw_pixel_rect(draw, 28, 4, 4, 6, mane_color)
        draw_pixel_rect(draw, 30, 2, 2, 4, mane_color)
        draw_pixel_rect(draw, 32, 3, 2, 3, mane_color)

        # Head
        draw_pixel_rect(draw, 32, 8, 12, 10, color)
        # Snout (lighter)
        snout_color = tuple(min(255, c + 40) for c in color)
        draw_pixel_rect(draw, 40, 12, 6, 6, snout_color)

        # Googly eyes (slapstick comedy style - big white circles with small pupils)
        draw_pixel_rect(draw, 34, 9, 4, 4, (255, 255, 255))  # Left eye white
        draw_pixel_rect(draw, 38, 9, 4, 4, (255, 255, 255))  # Right eye white
        # Pupils (looking slightly crazed/surprised)
        draw_pixel_rect(draw, 36, 10, 2, 2, (0, 0, 0))  # Left pupil
        draw_pixel_rect(draw, 39, 10, 2, 2, (0, 0, 0))  # Right pupil
        # Eye shine
        draw_pixel_rect(draw, 36, 10, 1, 1, (255, 255, 255))
        draw_pixel_rect(draw, 39, 10, 1, 1, (255, 255, 255))

        # Nostrils
        draw_pixel_rect(draw, 42, 14, 1, 1, (0, 0, 0))
        draw_pixel_rect(draw, 44, 14, 1, 1, (0, 0, 0))

        # Legs (comic style - stubby)
        leg_color = tuple(max(0, c - 20) for c in color)
        draw_pixel_rect(draw, 10, 26, 3, 4, leg_color)
        draw_pixel_rect(draw, 16, 26, 3, 4, leg_color)
        draw_pixel_rect(draw, 22, 26, 3, 4, leg_color)
        draw_pixel_rect(draw, 26, 26, 3, 4, leg_color)

        # Hooves
        draw_pixel_rect(draw, 10, 30, 3, 2, (50, 50, 50))
        draw_pixel_rect(draw, 16, 30, 3, 2, (50, 50, 50))
        draw_pixel_rect(draw, 22, 30, 3, 2, (50, 50, 50))
        draw_pixel_rect(draw, 26, 30, 3, 2, (50, 50, 50))

        # Tail (comic style)
        tail_color = mane_color
        draw_pixel_rect(draw, 4, 12, 4, 8, tail_color)
        draw_pixel_rect(draw, 2, 14, 2, 6, tail_color)
        draw_pixel_rect(draw, 6, 18, 2, 4, tail_color)

        filename = os.path.join(SPRITE_DIR, f"horse_{i}.png")
        img.save(filename)
        print(f"Created {filename}")


def create_bullet_sprite():
    """Create a cartoon projectile (16x8)"""
    img = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Bullet body (yellow-orange cartoon bullet)
    draw_pixel_rect(draw, 4, 2, 10, 4, (255, 200, 50))
    # Bullet tip (darker)
    draw_pixel_rect(draw, 12, 2, 3, 4, (255, 140, 0))
    # Shine
    draw_pixel_rect(draw, 6, 3, 4, 1, (255, 255, 200))

    img.save(os.path.join(SPRITE_DIR, "bullet.png"))
    print("Created bullet.png")


def create_powerup_sprites():
    """Create readable pickup icons (32x32) for each gameplay power-up."""
    styles = {
        "rapid_fire": {
            "base": (255, 190, 30, 255),
            "accent": (255, 76, 35, 255),
            "symbol": "bolt",
        },
        "spread_shot": {
            "base": (40, 210, 255, 255),
            "accent": (15, 80, 200, 255),
            "symbol": "spread",
        },
        "shield": {
            "base": (220, 92, 255, 255),
            "accent": (88, 32, 180, 255),
            "symbol": "shield",
        },
        "speed_boost": {
            "base": (94, 235, 102, 255),
            "accent": (22, 130, 64, 255),
            "symbol": "chevron",
        },
    }

    for name, style in styles.items():
        img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        base = style["base"]
        accent = style["accent"]

        draw.ellipse([2, 2, 29, 29], fill=(255, 255, 255, 225))
        draw.ellipse([4, 4, 27, 27], fill=base)
        draw.ellipse([7, 7, 24, 24], outline=(255, 255, 255, 210), width=2)
        draw.arc([5, 5, 27, 27], 210, 330, fill=accent, width=3)

        symbol = style["symbol"]
        if symbol == "bolt":
            draw.polygon([(17, 6), (9, 17), (15, 17), (13, 26), (23, 13), (17, 13)], fill=(255, 255, 255, 255))
            draw.line([(17, 6), (9, 17), (15, 17), (13, 26)], fill=accent, width=1)
        elif symbol == "spread":
            for end in [(9, 9), (16, 7), (23, 9)]:
                draw.line([(16, 22), end], fill=(255, 255, 255, 255), width=3)
            draw.ellipse([13, 19, 19, 25], fill=accent)
        elif symbol == "shield":
            draw.polygon([(16, 7), (24, 11), (22, 21), (16, 26), (10, 21), (8, 11)], fill=(255, 255, 255, 255))
            draw.polygon([(16, 10), (21, 12), (20, 20), (16, 23), (12, 20), (11, 12)], fill=accent)
        elif symbol == "chevron":
            draw.polygon([(9, 8), (20, 16), (9, 24), (9, 18), (5, 18), (5, 14), (9, 14)], fill=(255, 255, 255, 255))
            draw.polygon([(18, 8), (27, 16), (18, 24), (18, 18), (14, 18), (14, 14), (18, 14)], fill=accent)

        filename = os.path.join(SPRITE_DIR, f"powerup_{name}.png")
        img.save(filename)
        print(f"Created {filename}")


def create_explosion_animation():
    """Create cartoon explosion frames (32x32) - slapstick puff/smoke style"""
    frames = 4

    for frame in range(frames):
        img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Cartoon smoke puff - growing circles
        base_size = 8 + frame * 8
        alpha = 255 - frame * 50

        # Outer smoke (gray)
        smoke_color = (200, 200, 200, alpha)
        for i in range(8):
            offset_x = (i % 3) * 8 - 4
            offset_y = (i // 3) * 8 - 4
            size = base_size + (i % 3) * 2
            draw.ellipse(
                [
                    16 + offset_x - size // 2,
                    16 + offset_y - size // 2,
                    16 + offset_x + size // 2,
                    16 + offset_y + size // 2,
                ],
                fill=smoke_color,
            )

        # Inner "KA-BOOM" text effect for comic style (on later frames)
        if frame >= 2:
            # Comic starburst
            for angle in range(0, 360, 45):
                rad = math.radians(angle)
                x1 = 24 + int(8 * math.cos(rad))
                y1 = 24 + int(8 * math.sin(rad))
                x2 = 24 + int((12 + frame * 2) * math.cos(rad))
                y2 = 24 + int((12 + frame * 2) * math.sin(rad))
                draw.line([x1, y1, x2, y2], fill=(255, 255, 0, alpha), width=3)

        filename = os.path.join(SPRITE_DIR, f"explosion_{frame}.png")
        img.save(filename)
        print(f"Created {filename}")


def create_grass_background():
    """Create grass tile background (64x64, seamless)"""
    img = Image.new("RGBA", (64, 64), (34, 139, 34))  # Forest green base
    draw = ImageDraw.Draw(img)

    # Add grass texture with varying greens
    greens = [
        (50, 160, 50),
        (40, 145, 40),
        (60, 170, 60),
        (30, 130, 30),
    ]

    for y in range(0, 64, 4):
        for x in range(0, 64, 4):
            if (x + y) % 8 == 0:
                color = greens[(x // 8 + y // 8) % len(greens)]
                draw_pixel_rect(draw, x, y, 4, 4, color)

    # Add some random grass blades
    for i in range(20):
        x = (i * 13) % 60
        y = (i * 7) % 60
        draw_pixel_rect(draw, x, y, 2, 4, (70, 180, 70))

    img.save(os.path.join(SPRITE_DIR, "grass.png"))
    print("Created grass.png")


def create_icon():
    """Create app icon (256x256)"""
    img = Image.new("RGBA", (256, 256), (135, 206, 235))  # Sky blue
    draw = ImageDraw.Draw(img)

    # Grass at bottom
    draw.rectangle([0, 180, 256, 256], fill=(34, 139, 34))

    # Cartoon sun
    draw.ellipse([20, 20, 80, 80], fill=(255, 255, 0))

    # Simplified horse in center (cartoon style)
    # Body
    draw.ellipse([88, 120, 168, 160], fill=(255, 255, 255))  # White horse
    # Head
    draw.ellipse([140, 100, 180, 140], fill=(255, 255, 255))
    # Eye (googly)
    draw.ellipse([155, 110, 165, 120], fill=(255, 255, 255), outline=(0, 0, 0), width=2)
    draw.ellipse([158, 113, 162, 117], fill=(0, 0, 0))

    img.save(os.path.join(SPRITE_DIR, "icon.png"))
    print("Created icon.png")


def create_rpg_portrait():
    """Create the required player-character portrait: female, long dark brown hair."""
    img = Image.new("RGBA", (256, 256), (20, 24, 22, 255))
    draw = ImageDraw.Draw(img)

    for y in range(256):
        blend = y / 255.0
        color = (
            int(18 + blend * 18),
            int(24 + blend * 12),
            int(22 + blend * 10),
            255,
        )
        draw.line([(0, y), (255, y)], fill=color, width=1)

    draw.ellipse([24, 18, 232, 242], fill=(42, 30, 27, 255))
    draw.arc([22, 16, 234, 244], 200, 340, fill=(220, 132, 68, 255), width=5)

    hair_dark = (39, 20, 12, 255)
    hair_mid = (74, 40, 22, 255)
    hair_light = (118, 72, 40, 255)
    skin = (184, 132, 101, 255)
    skin_shadow = (136, 88, 66, 255)
    coat_dark = (48, 36, 34, 255)
    coat_light = (74, 54, 48, 255)

    draw.ellipse([64, 26, 192, 160], fill=hair_dark)
    draw.polygon([(78, 80), (48, 236), (100, 246), (118, 108)], fill=hair_dark)
    draw.polygon([(178, 80), (208, 236), (156, 246), (138, 108)], fill=hair_dark)
    draw.line([(88, 62), (70, 224)], fill=hair_mid, width=6)
    draw.line([(168, 62), (186, 224)], fill=hair_mid, width=6)
    draw.line([(110, 42), (92, 154)], fill=hair_light, width=3)
    draw.line([(146, 42), (164, 154)], fill=hair_light, width=3)

    draw.polygon([(68, 208), (188, 208), (226, 256), (30, 256)], fill=coat_dark)
    draw.polygon([(90, 132), (166, 132), (194, 240), (62, 240)], fill=coat_light)
    draw.polygon([(112, 132), (144, 132), (154, 198), (126, 214), (102, 198)], fill=(140, 44, 30, 255))

    draw.ellipse([90, 54, 166, 142], fill=skin)
    draw.polygon([(96, 116), (160, 116), (170, 172), (128, 198), (86, 172)], fill=skin)
    draw.polygon([(128, 72), (138, 118), (122, 120)], fill=skin_shadow)
    draw.polygon([(104, 100), (120, 96), (122, 102), (108, 104)], fill=(38, 20, 15, 255))
    draw.polygon([(152, 100), (136, 96), (134, 102), (148, 104)], fill=(38, 20, 15, 255))
    draw.ellipse([110, 104, 118, 112], fill=(18, 10, 8, 255))
    draw.ellipse([138, 104, 146, 112], fill=(18, 10, 8, 255))
    draw.line([(112, 160), (145, 155)], fill=(70, 30, 24, 255), width=4)
    draw.line([(112, 161), (128, 166), (145, 156)], fill=(122, 74, 54, 255), width=2)

    draw.polygon([(86, 46), (112, 38), (98, 152), (74, 140)], fill=hair_dark)
    draw.polygon([(170, 46), (144, 38), (158, 152), (182, 140)], fill=hair_dark)
    draw.polygon([(102, 30), (154, 30), (170, 74), (86, 74)], fill=hair_mid)

    draw.rectangle([170, 164, 228, 176], fill=(96, 92, 86, 255))
    draw.rectangle([208, 160, 232, 180], fill=(48, 34, 28, 255))

    img.save(os.path.join(SPRITE_DIR, "rpg_player_portrait.png"))
    print("Created rpg_player_portrait.png")


def create_biome_tiles():
    """Create larger RPG biome tiles used by the open-world reboot."""
    biomes = {
        "grassland": [(32, 88, 42), (52, 132, 60), (176, 142, 68)],
        "forest": [(16, 58, 36), (24, 92, 52), (78, 54, 32)],
        "snow": [(168, 190, 198), (224, 236, 238), (104, 134, 150)],
        "coast": [(20, 86, 110), (42, 138, 160), (194, 166, 92)],
        "mountain": [(70, 72, 76), (116, 112, 104), (180, 176, 160)],
        "volcano": [(52, 18, 14), (132, 42, 18), (238, 92, 26)],
        "badlands": [(116, 58, 28), (174, 92, 42), (226, 158, 74)],
        "corruption": [(42, 16, 50), (92, 28, 104), (196, 82, 212)],
    }
    for name, colors in biomes.items():
        img = Image.new("RGBA", (128, 128), colors[0] + (255,))
        draw = ImageDraw.Draw(img)
        for y in range(0, 128, 8):
            wave = int(math.sin(y * 0.17) * 12)
            draw.line([(0, y), (128, y + wave)], fill=colors[1] + (255,), width=3)
        for i in range(42):
            x = (i * 37) % 128
            y = (i * 53) % 128
            r = 2 + (i % 5)
            draw.ellipse([x - r, y - r, x + r, y + r], fill=colors[2] + (210,))
        img.save(os.path.join(SPRITE_DIR, f"biome_{name}.png"))
        print(f"Created biome_{name}.png")


def create_boss_emblems():
    """Create region boss emblems for journal/map usage."""
    bosses = {
        "toll_mare": ((92, 54, 30), (222, 174, 86)),
        "whiteout_stallion": ((210, 226, 232), (80, 122, 148)),
        "reef_kelpie": ((22, 98, 118), (92, 212, 220)),
        "glassback_colossus": ((74, 78, 86), (190, 198, 210)),
        "cinder_mare": ((108, 28, 18), (250, 82, 24)),
        "pale_herd_king": ((170, 118, 70), (244, 210, 130)),
        "last_horse": ((48, 16, 58), (220, 74, 230)),
    }
    for name, palette in bosses.items():
        base, accent = palette
        img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        draw.ellipse([8, 8, 120, 120], fill=base + (255,), outline=accent + (255,), width=5)
        draw.polygon([(36, 82), (52, 40), (78, 34), (98, 58), (90, 88), (60, 98)], fill=accent + (255,))
        draw.polygon([(76, 28), (86, 10), (92, 34)], fill=accent + (255,))
        draw.polygon([(48, 36), (38, 16), (36, 44)], fill=accent + (255,))
        draw.ellipse([62, 56, 72, 66], fill=(10, 8, 6, 255))
        draw.line([(48, 88), (92, 84)], fill=(10, 8, 6, 255), width=4)
        img.save(os.path.join(SPRITE_DIR, f"boss_{name}.png"))
        print(f"Created boss_{name}.png")


def main():
    create_directory()
    create_player_sprite()
    create_horse_sprite()
    create_bullet_sprite()
    create_powerup_sprites()
    create_explosion_animation()
    create_grass_background()
    create_icon()
    create_rpg_portrait()
    create_biome_tiles()
    create_boss_emblems()
    print("\nAll sprites created successfully!")


if __name__ == "__main__":
    main()
