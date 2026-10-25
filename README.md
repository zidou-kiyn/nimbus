<p align="center">
  <img src="assets/logo.svg" alt="Nimbus" width="460">
</p>

<p align="center">
  <b>轻量、干净的 Linux 云服务器工具箱</b><br>
  <sub>一条命令管理系统、网络、Docker 与安全 · 无遥测 · 无广告</sub>
</p>

<p align="center">
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-1.2.0-6366f1?style=flat-square" alt="version"></a>
  <img src="https://img.shields.io/badge/shell-bash-38bdf8?style=flat-square&logo=gnubash&logoColor=white" alt="bash">
  <img src="https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu%20%7C%20RHEL%20%7C%20Alpine-0ea5e9?style=flat-square&logo=linux&logoColor=white" alt="platform">
  <a href="https://github.com/zidou-kiyn/nimbus/commits/main"><img src="https://img.shields.io/github/last-commit/zidou-kiyn/nimbus?style=flat-square&color=818cf8" alt="last commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-64748b?style=flat-square" alt="license"></a>
</p>

<p align="center">
  <a href="#-快速开始">快速开始</a> ·
  <a href="#-功能一览">功能一览</a> ·
  <a href="#-命令行速查">命令行速查</a> ·
  <a href="#-bbrv3-加速">BBRv3</a> ·
  <a href="#-项目结构">项目结构</a>
</p>

---

## 🚀 快速开始

以 `root` 身份执行：

```bash
bash <(curl -sL https://raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh)
```

<details>
<summary>国内服务器（通过 GitHub 代理）</summary>

```bash
bash <(curl -sL https://ghfast.top/https://raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh)
```

</details>

首次运行后会安装快捷命令 **`nb`**（脚本保存在 `~/nimbus.sh`），以后直接输入 `nb` 打开主菜单；国内机器直连 GitHub 失败时会自动改用代理并切换为国内模式。

新机器推荐从 **`nb init`（新机开荒）** 开始，按顺序逐项完成初始化。

```text
Nimbus · 云服务器工具箱 v1.2.0
------------------------
1.   系统信息查询
2.   系统更新
3.   系统清理
4.   基础工具
5.   BBRv3加速
6.   Docker管理
7.   测试脚本合集
8.   系统工具
9.   新机开荒 ★
------------------------
00.  脚本更新
0.   退出脚本
```

> [!WARNING]
> 脚本会执行软件安装、内核更换、防火墙、磁盘等系统级操作。请先阅读终端提示，生产环境操作前做好备份。

## 🧰 功能一览

