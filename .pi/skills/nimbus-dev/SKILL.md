---
name: nimbus-dev
description: 按用户需求为 Nimbus（nimbus.sh 云服务器工具箱）新增功能或修复问题，包含仓库结构、编码约定、本地/远程测试方法和发版清单（版本号、CHANGELOG、文档、提交）。在 nimbus 仓库里做任何功能开发、bug 修复、菜单或新机开荒调整时使用。
---

# Nimbus 功能开发与修复

用户的需求写在本 skill 后面（`/skill:nimbus-dev <需求>`）。没写需求就先问。

## 仓库速览

| 路径 | 说明 |
|---|---|
| `nimbus.sh` | 主脚本，约 7600 行，所有功能都在这里。用户机器上是 `~/nimbus.sh` 和 `/usr/local/bin/nb` |
| `res/config/` | 运行时从 GitHub main 下载的配置（fail2ban、tmux、blesh） |
| `TG-*.sh`、`Limiting_Shut_down1.sh` | 部署到服务器上的独立脚本 |
| `CHANGELOG.md` | 更新日志，「脚本更新」菜单会读取最后 30 行 |
| `README.md`、`docs/{wizard,features,commands,faq}.md` | 文档 |
| `.pi/upstream-sync.md` | 上游同步记录（归 `nimbus-upstream-sync` skill 管） |

`nimbus.sh` 里的关键位置（行号会变，用 ffgrep 搜函数名）：
- 通用函数：`install` / `remove`（包管理器适配）、`break_end`、`root_use`、`nb_download`（GitHub 下载，自动走代理）、`nb_in_cn`、`nb_service_active`、`nb_is_pve`
- 菜单：主菜单在文件末尾的 `nimbus_home` 循环；`linux_tools`（基础工具）、`linux_Settings`（系统工具）
- 新机开荒：`nb_wz_status`（每一步的状态检测）、`nb_wizard`（`keys` / `titles` / `funcs` / `opts` 四个数组 + 阶段标题的编号）
- 命令行：文件末尾的 `case $1 in` 分发，帮助文本在 `nb_help`
- 自更新：`nb_self_update`、`nimbus_update`；`sh_v="x.y.z"` 在第 4 行

## 编码约定

- bash，缩进用 **Tab**；新函数用 `nb_` 前缀，局部变量一律 `local`。
- 颜色变量：`gl_lv` 成功、`gl_huang` 提示/警告、`gl_hong` 错误、`gl_hui` 次要说明、`gl_cyan` 编号、`gl_bai` 复位。
- 子菜单写法参考 `tmux_setup`、`blesh_setup`、`komari_agent_menu`：`clear` → 标题 → `------` 分隔线 → 当前状态 → 选项 → `read -r -e -p "请输入你的选择: "`。
- 双列菜单的左列要**按显示宽度**补齐（中文算 2 列），和同一菜单的其他行一致，一般是 35 列；新机开荒的标题固定 35 列。`scripts/check.py` 会检查。
- **GitHub 下载一律用 `nb_download <不带 https:// 的路径> <目标文件>`**：国内 / IPv6 模式先走 `gh_proxy`，失败了依次试直连和镜像。不要直接 `curl github.com`。
- 多发行版：Debian / Ubuntu / RHEL 系 / Alpine。包名不一样的要分开处理（例如 `xz-utils` 和 `xz`）。注意 `install` 在 dnf/yum 上会先做全量 `update`，非必要不调用。
- 改系统配置之前先备份（`*.bak.$(date +%Y%m%d-%H%M%S)`），并且要幂等，重复执行结果相同。写入用户文件的内容用 `# >>> nimbus xxx >>>` / `# <<< nimbus xxx <<<` 标记块包起来，方便检测和移除。
- 涉及 SSH、防火墙、fail2ban 这类可能把人锁在外面的操作：先放行、再修改、最后校验，失败了要还原，并提示「保持当前会话」。
- 依赖 `res/` 下文件的功能要 **push 到 main 之后才能在服务器上用**（脚本运行时从 GitHub 下载）。
- 不加遥测、广告和外部宣传链接。

## 工作流程

