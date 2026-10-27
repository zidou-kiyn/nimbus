# 🧰 功能详解

- [主菜单](#主菜单)
- [系统工具](#系统工具)
- [重装系统](#重装系统)
- [优化 DNS](#优化-dns)
- [BBRv3 加速](#bbrv3-加速)
- [自动安装安全更新](#自动安装安全更新)
- [ble.sh 命令行增强](#blesh-命令行增强)
- [TG-bot 监控预警](#tg-bot-监控预警)
- [应用部署](#应用部署)
- [文件与配置位置](#文件与配置位置)

## 主菜单

| # | 模块 | 内容 |
|:---:|---|---|
| 1 | 系统信息 | CPU、内存、磁盘、流量、地理位置、运行时长等 |
| 2 / 3 | 系统更新 / 清理 | 自动识别 apt / dnf / yum / apk / pacman 等包管理器 |
| 4 | 基础工具 | curl、wget、htop、btop、tmux、ffmpeg、vim、git 等的安装与卸载；realm 端口转发（xwPF） |
| 5 | BBRv3 加速 | 见 [下文](#bbrv3-加速) |
| 6 | Docker 管理 | 安装与换源、容器 / 镜像 / 网络 / 卷管理、IPv6、备份 / 迁移 / 还原 |
| 7 | 测试脚本 | 流媒体解锁、IP 质量、三网回程路由、测速、yabs / GB5 / 融合怪 |
| 8 | 系统工具 | 见 [下文](#系统工具) |
| 9 | 新机开荒 | 见 [新机开荒](wizard.md) |
| 00 | 脚本更新 | 手动更新，或开启每天凌晨 2 点自动更新 |

## 系统工具

| 分组 | 编号与功能 |
|---|---|
| 账号与登录 | 1 修改密码 · 2 密码登录模式 · 3 密钥登录模式 · 4 禁用 root 并新建账户 · 5 用户管理 · 6 用户 / 密码生成器 |
| 网络 | 7 开放所有端口 · 8 修改 SSH 端口 · 9 优化 DNS · 10 IPv4 / IPv6 优先 · 11 端口占用 · 12 防火墙 · 13 hosts 解析 · 14 网卡管理 |
| 系统 | 15 重装系统 · 16 虚拟内存 · 17 时区 · 18 BBRv3 · 19 主机名 · 20 更新源 · 21 定时任务 · 22 系统语言 · 23 环境变量 |
| 安全与运维 | 24 fail2ban · 25 限流自动关机 · 26 TG-bot 监控 · 27 命令行美化 · 28 备份与恢复 · 29 硬盘分区 · 30 命令历史 · 31 日志管理 · 32 自动安装安全更新 · 33 ble.sh 命令行增强 |
| 其他 | 99 重启服务器 · 101 命令行用法 · 102 卸载 Nimbus |

## 重装系统

基于 [leitbogioro/Tools InstallNET](https://github.com/leitbogioro/Tools)，使用各发行版的官方安装器。

打开菜单时先下载重装脚本：InstallNET 依次尝试 GitHub 直连和代理；都失败时（如没有国际出口的国内机器）自动改用 [bin456789/reinstall](https://github.com/bin456789/reinstall) 的国内镜像 cnb.cool，安装过程使用国内源，菜单顶部会提示当前使用的脚本。

| 项目 | 选项 |
|---|---|
| 系统 | Debian 13 ★ / 12、Ubuntu 24.04 / 22.04、AlmaLinux 9、Rocky 9、Alpine edge |
| root 密码 | 自定义（输入两次）；回车自动生成 16 位随机密码。可用字符 `A-Z a-z 0-9 @ # % + = : , . _ -`，6–64 位 |
| SSH 端口 | 自定义，默认 22 |
| 软 RAID | 检测到 ≥ 2 块硬盘时可选 RAID 0 / 1 / 5 / 6 / 10（Debian / AlmaLinux / Rocky） |

- Alpine 的 root 密码由 InstallNET 固定为 `LeitboGi0ro`，装好后请立即修改。改用 reinstall 时 Alpine 装最新稳定版，可自定义密码。
- reinstall 不支持软 RAID，多硬盘时安装到当前系统所在硬盘。
- **OVH 独服**用软 RAID 时，请先在 OVH 面板用官方模板、默认分区装一次系统，再执行重装，否则可能无法引导。
- 执行前会汇总所有参数，需要输入 `yes` 确认。重装会清空硬盘。

## 优化 DNS

| 选项 | 说明 |
|---|---|
| 1 国外 | `1.1.1.1` `8.8.8.8`（IPv6：Cloudflare / Google） |
| 2 国内 | `223.5.5.5` `119.29.29.29`（IPv6：阿里 / 腾讯 DNSPod），公共 DNS，任何厂商都能用 |
| 3 手动编辑 | 用 nano 编辑 `/etc/resolv.conf` |
| 4 恢复默认 | 写回 DHCP 下发的 DNS，阿里云 / 腾讯云即内网 DNS（延迟最低）；由 systemd-resolved 管理的机器恢复为它的链接 |

- **阿里云 / 腾讯云机器推荐选 4**，菜单会根据 DMI 信息自动提示。
- 选 1 / 2 会锁定 `/etc/resolv.conf`（`chattr +i`），防止 DHCP 覆盖；选 4 会解锁，交还 DHCP 维护。
- 写入前备份为 `/etc/resolv.conf.bak.*`；写入后验证解析，不通就自动还原（例如无国际出口的国内机器选了国外 DNS）。

## BBRv3 加速

- 从 XanMod 官方 APT 源安装 **LTS** 内核，按 CPU 指令集自动选择 `x64v1`–`x64v3`。官方源连不上时（如无国际出口的国内机器）自动改用国内镜像（南京大学 → 清华 TUNA → 北外），并使用内置公钥。
- 拥塞控制 `bbr`（XanMod 内核中即 BBRv3），队列算法 `fq`，写入 `/etc/sysctl.d/99-nimbus-bbr.conf`。
- 支持 Debian 12+ / Ubuntu 24.04+ 的 x86_64 机器，安装后需要重启。
- **Proxmox VE 宿主机、容器、非 x86_64 或其他发行版不更换内核**，只开启内核自带的 BBR + fq，无需重启。PVE 的判断依据是 `pveversion` 命令、`/etc/pve` 目录或 `pve-manager` 软件包，与主机名无关。

## 自动安装安全更新

基于 `unattended-upgrades`，仅支持 Debian / Ubuntu（含 PVE 等衍生系统）；其他系统会提示不支持，不做任何改动。

- **只装安全源的补丁**。系统默认策略还会安装普通稳定更新，开启后会被覆盖为仅安全更新。
- **不自动重启**。有更新需要重启时，菜单会提示。
- 不涉及 XanMod、Docker、PVE 等第三方源，PVE 的升级仍需手动 `apt dist-upgrade`。
- 菜单可开启 / 关闭、模拟运行、立即执行一次、查看日志，并显示上次和下次运行时间。

## ble.sh 命令行增强

[ble.sh](https://github.com/akinomyoga/ble.sh) 用纯 bash 实现的行编辑器：语法高亮、灰色自动建议（类似 fish）、增强补全。入口：新机开荒第 17 步、系统工具 33、`nb blesh`。

- 装在**当前用户**下（`~/.local/share/blesh`），下载 nightly 包安装，不需要 git / make；国内机器走 GitHub 代理。
- 在 `~/.bashrc` 开头和结尾写入加载块（官方推荐写法：开头 `--attach=none`，结尾 `ble-attach`）；手动加过的 `source …/ble.sh` 行会被注释掉，避免重复加载。改动前备份为 `.bashrc.bak.*`。
- 推荐快捷键写入 `~/.blerc`（来源 `res/config/blesh/blerc`），已有不同配置时先显示差异再确认：

| 按键 | 作用 |
|---|---|
| 回车 | 执行，多行也执行；引号、括号、`if` 等没写完时换行，不会执行半截命令 |
| Ctrl+J | 换行。显示灰色建议或在 Ctrl+R 搜索中时也只换行 / 结束搜索，不会误执行 |
| Shift+Tab、→、End | 接受整条灰色建议（Alt+F 接受一个词） |
| Ctrl+H | 删除光标前一个词。若终端的退格键发送 `^H`，请删掉 `~/.blerc` 中这一行 |

- ble.sh **不会自动更新**：在菜单里选「仅更新 ble.sh」（走同样的代理），或在可直连 GitHub 的机器上执行 `ble-update`。

## TG-bot 监控预警

- **资源监控**：CPU、内存、硬盘使用率和出入站流量超过阈值时，推送 Telegram 告警；由 systemd 服务 `tg-check-notify` 托管，无 systemd 的系统用 crontab。
- **SSH 登录提醒**：通过 `/etc/ssh/sshrc` 触发，只在交互式 SSH 登录时推送；`sudo -i`、tmux、scp/sftp 等无终端连接不会触发。非 root 用户登录时经 sudoers 规则 `/etc/sudoers.d/nimbus-tg-ssh`（只允许免密运行这一个脚本）以 root 读取配置，通知中显示实际登录名。
- Bot Token、Chat ID 和阈值在菜单中交互填写，保存在 `/etc/nimbus/tg-notify.conf`（权限 0600）。
- **话题群**：Chat ID 是开启了话题（Topics）的超级群时，可分别填写 SSH 登录提醒和资源告警的话题 ID（配置项 `SSH_THREAD_ID` / `MONITOR_THREAD_ID`），留空发到 General。旧版部署会自动迁移，菜单中也可一键卸载。

## 应用部署

| 应用 | 入口 | 说明 |
|---|---|---|
| [Komari](https://github.com/komari-monitor/komari-agent) 探针 Agent | 开荒 21 | 填写面板地址、自动发现密钥和月流量重置日；国内机器默认通过加速镜像下载 |
| [Realm](https://github.com/zywe03/realm-xwPF) 端口转发 | 开荒 22 / 基础工具 18 | 安装 xwPF，之后用 `pf` 命令管理；安装和更新都由 Nimbus 下载 xwPF 脚本和 realm（国内机器走代理），已安装时菜单可一键更新，不影响现有规则 |
| [XBoard-node](https://github.com/Hei-XiaoHu/Xboard-Node) | 开荒 23 | 使用 cedar2025/Xboard-Node 的维护分支（内核升级与适配）。填写面板地址、Token、节点 ID，内核可选 xray（默认）或 sing-box；支持状态查看、升级、卸载；国内机器通过代理下载 |

## 文件与配置位置

| 路径 | 说明 |
|---|---|
| `~/nimbus.sh`、`/usr/local/bin/nb` | 脚本与快捷命令 |
| `/etc/nimbus/tg-notify.conf` | TG-bot 配置 |
| `/etc/nimbus/wizard.state` | 新机开荒的执行记录与手动标记 |
| `/etc/apt/apt.conf.d/52nimbus-security-only` | 自动安全更新策略 |
| `/etc/sysctl.d/99-nimbus-bbr.conf` | BBR 设置 |
| `~/.local/share/blesh`、`~/.blerc` | ble.sh 及其快捷键配置 |

国内 / IPv6 模式使用的 GitHub 代理，在 `nimbus.sh` 开头的 `gh_proxy_mirror` 变量中配置。

<details>
<summary>仓库结构</summary>

```text
nimbus/
├── nimbus.sh                 主脚本
├── CHANGELOG.md              更新日志（「脚本更新」中读取）
├── TG-check-notify.sh        TG-bot 资源监控
├── TG-SSH-check-notify.sh    TG-bot SSH 登录提醒
├── Limiting_Shut_down1.sh    限流关机任务
├── archive.key               XanMod 仓库签名备用密钥
├── res/config/               fail2ban 规则（CentOS 系）、tmux / ble.sh 推荐配置
├── docs/                     文档
├── .pi/                      开发用 pi skill（功能开发 / 上游同步）与上游同步记录
└── assets/                   README 资源
```

</details>
