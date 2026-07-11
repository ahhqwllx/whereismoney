#!/usr/bin/env python3
"""生成 whereismoney App 图标 —— 简约风格"""
from PIL import Image, ImageDraw, ImageFont
import math
import os

def generate_icon(size=1024):
    """生成简约风格 App 图标"""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 圆角背景（深色 #0f1419）
    radius = size // 5
    bg_color = (15, 20, 25, 255)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=bg_color)

    cx, cy = size // 2, size // 2

    # 主体：简约的上升折线图，象征财务增长
    # 用粗绿色线条画一个从左下到右上的阶梯折线
    line_color = (74, 222, 128, 255)  # #4ADE80 与 App 主题色一致
    line_w = size // 30

    # 折线坐标点（相对于画布）
    points = [
        (0.22, 0.68),  # 起点（左下）
        (0.38, 0.62),  # 第一段
        (0.38, 0.52),  # 上升
        (0.54, 0.52),  # 平移
        (0.54, 0.38),  # 上升
        (0.70, 0.38),  # 平移
        (0.70, 0.22),  # 上升到高点
        (0.82, 0.22),  # 终点
    ]
    abs_points = [(int(p[0]*size), int(p[1]*size)) for p in points]

    # 画折线
    for i in range(len(abs_points)-1):
        draw.line([abs_points[i], abs_points[i+1]], fill=line_color, width=line_w)

    # 在折线端点画圆点
    dot_r = line_w // 2 + 2
    for p in abs_points:
        draw.ellipse([p[0]-dot_r, p[1]-dot_r, p[0]+dot_r, p[1]+dot_r], fill=line_color)

    # 底部：货币符号 ¥（简约半透明）
    try:
        font_size = size // 4
        font = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()

    # ¥ 符号放在右下角，半透明
    yen_text = "¥"
    yen_color = (74, 222, 128, 80)  # 半透明绿
    bbox = draw.textbbox((0, 0), yen_text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = int(size * 0.72) - tw // 2
    ty = int(size * 0.72) - th // 2
    draw.text((tx, ty), yen_text, font=font, fill=yen_color)

    return img


def generate_all_sizes():
    """生成所有需要的图标尺寸"""
    base = generate_icon(1024)

    icon_dir = os.path.join(os.path.dirname(__file__), "whereismoney", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(icon_dir, exist_ok=True)

    # iOS 现代图标只需要一个 1024x1024 的图标
    icon_path = os.path.join(icon_dir, "icon_1024.png")
    base.save(icon_path, "PNG")
    print(f"✅ 生成 1024x1024 图标: {icon_path}")

    # 更新 Contents.json
    contents = {
        "images": [
            {
                "filename": "icon_1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    import json
    contents_path = os.path.join(icon_dir, "Contents.json")
    with open(contents_path, "w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2)
    print(f"✅ 更新 Contents.json: {contents_path}")

    return base


if __name__ == "__main__":
    img = generate_all_sizes()
    # 保存一份预览到根目录
    preview = os.path.join(os.path.dirname(__file__), "icon_preview.png")
    img.save(preview, "PNG")
    print(f"✅ 预览图: {preview}")
