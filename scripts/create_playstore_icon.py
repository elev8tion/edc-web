#!/usr/bin/env python3
"""
Create a 512x512 Play Store icon for Everyday Christian app
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

def create_playstore_icon():
    # Create a 512x512 image with RGBA
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Define colors
    purple = (138, 43, 226)  # Blue-violet
    blue = (65, 105, 225)     # Royal blue
    gold = (218, 165, 32)     # Golden rod
    white = (255, 255, 255)

    # Create gradient background
    for y in range(size):
        # Interpolate between purple and blue
        ratio = y / size
        r = int(purple[0] * (1 - ratio) + blue[0] * ratio)
        g = int(purple[1] * (1 - ratio) + blue[1] * ratio)
        b = int(purple[2] * (1 - ratio) + blue[2] * ratio)
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))

    # Draw rounded rectangle border (golden)
    border_width = 8
    corner_radius = 80

    # Outer rounded rectangle
    draw.rounded_rectangle(
        [(border_width, border_width), (size-border_width, size-border_width)],
        radius=corner_radius,
        outline=gold,
        width=border_width
    )

    # Draw sunrise/sun icon
    sun_center_x = size // 2
    sun_center_y = 140
    sun_radius = 35

    # Draw sun rays
    num_rays = 16
    for i in range(num_rays):
        angle = (i * 360 / num_rays) * math.pi / 180
        # Only draw upper half rays (sunrise effect)
        if angle <= math.pi:
            inner_radius = sun_radius + 10
            outer_radius = sun_radius + 30
            x1 = sun_center_x + inner_radius * math.cos(angle)
            y1 = sun_center_y + inner_radius * math.sin(angle)
            x2 = sun_center_x + outer_radius * math.cos(angle)
            y2 = sun_center_y + outer_radius * math.sin(angle)
            draw.line([(x1, y1), (x2, y2)], fill=gold, width=3)

    # Draw semi-circle for sun
    draw.pieslice(
        [(sun_center_x - sun_radius, sun_center_y - sun_radius),
         (sun_center_x + sun_radius, sun_center_y + sun_radius)],
        start=180, end=360,
        fill=gold
    )

    # Draw horizon line
    horizon_y = sun_center_y
    draw.line([(80, horizon_y), (200, horizon_y)], fill=gold, width=3)
    draw.line([(312, horizon_y), (432, horizon_y)], fill=gold, width=3)

    # Draw sun rays inside semi-circle
    for i in range(8):
        angle = 180 + (i * 180 / 8)
        angle_rad = angle * math.pi / 180
        x = sun_center_x + (sun_radius - 5) * math.cos(angle_rad)
        y = sun_center_y + (sun_radius - 5) * math.sin(angle_rad)
        draw.line([(sun_center_x, sun_center_y), (x, y)], fill=white, width=2)

    # Add text - we'll use a basic font since we don't have custom fonts
    try:
        # Try to use a better font if available
        font_regular = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
        font_bold = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 72)
    except:
        # Fallback to default font
        font_regular = ImageFont.load_default()
        font_bold = ImageFont.load_default()

    # Draw "EVERYDAY" text
    text1 = "EVERYDAY"
    bbox1 = draw.textbbox((0, 0), text1, font=font_regular)
    text1_width = bbox1[2] - bbox1[0]
    text1_x = (size - text1_width) // 2
    text1_y = 200

    # Draw horizontal lines around EVERYDAY
    line_y = text1_y + 25
    draw.line([(50, line_y), (150, line_y)], fill=white, width=2)
    draw.line([(362, line_y), (462, line_y)], fill=white, width=2)

    draw.text((text1_x, text1_y), text1, fill=white, font=font_regular)

    # Draw "CHRISTIAN" text (bigger and bolder)
    text2 = "CHRISTIAN"
    bbox2 = draw.textbbox((0, 0), text2, font=font_bold)
    text2_width = bbox2[2] - bbox2[0]
    text2_x = (size - text2_width) // 2
    text2_y = 260
    draw.text((text2_x, text2_y), text2, fill=white, font=font_bold)

    # Draw open book icon at the bottom
    book_center_x = size // 2
    book_y = 380
    book_width = 100
    book_height = 60

    # Left page
    left_points = [
        (book_center_x - book_width//2, book_y),
        (book_center_x - 5, book_y - 20),
        (book_center_x - 5, book_y + book_height - 20),
        (book_center_x - book_width//2, book_y + book_height)
    ]
    draw.polygon(left_points, outline=gold, width=3)

    # Right page
    right_points = [
        (book_center_x + book_width//2, book_y),
        (book_center_x + 5, book_y - 20),
        (book_center_x + 5, book_y + book_height - 20),
        (book_center_x + book_width//2, book_y + book_height)
    ]
    draw.polygon(right_points, outline=gold, width=3)

    # Book spine
    draw.line([(book_center_x, book_y - 20), (book_center_x, book_y + book_height - 20)],
              fill=gold, width=3)

    # Add subtle inner glow effect
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.rounded_rectangle(
        [(20, 20), (size-20, size-20)],
        radius=corner_radius-10,
        fill=(255, 255, 255, 30)
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=20))
    img = Image.alpha_composite(img, glow)

    return img

if __name__ == "__main__":
    print("Creating Play Store icon...")
    icon = create_playstore_icon()

    # Save the icon
    output_path = "playstore_icon_512.png"
    icon.save(output_path, "PNG", quality=100)
    print(f"Icon saved as {output_path}")

    # Also save in app_store_assets if the directory exists
    if os.path.exists("app_store_assets/icons"):
        asset_path = "app_store_assets/icons/playstore_icon_512_new.png"
        icon.save(asset_path, "PNG", quality=100)
        print(f"Also saved as {asset_path}")