1. **弄清需求**：先 ffgrep 找到相关函数，读懂现有实现。需求有歧义、或者有多种合理做法时，用 `ask_user_question` 一次把问题问完。
2. **实现**：按上面的约定写。新功能想清楚放在哪些入口：子菜单、系统工具编号、新机开荒步骤、`nb <命令>`。每个入口都要接上。
3. **新增新机开荒步骤时**，四个数组要同步插入，`nb_wz_status` 加上状态检测；插入位置之后的阶段标题编号（`case $((i + 1))` 里的数字）要顺延；`docs/wizard.md` 的表格和 `docs/features.md` 里「开荒 N」的引用也要一起改。
4. **测试**（见下一节），至少要过 `scripts/check.py`。
5. **发版**（见最后一节），然后汇报。

## 测试方法

本机是 Fedora 桌面，**不是**目标环境。**不要在本机用 root 或 sudo 直接跑 `nimbus.sh`**：它会自安装到 `/usr/local/bin/nb`，菜单里的操作也会改动系统。

- 静态检查：`python3 .pi/skills/nimbus-dev/scripts/check.py`，检查 bash 语法、四处版本号是否一致、开荒数组、菜单对齐。
- **函数级沙箱测试**（推荐）：把要测的函数和依赖用 sed 抽出来，在临时 HOME 里运行。不用的依赖写成桩函数，需要下载 `res/` 文件时用本地文件替代 `nb_download`：
  ```bash
  { sed -n '/^gl_hui=/,/^gl_cyan=/p' nimbus.sh; sed -n '/^nb_download() {/,/^}/p' nimbus.sh; sed -n '/^目标函数() {/,/^}/p' nimbus.sh; } > /tmp/fn.sh
  HOME=/tmp/fakehome bash -c 'source /tmp/fn.sh; install(){ echo "would install $*"; }; 目标函数'
  ```
- 菜单渲染：同样抽出相关函数，把 `clear`、`root_use` 写成桩，用 `echo 0 | 菜单函数` 看输出。
- 需要交互式终端时（例如 ble.sh 这类行编辑器）：本机用 `python3 -c 'import pty…'` 开 pty 发按键；Debian 服务器上有 `script`：`( sleep 5; printf '命令\r'; sleep 3; printf 'exit\r' ) | script -qfc "bash -i" /dev/null`。回车要发 `\r`。
- **远程实测**（真正改系统的功能必须做）：用 codemode 调 `mcp__termius__*`。先 `hosts` 列出机器，**用 `ask_user_question` 确认在哪几台测**：OpenWrt 路由器不是目标，用户明确排除的机器也不碰。注意事项：
  - 大多是 Debian 13，用户多为 root，有的不是。国内机直连 GitHub 不通，要走 `https://ghfast.top/`。
  - 部分机器经跳板连接，单次约 40 秒；多台用 `Promise.allSettled` 并行，codemode 超时设到 300 秒以上。
  - 本地改过的脚本先传到远端 `/tmp` 测试（base64 编码后 `echo … | base64 -d`），不要依赖还没 push 的 GitHub 文件。
  - 改 SSH 端口、防火墙、重启这类危险操作，测之前要用户明确同意。

## 发版清单

每次面向用户的改动都要发一个版本（只改文档的除外）：

1. 版本号：修复递增 patch，新功能视大小递增 minor 或 patch。要改的地方：`nimbus.sh` 第 4 行 `sh_v`、README 徽章 `version-x.y.z-`、README 菜单预览 `v x.y.z`、CHANGELOG 新条目。
2. `CHANGELOG.md` 末尾追加，格式和已有条目一致：
   ```
   2026-10-27   v1.2.6
   一句话概述。
   1.具体改动（用户能感知到的行为、原因、入口）。
   2.……
   ------------------------
   ```
3. 文档：入口和编号写进 `docs/features.md`、`docs/commands.md`、`docs/wizard.md`，README 特性列表视情况更新。
4. `python3 .pi/skills/nimbus-dev/scripts/check.py` 通过。
5. 提交信息用中文，一句话概括并带版本号，例如 `新增 xxx：入口…，要点…（v1.2.6）`。
6. **push 前先确认**：用户在需求里说了要推送才直接推，否则提交后问一句。已部署的服务器用 `nb self-update` 更新。

## 汇报

说清楚改了什么、入口在哪、测了什么（哪些是本地沙箱，哪些是真机），以及还没推送或需要用户手动做的事。
