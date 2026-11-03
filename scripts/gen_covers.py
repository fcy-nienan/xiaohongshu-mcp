"""生成小红书封面（纯文字，无需设计工具）。

用法:
  .venv/bin/python scripts/gen_covers.py                 # 生成 Cloudflare 三张示例封面
  .venv/bin/python scripts/gen_covers.py --title "第一行|第二行" \
      --kicker "AWS · 出海" --footer "以官网当期为准" --out assets/covers/cover-aws.png
输出目录默认 assets/covers/（1080x1440）
"""

import argparse
import os

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1440
OUT = "assets/covers"

# 字体按平台优先级回退：WSL 用 Windows 字体，Linux/macOS 用系统自带中文字体
BOLD = None
REG = None

_BOLD_CANDIDATES = [
    "/mnt/c/Windows/Fonts/msyhbd.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc",
    "/System/Library/Fonts/PingFang.ttc",
    "/Library/Fonts/Arial Unicode.ttf",
]
_REG_CANDIDATES = [
    "/mnt/c/Windows/Fonts/msyh.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
    "/System/Library/Fonts/PingFang.ttc",
    "/Library/Fonts/Arial Unicode.ttf",
]


def _pick_font(candidates, label):
    for p in candidates:
        if os.path.exists(p):
            return p
    raise SystemExit(
        f"找不到{label}中文字体，请安装 fonts-noto-cjk，"
        f"或用环境变量指定（当前候选：{', '.join(candidates)}）"
    )

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


def _hex_rgb(s):
    s = s.lstrip("#")
    if len(s) != 6:
        raise SystemExit("--accent 需要形如 #FF9900 的 6 位十六进制")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def generic_cover(title_lines, kicker="", footer_lines=None, accent="#FF9900", out="assets/covers/cover-custom.png", note="", subtitle=""):
    """通用封面：左侧强调色竖条 + 顶部小字 + 大标题 + 底部说明。"""
    global BOLD, REG
    if not BOLD:
        BOLD = _pick_font(_BOLD_CANDIDATES, "粗体")
        REG = _pick_font(_REG_CANDIDATES, "常规")

    ac = _hex_rgb(accent)
    footer_lines = footer_lines or []

    img = Image.new("RGB", (W, H), (16, 18, 23))
    d = ImageDraw.Draw(img)

    # 背景轻微渐变，避免死板纯色
    for i in range(H):
        t = i / H
        d.line([0, i, W, i], fill=(int(16 + 8 * t), int(18 + 9 * t), int(23 + 12 * t)))

    d.rectangle([0, 0, 24, H], fill=ac)

    y = 130
    if kicker:
        d.text((88, y), kicker, font=font(REG, 44), fill=(150, 158, 172))
        y += 110

    size = 128 if len(title_lines) <= 2 else (108 if len(title_lines) == 3 else 92)
    f = font(BOLD, size)
    y += 30
    for line in title_lines:
        for seg in wrap(d, line, f, W - 176):
            d.text((88, y), seg, font=f, fill=(255, 255, 255))
            y += int(size * 1.32)

    d.rectangle([88, y + 30, 88 + 200, y + 40], fill=ac)

    if subtitle:
        sy = y + 92
        for seg in wrap(d, subtitle, font(REG, 50), W - 176):
            d.text((88, sy), seg, font=font(REG, 50), fill=(160, 168, 182))
            sy += 74

    fy = 1180
    for line in footer_lines:
        d.text((88, fy), line, font=font(REG, 44), fill=(150, 158, 172))
        fy += 78

    d.text((88, 1360), note, font=font(REG, 26), fill=(96, 102, 114))
    img.save(out)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="生成小红书封面 PNG（1080x1440）")
    parser.add_argument("--title", help="主标题，多行用 | 分隔，例如 '出海独立站|AWS 怎么起步'")
    parser.add_argument("--kicker", default="", help="顶部小字")
    parser.add_argument("--footer", default="", help="底部说明，多行用 | 分隔")
    parser.add_argument("--accent", default="#FF9900", help="强调色，十六进制，默认 AWS 橙")
    parser.add_argument("--note", default="", help="右下角小字，例如 '以官网当期为准'")
    parser.add_argument("--subtitle", default="", help="标题下方的副标题")
    parser.add_argument("--out", default="assets/covers/cover-custom.png", help="输出路径")
    args = parser.parse_args()

    BOLD = _pick_font(_BOLD_CANDIDATES, "粗体")
    REG = _pick_font(_REG_CANDIDATES, "常规")

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)

    if args.title:
        generic_cover(
            title_lines=[s for s in args.title.split("|") if s],
            kicker=args.kicker,
            footer_lines=[s for s in args.footer.split("|") if s],
            accent=args.accent,
            out=args.out,
            note=args.note,
            subtitle=args.subtitle,
        )
        print("saved:", args.out)
    else:
        os.makedirs(OUT, exist_ok=True)
        cover_a()
        cover_b()
        cover_c()
        print("saved:", ", ".join(os.path.join(OUT, f) for f in sorted(os.listdir(OUT))))
