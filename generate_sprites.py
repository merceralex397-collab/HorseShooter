#!/usr/bin/env python3
"""
Sprite generator for HorseShooter game
Creates pixel art sprites programmatically using PIL
Slapstick comedy style - exaggerated, cartoonish, non-violent
"""

from PIL import Image, ImageDraw
import os
import math


def create_directory():
    """Create assets directory if it doesn't exist"""
    os.makedirs("/home/rowan/horseshooter/HorseShooter/assets/sprites", exist_ok=True)


def draw_pixel_rect(draw, x, y, w, h, color):
    """Draw a rectangle in pixel-art style"""
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=color)


def create_player_sprite():
    """Create a cartoon cowboy/player character (32x32)"""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Body (blue shirt)
    draw_pixel_rect(draw, 12, 14, 8, 10, (65, 105, 225))  # Royal blue
    # Pants (jeans)
    draw_pixel_rect(draw, 12, 24, 8, 6, (70, 130, 180))  # Steel blue
    # Legs
    draw_pixel_rect(draw, 12, 28, 3, 4, (70, 130, 180))
    draw_pixel_rect(draw, 17, 28, 3, 4, (70, 130, 180))
    # Boots
    draw_pixel_rect(draw, 11, 30, 4, 2, (139, 69, 19))  # Brown
    draw_pixel_rect(draw, 17, 30, 4, 2, (139, 69, 19))
    # Head (skin tone)
    draw_pixel_rect(draw, 13, 8, 6, 6, (255, 220, 177))  # Light skin
    # Hat (cowboy hat - tan)
    draw_pixel_rect(draw, 10, 4, 12, 3, (210, 180, 140))  # Tan
    draw_pixel_rect(draw, 12, 6, 8, 3, (210, 180, 140))
    draw_pixel_rect(draw, 13, 3, 6, 2, (210, 180, 140))
    # Hat brim
    draw_pixel_rect(draw, 8, 5, 4, 2, (210, 180, 140))
    draw_pixel_rect(draw, 20, 5, 4, 2, (210, 180, 140))
    # Eyes (cartoon style - black dots)
    draw_pixel_rect(draw, 14, 10, 1, 2, (0, 0, 0))
    draw_pixel_rect(draw, 17, 10, 1, 2, (0, 0, 0))
    # Smile
    draw_pixel_rect(draw, 15, 12, 2, 1, (0, 0, 0))
    # Arms holding gun
    draw_pixel_rect(draw, 20, 16, 4, 2, (255, 220, 177))
    draw_pixel_rect(draw, 24, 15, 3, 4, (139, 69, 19))  # Gun handle
    draw_pixel_rect(draw, 27, 16, 4, 2, (64, 64, 64))  # Gun barrel

    img.save("/home/rowan/horseshooter/HorseShooter/assets/sprites/player.png")
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

        filename = f"/home/rowan/horseshooter/HorseShooter/assets/sprites/horse_{i}.png"
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

    img.save("/home/rowan/horseshooter/HorseShooter/assets/sprites/bullet.png")
    print("Created bullet.png")


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

        filename = f"/home/rowan/horseshooter/HorseShooter/assets/sprites/explosion_{frame}.png"
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

    img.save("/home/rowan/horseshooter/HorseShooter/assets/sprites/grass.png")
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

    img.save("/home/rowan/horseshooter/HorseShooter/assets/sprites/icon.png")
    print("Created icon.png")


def main():
    create_directory()
    create_player_sprite()
    create_horse_sprite()
    create_bullet_sprite()
    create_explosion_animation()
    create_grass_background()
    create_icon()
    print("\nAll sprites created successfully!")


if __name__ == "__main__":
    main()
