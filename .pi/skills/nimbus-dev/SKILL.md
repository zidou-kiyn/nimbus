---
name: nimbus-dev
description: 按用户需求为 Nimbus（nimbus.sh 云服务器工具箱）新增功能或修复问题，包含仓库结构、编码约定、本地/远程测试方法和发版清单（版本号、CHANGELOG、文档、提交）。在 nimbus 仓库里做任何功能开发、bug 修复、菜单或新机开荒调整时使用。
---

# Nimbus 功能开发与修复

用户的需求写在本 skill 后面（`/skill:nimbus-dev <需求>`）。没写需求就先问。所有功能都在 `nimbus.sh` 一个文件里，用 ffgrep 搜函数名定位。

| 任务 | 读 / 运行 |
|---|---|
| 找文件、找函数入口、cnb 镜像同步 | `references/repo.md` |
| 写代码前（每次都读） | `references/conventions.md` |
| 新增或调整新机开荒步骤 | `references/repo.md`「新增新机开荒步骤」 |
| 测试（本地沙箱、远程真机） | `references/testing.md` |
| 发版（版本号、CHANGELOG、文档、提交） | `references/release.md` |
| 静态检查 | `python3 .pi/skills/nimbus-dev/scripts/check.py` |

## 工作流程

1. **弄清需求**：ffgrep 找到相关函数，读懂现有实现。有歧义或多种合理做法时，用 `ask_user_question` 一次问完。
2. **实现**：按 `references/conventions.md` 写，所有入口（子菜单、系统工具编号、开荒步骤、`nb <命令>`）都要接上。
3. **测试**：按 `references/testing.md`，至少过 `scripts/check.py`；真正改系统的功能要真机测。
4. **发版**：按 `references/release.md`。
5. **汇报**：改了什么、入口在哪、测了什么（哪些是本地沙箱，哪些是真机），以及还没推送或需要用户手动做的事。

## 硬规则

- **不要在本机用 root / sudo 跑 `nimbus.sh`**：本机是 Fedora 桌面，脚本会自安装并改系统。
- GitHub 下载一律走 `nb_download`，不要直接 `curl github.com`。
- 改系统配置先备份、要幂等；SSH / 防火墙 / fail2ban 先放行、再修改、最后校验，失败还原。
- 真机测试先问在哪几台测；改 SSH 端口、防火墙、重启前要用户明确同意。
- 面向用户的改动都要发版；push 前先确认（用户在需求里说了要推送除外）。
- 不加遥测、广告和外部宣传链接。
