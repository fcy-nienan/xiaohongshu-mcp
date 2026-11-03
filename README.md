# 小红书 MCP 本地环境（WSL2 源码编译）

基于 [xpzouying/xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) 在 WSL2 里从源码编译部署，
已经接好 opencode（项目级 MCP 配置）。

## 快速开始（新机器）

```bash
git clone -b fcy git@github.com:fcy-nienan/xiaohongshu-mcp.git
cd xiaohongshu-mcp          # 注意：这是仓库根，不是子目录
./scripts/bootstrap.sh      # 1) 装 python 依赖到 .venv
./scripts/build.sh          # 2) 编译 MCP（首次会下载 Go 依赖 + 内置 Chromium 约 148MB）
./scripts/start.sh          # 3) 起服务（127.0.0.1:18060）
./scripts/login.sh          # 4) 扫码登录（WSLg 有窗口；无窗口用 ./scripts/qr.sh）
./scripts/status.sh         # 确认已登录
```

> 登录态不在仓库里（`data/` 被忽略），每台机器都要单独扫码一次。
> 如果机器没有图形界面，用 `./scripts/qr.sh` 生成二维码 PNG 再传出来扫。
> 同一账号不要在多个网页端同时登录，会把这里的会话踢掉（手机 App 不受影响）。

`fcy` 分支是个人使用的快照分支，和 `main`（upstream 镜像）没有共同历史。
本仓库的 `xiaohongshu-mcp/xiaohongshu/login.go` 带一处本地补丁（检测登录超时 30s→90s），
所以不要直接用 `main` 覆盖代码。


## 目录结构

```
.
├── xiaohongshu-mcp/              # 上游源码（sparse checkout，未拉 assets/donate）
│   ├── bin/xiaohongshu-mcp       # MCP 服务（HTTP，默认 18060）
│   └── bin/xiaohongshu-login     # 有窗口扫码登录工具
├── data/
│   ├── cookies.json              # 登录态，可备份/迁移（含会话指纹 seed）
│   ├── home/                     # 服务进程专用 HOME（浏览器缓存等）
│   ├── chrome-profiles/          # post-to-xhs skill 的 Chrome profile
│   └── mcp.pid
├── logs/mcp.log
├── scripts/
│   ├── build.sh                  # 编译（GOPROXY 走 goproxy.cn）
│   ├── start.sh                  # 启动（默认无头，--headed 可看窗口）
│   ├── stop.sh
│   ├── status.sh                 # 进程/端口/MCP 握手/cookies/日志
│   ├── login.sh                  # 有窗口扫码登录（WSLg 显示到 Windows 桌面）
│   └── qr.sh                     # 无窗口登录：生成二维码 PNG 并打开
├── .opencode/skills/post-to-xhs/ # 发帖 skill（已做 WSL 适配）
├── .venv/                        # skill 的 python 依赖（websockets/requests）
└── opencode.json                 # opencode MCP 配置
```

## 常用命令

```bash
# 编译（改了 Go 代码后重跑）
./scripts/build.sh

# 启动（无头）
./scripts/start.sh

# 启动并显示浏览器窗口（WSLg，调试用）
./scripts/start.sh --headed

# 看状态
./scripts/status.sh

# 停止
./scripts/stop.sh

# 有窗口扫码登录（窗口里出二维码，推荐）
./scripts/login.sh

# 无窗口：生成 data/login-qr.png、data/login-qr-big.png 并用图片查看器打开
./scripts/qr.sh

# 生成封面：不带参数出 Cloudflare 三张示例；带 --title 走通用模板
.venv/bin/python scripts/gen_covers.py
.venv/bin/python scripts/gen_covers.py --title "第一行|第二行" --kicker "小字" \
  --subtitle "副标题" --footer "底部说明|第二行" --accent "#FF9900" \
  --note "以官网当期为准" --out assets/covers/cover-custom.png
```

服务地址：`http://127.0.0.1:18060/mcp`，只监听回环地址。

## 登录

两种方式，cookies 都写到 `data/cookies.json`：

1. **有窗口**：`./scripts/login.sh`，浏览器窗口经 WSLg 出现在 Windows 桌面，手机扫码。
2. **无窗口**：服务启动后，让 opencode 调用 MCP 工具 `get_login_qrcode`，返回 base64 二维码图片，扫码即可。
   登录成功后再调 `check_login_status` 确认。

