# ⌨️ 命令行参考

不进菜单，直接用 `nb <命令>` 执行。大多数命令也支持中文别名，`nb help` 可查看全部。

## 常用

| 命令 | 说明 |
|---|---|
| `nb` | 打开主菜单 |
| `nb init` | 新机开荒 |
| `nb info` | 系统信息 |
| `nb update` / `nb clean` | 更新系统 / 清理垃圾 |
| `nb help` | 显示全部用法 |

## 软件包与服务

| 命令 | 说明 |
|---|---|
| `nb install nano wget` | 安装软件包（别名 `add`） |
| `nb remove nano wget` | 卸载软件包（别名 `del` / `uninstall`） |
| `nb start\|stop\|restart\|status <服务>` | 服务启动 / 停止 / 重启 / 状态 |
| `nb enable <服务>` | 设为开机启动（别名 `autostart`） |

## 系统

| 命令 | 说明 |
|---|---|
| `nb dd` | 一键重装系统 |
| `nb bbr3` | BBRv3 加速 |
| `nb swap 2048` | 设置虚拟内存（MB） |
| `nb time Asia/Shanghai` | 设置时区 |
| `nb secupdate` | 自动安装安全更新 |
| `nb backup` | 系统备份与恢复 |
| `nb disk` | 硬盘管理 |

## 网络与安全

| 命令 | 说明 |
|---|---|
| `nb fhq` | 防火墙面板 |
| `nb dkdk 8080` / `nb gbdk 8080` | 开放 / 关闭端口 |
| `nb fxip 1.2.3.4` / `nb zzip 1.2.3.4` | 放行 / 阻止 IP（支持网段） |
| `nb f2b` | fail2ban SSH 防御 |
| `nb sshkey` | root 密钥管理 |
| `nb sshkey <url>` | 从 URL 导入公钥 |
| `nb sshkey github <用户>` | 导入 GitHub 用户的公钥 |

## Docker

| 命令 | 说明 |
|---|---|
| `nb docker` | Docker 管理面板 |
| `nb docker install` | 安装 Docker 环境 |
| `nb docker ps` | 容器管理 |
| `nb docker img` | 镜像管理 |
