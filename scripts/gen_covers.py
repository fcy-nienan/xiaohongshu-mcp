"""生成小红书封面（纯文字，无需设计工具）。

用法: .venv/bin/python scripts/gen_covers.py
输出: assets/covers/cover-a.png / cover-b.png / cover-c.png（1080x1440）
"""

import os

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1440
BOLD = "/mnt/c/Windows/Fonts/msyhbd.ttc"
REG = "/mnt/c/Windows/Fonts/msyh.ttc"
OUT = "assets/covers"

ORANGE = (246, 130, 31)  # Cloudflare 橙
DARK = (20, 21, 24)
WHITE = (255, 255, 255)
GRAY = (150, 152, 158)


def font(path, size):
    return ImageFont.truetype(path, size)


def wrap(draw, text, fnt, max_w):
    lines, line = [], ""
    for ch in text:
        if draw.textlength(line + ch, font=fnt) <= max_w:
            line += ch
        else:
            lines.append(line)
            line = ch
    if line:
        lines.append(line)
    return lines


def cover_a():
    img = Image.new("RGB", (W, H), DARK)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 26, H], fill=ORANGE)

    d.text((96, 150), "CLOUDFLARE", font=font(BOLD, 64), fill=ORANGE)
    d.text((96, 240), "FREE TIER", font=font(BOLD, 40), fill=GRAY)

    f = font(BOLD, 150)
    y = 420
    for line in ["Cloudflare", "免费额度", "有多香"]:
        d.text((96, y), line, font=f, fill=WHITE)
        y += 190

    d.rectangle([96, 1090, 300, 1100], fill=ORANGE)
    d.text((96, 1140), "个人站 / 小工具 / 副业", font=font(REG, 52), fill=GRAY)
    d.text((96, 1210), "能覆盖 80% 的需求", font=font(REG, 52), fill=GRAY)
    img.save(os.path.join(OUT, "cover-a.png"))


def cover_b():
    img = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, 430], fill=ORANGE)

    d.text((80, 110), "Cloudflare", font=font(BOLD, 96), fill=WHITE)
    d.text((80, 240), "免费额度清单", font=font(BOLD, 108), fill=WHITE)
    d.text((84, 370), "0 成本也能很能打", font=font(REG, 44), fill=(255, 236, 220))

    items = [
        ("01", "CDN 加速", "流量不额外收费"),
        ("02", "SSL 证书", "自动签发续期"),
        ("03", "DDoS 防护", "免费版就有"),
        ("04", "Workers", "每天 10 万次请求"),
        ("05", "R2 存储", "10G + 出网免费"),
        ("06", "Tunnel", "内网穿透不开端口"),
    ]
    y = 520
    for idx, (num, name, desc) in enumerate(items):
        d.text((80, y + 6), num, font=font(BOLD, 46), fill=ORANGE)
        d.text((170, y), name, font=font(BOLD, 62), fill=DARK)
        d.text((170, y + 76), desc, font=font(REG, 40), fill=(110, 112, 118))
        if idx < len(items) - 1:
            d.line([80, y + 158, W - 80, y + 158], fill=(235, 236, 238), width=2)
        y += 148

    d.text((80, 1404), "以官网当期额度为准", font=font(REG, 30), fill=GRAY)
    img.save(os.path.join(OUT, "cover-b.png"))


def cover_c():
    img = Image.new("RGB", (W, H), (10, 18, 35))
    d = ImageDraw.Draw(img)
    for i in range(H):
        t = i / H
        d.line([0, i, W, i], fill=(int(10 + 18 * t), int(18 + 26 * t), int(35 + 45 * t)))

    d.text((80, 120), "独立开发者の省钱清单", font=font(REG, 46), fill=(150, 170, 200))

    d.text((80, 280), "0", font=font(BOLD, 380), fill=ORANGE)
    d.text((300, 480), "元/月", font=font(BOLD, 90), fill=WHITE)

    f = font(BOLD, 96)
    y = 760
    for line in ["白嫖", "Cloudflare", "能干什么"]:
        d.text((80, y), line, font=f, fill=WHITE)
        y += 120

    d.rectangle([80, 1160, 80 + 220, 1170], fill=ORANGE)
    d.text((80, 1210), "CDN · SSL · Workers · R2 · Tunnel", font=font(REG, 40), fill=(170, 185, 210))
    d.text((80, 1280), "留言告诉我你用它做了什么", font=font(REG, 36), fill=(120, 138, 165))
    img.save(os.path.join(OUT, "cover-c.png"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    cover_a()
    cover_b()
    cover_c()
    print("saved:", ", ".join(os.path.join(OUT, f) for f in sorted(os.listdir(OUT))))
