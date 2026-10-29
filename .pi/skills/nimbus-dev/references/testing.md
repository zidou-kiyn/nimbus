# 测试方法

本机是 Fedora 桌面，**不是**目标环境。**不要在本机用 root 或 sudo 直接跑 `nimbus.sh`**：它会自安装到 `/usr/local/bin/nb`，菜单里的操作也会改动系统。

## 本地

- 静态检查：`python3 .pi/skills/nimbus-dev/scripts/check.py`，检查 bash 语法、四处版本号是否一致、开荒数组、菜单对齐。
- **函数级沙箱测试**（推荐）：把要测的函数和依赖用 sed 抽出来，在临时 HOME 里运行。不用的依赖写成桩函数，需要下载 `res/` 文件时用本地文件替代 `nb_download`：
  ```bash
  { sed -n '/^gl_hui=/,/^gl_cyan=/p' nimbus.sh; sed -n '/^nb_download() {/,/^}/p' nimbus.sh; sed -n '/^目标函数() {/,/^}/p' nimbus.sh; } > /tmp/fn.sh
  HOME=/tmp/fakehome bash -c 'source /tmp/fn.sh; install(){ echo "would install $*"; }; 目标函数'
  ```
- 菜单渲染：同样抽出相关函数，把 `clear`、`root_use` 写成桩，用 `echo 0 | 菜单函数` 看输出。
- 需要交互式终端时（例如 ble.sh 这类行编辑器）：本机用 `python3 -c 'import pty…'` 开 pty 发按键；Debian 服务器上有 `script`：`( sleep 5; printf '命令\r'; sleep 3; printf 'exit\r' ) | script -qfc "bash -i" /dev/null`。回车要发 `\r`。

## 远程实测

真正改系统的功能必须做。用 codemode 调 `mcp__termius__*`。先 `hosts` 列出机器，**用 `ask_user_question` 确认在哪几台测**：OpenWrt 路由器不是目标，用户明确排除的机器也不碰。

- 大多是 Debian 13，用户多为 root，有的不是。国内机直连 GitHub 不通，要走 `https://ghfast.top/`。
- 部分机器经跳板连接，单次约 40 秒；多台用 `Promise.allSettled` 并行，codemode 超时设到 300 秒以上。
- 本地改过的脚本先传到远端 `/tmp` 测试（base64 编码后 `echo … | base64 -d`），不要依赖还没 push 的 GitHub 文件。
- 改 SSH 端口、防火墙、重启这类危险操作，测之前要用户明确同意。