> 同一个账号不要在别的网页端同时登录，否则会把这里的会话踢掉（手机 App 不受影响）。
> 二维码有时效，生成后尽快扫。

## opencode 接入

`opencode.json` 已经写好：

```jsonc
{
  "mcp": {
    "servers": {
      "xiaohongshu": {
        "type": "remote",
        "url": "http://127.0.0.1:18060/mcp",
        "oauth": false
      }
    }
  }
}
```

确认连接：

```bash
opencode mcp list        # 应显示 xiaohongshu connected（前提是服务已启动）
```

工具在 Code Mode 下以 `tools.xiaohongshu.*` 形式提供，共 13 个：登录状态/二维码、图文与视频发布、
推荐列表、搜索、帖子详情、评论与回复、点赞、收藏、用户主页。

## 本地改动

- `xiaohongshu-mcp/xiaohongshu/login.go`：`CheckLoginStatus` 的超时从 30s 调到 **90s**。
  原因：每次工具调用都会新起一个无缓存浏览器实例，探索页首次加载在 WSL 无头环境下要 20–30s，
  30s 会偶发 `context deadline exceeded`（rod panic）。升级上游代码后需要重新打这个补丁。
- `.opencode/skills/post-to-xhs`：Windows 路径改成 Linux（`CHROME_PATH` / Playwright Chromium），
  新增 `scripts/xhs.sh` 统一入口。

## 性能提示

每个 MCP 工具调用都会新起一个浏览器进程，首次页面加载约 20–30 秒，属正常现象；
`list_feeds` 偶发「没有捕获到 feeds 数据」，重试一次通常即可，`search_feeds` 更稳定。

## 发布注意

- 标题 ≤ 20 字（项目建议），正文 ≤ 1000 字
- 本地图片用 **WSL 绝对路径**（源码部署不需要 Docker 的 `/app/images` 映射）
- 图片文件名避免中文，单张别过大
- 视频只支持本地绝对路径，处理时间较长

## 浏览器说明

- MCP 服务**只用项目自带的内置 Chromium**（148.0.7778.215，下载到 `data/home/.cache/xiaohongshu-mcp/`），
  不支持换成系统 Chrome 或 Windows 上的 Chrome；`--no-sandbox` 已由依赖库自动加上。
- 内置浏览器在 WSL 里运行，`--headed` 时窗口通过 WSLg 显示到 Windows 桌面。
- `post-to-xhs` skill 是另一条 CDP 链路，默认用 Playwright 的 Chromium：
  `~/.cache/ms-playwright/chromium-*/chrome-linux64/chrome`。
  想换浏览器就设 `CHROME_PATH`；想连 Windows 上的 Chrome，给它加 `--remote-debugging-port=9222` 后设
  `CDP_HOST=$(ip route show default | awk '{print $3}')`（需 Windows 防火墙放行，不保证可用）。

## skill 用法

详见 `.opencode/skills/post-to-xhs/SKILL.md`。命令统一走包装脚本：

```bash
SKILL=/home/fcy/work/xiaohongshu/.opencode/skills/post-to-xhs
$SKILL/scripts/xhs.sh cdp_publish.py login
$SKILL/scripts/xhs.sh publish_pipeline.py --headless --title-file title.txt --content-file content.txt --images /path/a.jpg
```

skill 的 profile 在 `data/chrome-profiles/default`，和 MCP 服务的 cookies **互不相通**，各自登录一次。

## 常见问题

- **首次启动卡在下载浏览器**：约 148MB，走系统代理下载，慢的话等它跑完；中断后重跑会重新下载（有 SHA256 校验）。
- **登录态失效**：`check_login_status` 返回未登录时，重新跑 `./scripts/login.sh` 或走 `get_login_qrcode`；
  也可以先调 `delete_cookies` 再登录。
- **端口占用**：`ss -ltnp | grep 18060`，用 `PORT=18061 ./scripts/start.sh` 换端口，同时改 `opencode.json` 的 url。
- **看日志**：`tail -f logs/mcp.log`。

## 升级

```bash
cd xiaohongshu-mcp && git pull && cd .. && ./scripts/build.sh && ./scripts/stop.sh && ./scripts/start.sh
```
