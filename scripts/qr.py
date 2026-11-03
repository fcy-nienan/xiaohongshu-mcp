"""无窗口获取小红书登录二维码。

调用本地 MCP 服务的 get_login_qrcode 工具，把二维码存成 PNG，
并尽量用 zxing-cpp + qrcode 重新放大一版，方便手机扫。

用法： .venv/bin/python scripts/qr.py [输出目录，默认 data/]
"""

import base64
import os
import sys

import requests

URL = "http://127.0.0.1:18060/mcp"
HEADERS = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"}


def main() -> int:
    outdir = sys.argv[1] if len(sys.argv) > 1 else "data"
    os.makedirs(outdir, exist_ok=True)

    s = requests.Session()
    r = s.post(
        URL,
        headers=HEADERS,
        json={
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2025-06-18",
                "capabilities": {},
                "clientInfo": {"name": "qr", "version": "1"},
            },
        },
        timeout=60,
    )
    sid = r.headers.get("Mcp-Session-Id")
    if not sid:
        print("连接 MCP 失败，服务是否已启动？")
        print(r.text[:300])
        return 1

    h = dict(HEADERS, **{"Mcp-Session-Id": sid})
    s.post(URL, headers=h, json={"jsonrpc": "2.0", "method": "notifications/initialized"}, timeout=30)
    r = s.post(
        URL,
        headers=h,
        json={
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {"name": "get_login_qrcode", "arguments": {}},
        },
        timeout=180,
    )

    small = os.path.join(outdir, "login-qr.png")
    for c in r.json().get("result", {}).get("content", []):
        if c.get("type") == "image":
            open(small, "wb").write(base64.b64decode(c["data"].split(",")[-1]))
            print("二维码已保存:", small)
        elif c.get("type") == "text":
            print(c.get("text", "").strip())

    big = os.path.join(outdir, "login-qr-big.png")
    try:
        import qrcode
        import zxingcpp
        from PIL import Image

        res = zxingcpp.read_barcodes(Image.open(small).convert("RGB"))
        if res:
            q = qrcode.QRCode(border=2, box_size=12)
            q.add_data(res[0].text)
            q.make(fit=True)
            q.make_image(fill_color="black", back_color="white").save(big)
            print("放大版二维码:", big)
    except Exception as e:  # 依赖缺失时不影响主流程
        print("（未生成放大版：%s）" % e)

    return 0


if __name__ == "__main__":
    sys.exit(main())
