Nimbus 更新日志
------------------------
2026-10-25   v1.0.0
首个版本。
1.主菜单：系统信息、系统更新、系统清理、基础工具、BBRv3、Docker 管理、测试脚本、系统工具。
2.BBRv3：安装 XanMod LTS 内核，开启 BBRv3 + fq。
3.系统工具按 账号与登录 / 网络 / 系统 / 安全与运维 分组。
4.无遥测、无广告、无外部宣传链接；脚本与资源全部来自本仓库。
5.快捷命令 nb，脚本位于 ~/nimbus.sh。
------------------------
2026-10-25   v1.0.1
TG-bot 系统监控预警（系统工具 26）重构。
1.配置全部改为交互问答，不再用 nano 编辑脚本：机器信息可用自动探测值或自定义，Bot Token 隐藏输入并经 getMe 校验，发送测试消息确认，阈值带默认值与合法性校验；已有配置可逐项沿用。
2.配置统一写入 /etc/nimbus/tg-notify.conf（root:root 0600），两个脚本运行时读取，仓库中不含任何 Token。
3.资源监控改为 systemd 托管：/root/TG-check-notify.sh + tg-check-notify.service（开机自启、异常自动重启）；无 systemd 的系统回退为 crontab @reboot。不再使用 tmux。
4.SSH 登录提醒改为 /usr/local/bin/tg-ssh-notify.sh，由 /etc/ssh/sshrc 后台触发，不再写入 ~/.profile；新建 sshrc 且开启 X11 转发时自动补上标准 xauth 片段。
5.旧部署自动迁移：停止旧 tmux 会话，移除 crontab 中的 @reboot 行、~/.profile 中的旧调用（及旧逻辑添加的 source ~/.profile），删除 ~/TG-SSH-check-notify.sh。
6.机器信息只在配置时探测一次，登录提醒不再每次联网查询本机信息；消息改用 URL 编码发送，含 & + % 等字符不再被截断；所有请求加超时。
7.新增“卸载”选项：停用并删除服务、sshrc 挂载、脚本和配置文件。
8.依赖精简为 curl bc jq。
------------------------
