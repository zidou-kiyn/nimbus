<h1 align="center">kejilion.sh（精简版）</h1>

<p align="center">
  面向 Linux 服务器的脚本工具箱，fork 自
  <a href="https://github.com/kejilion/sh">kejilion/sh</a>，去除遥测与外部依赖后精简维护。
</p>

<p align="center">
  <a href="https://github.com/zidou-kiyn/sh/commits/main"><img src="https://img.shields.io/github/last-commit/zidou-kiyn/sh?style=flat-square" alt="Last Commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg?style=flat-square" alt="Apache-2.0 License"></a>
</p>

## 一键安装

使用 `root` 用户执行：

```bash
bash <(curl -sL https://raw.githubusercontent.com/zidou-kiyn/sh/main/kejilion.sh)
```

国内服务器可通过 GitHub 代理下载：

```bash
bash <(curl -sL https://ghfast.top/https://raw.githubusercontent.com/zidou-kiyn/sh/main/kejilion.sh)
```

运行后会安装 `k` 快捷命令，之后直接输入 `k` 即可打开主菜单，`k help` 查看命令行用法。

> [!IMPORTANT]
> 脚本包含软件安装、网络、防火墙、磁盘等系统级操作。
> 请在执行前阅读终端提示，并提前备份重要数据、容器和配置。

## 功能

- **系统信息与维护**：系统信息、更新、清理、基础工具安装、BBR/BBRv3、内核参数优化、一条龙调优。
- **网络与测试**：测速、回程路由、流媒体解锁等测试脚本合集，WARP 管理。
- **Docker 管理**：容器、镜像、网络、存储卷管理，备份/迁移/还原。
- **应用市场**：一键安装和管理常用面板、服务与 AI 工具，支持 `~/apps-local` 本地自建应用。
- **系统工具**：防火墙、fail2ban、SSH、虚拟内存、时区、DNS、硬盘、rsync、定时任务、限流关机等。
- **后台工作区与集群控制**：tmux 后台任务，多服务器批量执行。

## 与上游的差异

相对上游 v4.5.14 移除了以下内容，详见 [更新日志](kejilion_sh_log.txt)：

- 遥测/数据采集、首次运行许可协议、广告专栏与外部宣传链接
- KPanel 面板及其协议接口
- LDNMP 建站（证书申请与续签、WAF、反向代理、站点管理）及依赖域名反代的应用
- 多语言版本、游戏开服脚本

脚本更新、应用市场与配置资源全部从本仓库获取，不再访问 kejilion 的服务器：

| 目录 | 内容 |
|---|---|
| `kejilion.sh` | 主脚本 |
| `apps/` | 应用市场配置，见 [说明](apps/README.md) |
| `res/` | 部分应用使用的 compose、fail2ban、prometheus 等配置 |

国内/IPv6 模式使用的 GitHub 代理在脚本开头的 `gh_proxy_mirror` 变量中配置。

## 开源许可

本项目基于 [kejilion/sh](https://github.com/kejilion/sh) 修改，沿用 [Apache License 2.0](LICENSE)。