| 模块 | 内容 |
|---|---|
| **系统信息** | CPU、内存、磁盘、网络流量、地理位置、运行时长等概览 |
| **系统更新 / 清理** | 自动识别 apt / dnf / yum / apk / pacman 等包管理器 |
| **基础工具** | curl、wget、htop、btop、tmux、ffmpeg、vim、nano、git 等一键安装与卸载；realm 端口转发（xwPF） |
| **BBRv3 加速** | XanMod LTS 内核 + BBRv3 + fq，见 [下文](#-bbrv3-加速) |
| **Docker 管理** | 安装与换源、容器 / 镜像 / 网络 / 卷管理、IPv6、备份 / 迁移 / 还原 |
| **测试脚本** | 流媒体解锁、IP 质量、三网回程路由、测速、yabs / GB5 / 融合怪性能测试 |
| **新机开荒** | 把新机初始化按推荐顺序集中在一个菜单，实时显示每步状态并给出下一步，见 [下文](#-新机开荒) |

**系统工具**

| 分组 | 功能 |
|---|---|
| 账号与登录 | 修改密码、密码 / 密钥登录模式、禁用 root 并新建账户、用户管理、密码生成器 |
| 网络 | 开放端口、修改 SSH 端口、DNS 优化、IPv4/IPv6 优先、端口占用、防火墙、hosts、网卡管理 |
| 系统 | 一键重装系统（InstallNET，可自定义密码 / 端口 / 软 RAID）、虚拟内存、时区、BBRv3、主机名、更新源、定时任务、系统语言、环境变量 |
| 安全与运维 | SSH 防御（fail2ban）、自动安装安全更新、限流自动关机、TG-bot 监控预警、命令行美化、系统备份与恢复、硬盘分区、命令历史、日志管理 |

## ⌨️ 命令行速查

| 命令 | 说明 |
|---|---|
| `nb` | 打开主菜单 |
| `nb init` | 新机开荒 |
| `nb secupdate` | 自动安装安全更新 |
| `nb info` | 系统信息 |
| `nb update` / `nb clean` | 更新系统 / 清理垃圾 |
| `nb install <包…>` / `nb remove <包…>` | 安装 / 卸载软件包 |
| `nb bbr3` | BBRv3 加速 |
| `nb docker [install\|ps\|img]` | Docker 管理 / 安装 / 容器 / 镜像 |
| `nb swap 2048` | 设置虚拟内存（MB） |
| `nb time Asia/Shanghai` | 设置时区 |
| `nb fhq` | 防火墙面板 |
| `nb dkdk <端口>` / `nb gbdk <端口>` | 开放 / 关闭端口 |
| `nb fxip <IP>` / `nb zzip <IP>` | 放行 / 阻止 IP |
| `nb f2b` | fail2ban SSH 防御 |
| `nb sshkey [<url>\|github <用户>]` | 导入 SSH 公钥 |
| `nb backup` / `nb disk` | 系统备份 / 硬盘管理 |
| `nb dd` | 一键重装系统 |
| `nb start\|stop\|restart\|status\|enable <服务>` | 服务管理 |
| `nb help` | 显示全部用法 |

## ⚡ BBRv3 加速

- 从 XanMod 官方 APT 源安装 **LTS** 内核，按 CPU 指令集自动选择 `x64v1`–`x64v3` 包
- 拥塞控制 `bbr`（XanMod 内核即 BBRv3），队列算法 `fq`，写入 `/etc/sysctl.d/99-nimbus-bbr.conf`
- 支持 Debian 12+ / Ubuntu 24.04+，x86_64；安装后需重启
- Proxmox VE 宿主机、容器、非 x86_64 或其他发行版不更换内核，只开启内核自带的 BBR + fq

## 🌱 新机开荒

`nb init` 或主菜单 `9`。每一步实时检测状态（✔ 已完成 / ○ 待处理 / ⚠ 需注意），按 `n` 执行推荐的下一步，可随时退出、回来继续。

| 阶段 | 步骤 |
|---|---|
| 一 · 系统安装 | 1 重装系统（可选） |
| 二 · 基础与内核 | 2 修改 root 密码 · 3 更新系统 · 4 内核与 BBR · 5 重启并检查内核 |
| 三 · 系统设置 | 6 时区 · 7 主机名 · 8 hosts 解析 · 9 虚拟内存 · 10 DNS · 11 自动安装安全更新 |
| 四 · SSH 与账号安全 | 12 密钥登录（禁用密码） · 13 SSH 端口 · 14 新建 sudo 用户并禁用 root（可选） · 15 fail2ban |
| 五 · 环境与监控 | 16 tmux 及推荐配置 · 17 TG-bot 监控 · 18 系统语言（可选） · 19 命令行美化 |
| 六 · 应用部署（按需） | 20 Komari 探针 · 21 Realm 端口转发 · 22 XBoard-node 节点 |

## 📁 项目结构

```text
nimbus/
├── nimbus.sh                 主脚本
├── CHANGELOG.md              更新日志（脚本内「脚本更新」读取）
├── Limiting_Shut_down1.sh    限流关机任务
├── TG-check-notify.sh        TG-bot 资源监控
├── TG-SSH-check-notify.sh    TG-bot SSH 登录提醒
├── archive.key               XanMod 仓库签名备用密钥
├── res/config/fail2ban/      fail2ban 规则（CentOS 系）
├── res/config/tmux/          tmux 推荐配置
├── assets/                   README 资源
└── NOTICE                    上游出处声明
```

国内 / IPv6 模式使用的 GitHub 代理在 `nimbus.sh` 开头的 `gh_proxy_mirror` 变量中配置。

## 📄 许可

[Apache License 2.0](LICENSE)。本项目基于 [kejilion/sh](https://github.com/kejilion/sh) 修改，详见 [NOTICE](NOTICE)。
