<p align="center">
  <img src="assets/logo.svg" alt="Nimbus" width="460">
</p>

<p align="center">
  <b>轻量、干净的 Linux 云服务器工具箱</b><br>
  <sub>一条命令完成新机初始化、系统管理、网络加速与安全加固 · 无遥测 · 无广告</sub>
</p>

<p align="center">
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/version-1.2.20-6366f1?style=flat-square" alt="version"></a>
  <img src="https://img.shields.io/badge/shell-bash-38bdf8?style=flat-square&logo=gnubash&logoColor=white" alt="bash">
  <img src="https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu%20%7C%20RHEL%20%7C%20Alpine-0ea5e9?style=flat-square&logo=linux&logoColor=white" alt="platform">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-64748b?style=flat-square" alt="license"></a>
</p>

<p align="center">
  <a href="#-快速开始">快速开始</a> ·
  <a href="docs/wizard.md">新机开荒</a> ·
  <a href="docs/features.md">功能详解</a> ·
  <a href="docs/commands.md">命令行</a> ·
  <a href="docs/faq.md">常见问题</a>
</p>

---

## 🚀 快速开始

以 `root` 身份运行：

```bash
bash <(curl -sL https://raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh)
```

<details>
<summary>国内服务器</summary>

```bash
bash <(curl -sL https://ghfast.top/https://raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh)
```

连 ghfast 也访问不了（没有国际出口）时，用国内镜像 cnb.cool：

```bash
bash <(curl -sL https://cnb.cool/zidou-kiyn/nimbus/-/git/raw/main/nimbus.sh)
```

</details>

首次运行会安装快捷命令 **`nb`**，之后输入 `nb` 即可打开菜单。新机器建议直接从 **`nb init`** 开始。

## ✨ 特性

- 🌱 **新机开荒**：23 步初始化按推荐顺序排好，实时检测状态、推荐下一步，可跳过或手动标记。[了解更多 →](docs/wizard.md)
- 💿 **重装系统**：基于 InstallNET，可自定义系统版本、root 密码、SSH 端口，多硬盘时可选软 RAID；连不上 GitHub 的国内机器自动改用 bin456789/reinstall 国内镜像。
- ⚡ **BBRv3**：XanMod LTS 内核 + BBRv3；PVE 宿主机、容器只开 BBR + fq，不动内核。
- 🛡️ **安全加固**：密钥登录、改 SSH 端口、fail2ban、仅安全补丁的自动更新。
- 📡 **监控与部署**：TG-bot 资源告警与 SSH 登录提醒，以及 Komari 探针、Realm 转发、XBoard-node 的安装。
- ⌨️ **命令行增强**：tmux 推荐配置；ble.sh 语法高亮与自动建议，回车 / Ctrl+J 等快捷键防误触。
- 🐳 **日常运维**：Docker 管理、防火墙、虚拟内存、备份、测速与流媒体检测。

```text
Nimbus · 云服务器工具箱 v1.2.20
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

## ⌨️ 常用命令

| 命令 | 说明 |
|---|---|
| `nb init` | 新机开荒 |
| `nb update` / `nb clean` | 更新系统 / 清理垃圾 |
| `nb bbr3` | BBRv3 加速 |
| `nb dd` | 重装系统 |
| `nb sshkey github <用户>` | 导入 GitHub 公钥 |
| `nb help` | 全部用法 |

完整列表见 [命令行参考](docs/commands.md)。

> [!WARNING]
> 脚本会执行装包、换内核、改防火墙、重装系统等系统级操作。请看清终端提示，生产环境操作前先做好备份。

## 📄 许可

[Apache License 2.0](LICENSE)。本项目基于 [kejilion/sh](https://github.com/kejilion/sh) 修改，详见 [NOTICE](NOTICE) · [更新日志](CHANGELOG.md)。
