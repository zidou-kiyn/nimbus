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
2026-10-25   v1.1.0
新增「新机开荒」，修复首次运行不安装快捷命令。
1.修复：通过 bash <(curl ...) 首次运行时未安装 ~/nimbus.sh 和 nb；现在会自动下载安装，直连 GitHub 失败时改走代理并切换为国内模式。
2.新增新机开荒（主菜单 9 / nb init）：21 步按推荐顺序分 6 个阶段，实时显示状态并推荐下一步。
3.重装系统改用 InstallNET（leitbogioro）：可自定义系统版本、root 密码、SSH 端口，多硬盘时可选软 RAID 0/1/5/6/10（Debian / Alma / Rocky）。
4.BBRv3：Proxmox VE 宿主机、容器、非 x86_64 或其他发行版不再尝试安装 XanMod，改为只开启内核自带 BBR + fq。
5.新增 tmux 推荐配置、Komari 探针、XBoard-node 节点；基础工具新增 realm 端口转发（xwPF）。
6.修复：fail2ban 未同步 SSH 端口（改端口后拦截无效）；Debian 12 首次安装 fail2ban 因缺少 auth.log 启动失败。
7.修复：命令行美化把 PS1 直接写入 ~/.profile，dash 登录时原样打印转义符；现写入带 bash 判断的配置块。
8.修改主机名：PVE 宿主机先警告；/etc/hosts 改为精确替换旧主机名（含 FQDN），不再整行覆盖 127.0.0.1。
9.新建 sudo 用户并禁用 root 后立即重启 sshd 使禁用生效；修改 SSH 端口成功后自动退出。
------------------------
2026-10-25   v1.2.0
新增「自动安装安全更新」。
1.基于 unattended-upgrades，只自动安装 Debian / Ubuntu 安全源的补丁（覆盖系统默认策略中的普通稳定更新），不自动重启，不影响 XanMod、Docker、PVE 等第三方源。
2.可开启 / 关闭、模拟运行、立即执行一次、查看日志，显示上次与下次运行时间及是否需要重启。
3.入口：新机开荒第 11 步、系统工具 32、nb secupdate。PVE 宿主机开启前会提示。
------------------------
2026-10-26   v1.2.1
新机开荒支持跳过和手动标记，文档重新整理。
1.新机开荒：s 跳过推荐的这一步；m 编号 切换完成/未完成（可多个，如 m 3 6 9）；a 编号 恢复自动检测。重新执行某一步后，该步的手动标记自动清除。
2.新机开荒：不适用的步骤（如非 Debian/Ubuntu 上的自动安全更新）显示为「–」，不再卡住推荐；TG-bot 改为可选，系统语言改为必做并按配置文件检测。
3.PVE 判断增加 pve-manager 软件包检测（与主机名无关）。
4.README 精简，详细说明移到 docs/（新机开荒、功能详解、命令行参考、常见问题）。
------------------------
2026-10-27   v1.2.2
tmux 推荐配置优化（Termius 手机/电脑 + tmux 内运行 pi）。
1.pi 复制在任何来源的会话里都能到达客户端：全局设置 PI_CLIPBOARD_OSC52=1（本机或远控开的会话、之后再从 SSH attach 也生效）。
2.新增 prefix+m（默认 Ctrl+B 然后 M）开关鼠标，关闭后可直接用终端原生选择。
3.escape-time 10（旧版 tmux 默认 500ms，Esc 有延迟）；关闭会话最后一个窗口时切到其他会话而不是断开；窗口自动重新编号。
4.去掉 vi 模式下用不到的 copy-mode 重复绑定，注释精简，配置行数减半；鼠标行为不变。
------------------------
2026-10-27   v1.2.3
修复自动更新会把国内镜像设置改回直连 GitHub。
1.原因：自动更新的定时任务写成 bash -c '…'，里面又套了单引号，sed 中的双引号被吃掉，替换永远匹配不上，国内/IPv6 机器第一次自动更新后就回到直连，之后下载全部失败。
2.“现在更新”和自动更新统一改为 nb self-update：沿用本机当前线路模式；直连下载失败时自动改走镜像并切换为国内模式；更新 nb 命令时先写临时文件再替换，不再改写正在运行的脚本。
3.IPv6 模式只用于纯 IPv6 机器（没有 IPv4 默认路由），双栈机器保持直连 GitHub。
4.旧版定时任务在下次运行 nb 时自动迁移为 nb self-update，执行时间不变。
------------------------
2026-10-27   v1.2.4
修复修改 SSH 端口后 fail2ban 仍只拦截 22 端口。
1.Alpine：jail 名本来就是 sshd / sshd-ddos（alpine-sshd 只是过滤器名），旧版却把端口写进不存在的 [alpine-sshd]，真正生效的 jail 仍是 port = ssh；旧配置会自动迁移，原有 bantime 等参数保留。
2.端口改为同步到 fail2ban 实际加载的所有 SSH jail（sshd、sshd-ddos 等），不再按系统猜测 jail 名；查看拦截记录、基础参数配置同样按实际 jail 名处理。
3.SSH 端口检测更可靠：sshd -T 失败时（Debian/Ubuntu 缺少 /run/sshd）会解析 sshd_config 及 sshd_config.d/*.conf，并合并 sshd 实际监听的端口（如 Ubuntu ssh.socket 未切换到新端口时，新旧端口都会保护）。
4.同步时机：修改 SSH 端口时即使重启 sshd 失败也会同步；进入 fail2ban 面板、编辑配置后会自动检查（端口没变化时不会输出提示，也不会 reload），手动改端口或装 fail2ban 之前就改过端口的机器也能对齐。
5.基础参数配置只在 Debian/Ubuntu 上补 logpath = /var/log/auth.log，CentOS 系不再写入不存在的日志路径。
6.修改 SSH 端口不再卸载 firewalld：RHEL 系上 dnf remove firewalld 会连带卸掉整个 fail2ban。firewalld 运行中时改为用 firewall-cmd 放行新端口；没运行时只写入它的永久配置，避免开机自启后拦截新端口。
7.CentOS 系安装 fail2ban 时若连带装上了 firewalld（原本没有、也没运行），会取消它的开机自启：它默认只放行 22，重启后会让改过端口的 SSH 连不上。
8.封禁动作按本机实际可用的防火墙选择：当前动作无法执行时（firewalld 没运行、只有 nftables 没有 iptables），自动改用 firewallcmd / nftables / iptables 中可用的一个；原本能用的配置（如 Debian 13 默认的 nftables）不改动。修复前这类机器上 fail2ban 只记日志，实际不会拦截。
9.同步后核对 fail2ban 实际生效的端口；若被其他 jail.d/*.local 覆盖，会列出这些文件提示修改。
10.检测到自定义 nftables 规则时，改端口后提示在自己的 nftables 规则中放行新端口（nimbus 只操作 iptables / firewalld，不改 nftables 配置）。
------------------------
2026-10-27   v1.2.5
修复修改 SSH 端口的几个可靠性问题，防火墙规则不再保存 fail2ban 的封禁。
1.Ubuntu 22.10+（ssh.socket 监听端口）改端口后实际仍在旧端口监听：现在会 daemon-reload 并重启 ssh.socket 与 ssh.service，已有会话不受影响。
2.重启 SSH 服务按实际服务名处理（Debian/Ubuntu 为 ssh，RHEL 系为 sshd），Alpine 改用 rc-service；失败时如实返回，不再一律当作成功。
3.修改 SSH 端口改为先放行防火墙、再改配置并重启：放行失败时 sshd_config 保持原样；改完先用 sshd -t 检查，配置有误自动还原；重启后检查新端口确实在监听，否则提示保持当前会话排查。
4.保存 iptables 规则时去掉 fail2ban 的 f2b-* 链：之前会把当时被封的 IP 一起存进 rules.v4，开机恢复后变成永久封禁，fail2ban 也不会解封。
5.防火墙菜单的清除 IP、允许 / 禁用 PING 改用统一的保存逻辑（同时保存 IPv6 规则与开机恢复任务）。
------------------------
2026-10-27   v1.2.6
新增「ble.sh 命令行增强」（新机开荒第 17 步 / 系统工具 33 / nb blesh）。
1.安装 ble.sh：语法高亮、灰色自动建议、增强补全。装在当前用户的 ~/.local/share/blesh，下载 nightly 包安装，不需要 git / make，国内机器走 GitHub 代理；可单独更新或卸载。
2.~/.bashrc 首尾写入加载块（开头 --attach=none、结尾 ble-attach），手动添加过的 source ble.sh 行自动注释，改动前备份。
3.推荐快捷键写入 ~/.blerc（res/config/blesh/blerc）：回车执行、命令没写完时换行；Ctrl+J 换行；Shift+Tab 接受建议；Ctrl+H 删前一个词。
4.防误触：显示灰色建议时 Ctrl+J 原本会「接受建议并执行」，Ctrl+R 搜索中 Ctrl+J 原本会直接执行，均改为不执行。
5.新机开荒原 17–22 步顺延为 18–23 步。
------------------------
2026-10-27   v1.2.7
XBoard-node 改用 Hei-XiaoHu/Xboard-Node。
1.安装脚本和程序改从 Hei-XiaoHu/Xboard-Node（cedar2025/Xboard-Node 的维护分支，内核升级与适配）下载：main 分支的安装脚本 + 最新 release，命令行参数和配置目录不变，已装的节点选「升级」即可切换。
2.安装和升级前先由 Nimbus 下载 xboard-node / xbctl（国内机器走 GitHub 代理），再交给安装脚本，修复国内机器直连 GitHub 下载失败。
3.菜单显示当前已安装的版本。
------------------------
2026-10-27   v1.2.8
修复装了 ble.sh 后命令行美化失效（提示符变回全白）。
1.原因：Debian/Ubuntu 的美化 PS1 写在 ~/.profile，在加载 ~/.bashrc 之后才设置；ble.sh 在 ~/.bashrc 末尾 attach 时接管提示符，之后再设的 PS1 会被它还原成 .bashrc 里的默认值，因此重新美化也不生效。
2.命令行美化改为写入 ~/.bashrc，并放在 ble.sh 的 attach 块之前（登录时不加载 .bashrc 的系统如 Alpine 仍写 ~/.profile），同时清理 ~/.profile 里旧的配置；~/.profile 中其他 PS1= 行（包括手写在 if 里的）改为注释掉的空操作 `: # [nimbus 已停用] …`，不会破坏 if 语法。
3.安装 / 更新 ble.sh（系统工具 33 选 1、新机开荒、nb blesh）时，自动把 ~/.profile 里已有的美化配置挪到 ~/.bashrc。已受影响的机器：nb self-update 后重新执行一次命令行美化或 ble.sh 安装即可。
------------------------
2026-10-28   v1.2.9
重装系统适配无法访问境外的国内机器（如部分腾讯云锐驰型）。
1.原来重装前要从 GitHub（国内走 ghfast 代理）下载 InstallNET.sh，机器完全没有国际出口时会下载失败，而 InstallNET 在 gitee 上的副本也已无法下载。
2.现在打开重装菜单时先下载重装脚本：InstallNET 依次尝试直连和代理；都失败时自动改用 bin456789/reinstall 的国内镜像 cnb.cool，安装过程使用国内源，菜单顶部会提示当前使用的脚本。
3.改用 reinstall 时系统选项、root 密码和 SSH 端口不变，Alpine 改为最新稳定版并可自定义密码；reinstall 不支持软 RAID，多硬盘时安装到当前系统所在硬盘。
------------------------
2026-10-28   v1.2.10
修复无国际出口的机器上「优化 DNS」卡住，并防止选错 DNS 后断网。
1.原因：写 DNS 前要查公网 IP，请求 ipinfo.io 没有超时，连不上境外的机器会卡好几分钟；卡完还会照样写入国外 DNS，而这类机器连不上 1.1.1.1 / 8.8.8.8，写入后无法解析任何域名。
2.优化 DNS 改为按默认路由判断 IPv4 / IPv6，不再查公网 IP；写入前备份 /etc/resolv.conf，写入后验证解析，不通就自动还原原配置并提示改选国内 DNS。完成后停留显示结果。
3.其他查询公网 IP 和国家的地方（系统信息、Docker 安装、系统更新等）统一加了超时，最多等 5 秒。
------------------------
2026-10-28   v1.2.11
修复无国际出口的国内机器被识别成国外机器。
1.原因：判断机器所在国家只查 ipinfo.io，连不上境外的机器查不到结果，被当成非国内处理，例如装 Docker、换系统源时会用国外源。
2.新增统一的国家检测：先查 ipinfo.io，查不到时改用 Cloudflare 国内节点的 trace 接口（qualcomm.cn），国内外都能访问。
3.用到的地方：国内模式判断、脚本自更新的线路检测、Docker 安装与镜像加速、切换系统源、系统信息的地理位置、TG-bot 监控预警的机器标识。
------------------------
2026-10-28   v1.2.12
优化 DNS：国内选项改用公共 DNS，新增「恢复默认 DNS」。
1.原「国内 DNS」里的 183.60.83.19 是腾讯云内网 DNS，只有腾讯云机器能用，阿里云等其他机器上会超时。改为公共 DNS 223.5.5.5 + 119.29.29.29（IPv6：2400:3200::1 + 2402:4e00::）。
2.新增选项 4「恢复默认 DNS」：写回 DHCP 下发的 DNS（依次读取 dhcpcd、dhclient、systemd-networkd、NetworkManager，读不到时按云厂商使用内网 DNS），并解除锁定交还 DHCP 维护；由 systemd-resolved 管理的机器恢复为它的链接。
3.阿里云、腾讯云机器（按 DMI 信息识别）打开菜单时提示推荐选 4：内网 DNS 延迟最低，也不受公网波动影响。
4.原来 /etc/resolv.conf 是链接时，选 1 / 2 改为替换成普通文件，不再写进 systemd-resolved 的临时文件；备份文件名不再重复；「当前 DNS 地址」不再显示注释。
------------------------
2026-10-28   v1.2.13
TG-bot 监控预警支持话题群；Realm 端口转发新增一键更新。
1.TG-bot 监控预警：Chat ID 是开启了话题（Topics）的超级群（-100 开头）时，新增「话题设置」：SSH 登录提醒和资源告警可分别发到不同话题，填写后会向每个话题发送测试消息确认。话题 ID 保存为配置文件中的 SSH_THREAD_ID / MONITOR_THREAD_ID，留空则和以前一样发到 General 或私聊；旧配置文件无需改动。
2.Realm 端口转发：已安装 xwPF 时，菜单改为「管理转发规则（pf）」和「更新 xwPF 脚本和 realm」，并显示当前版本与服务状态。xwPF 自带的更新直连 GitHub，国内机器会卡住或失败；新的更新全部走 Nimbus 的下载通道（国内自动用代理），realm 版本跟随 xwPF 中适配过的 REALM_VERSION，更新时自动停启服务，旧程序备份为 /usr/local/bin/realm.bak，转发规则和配置不受影响。
------------------------
2026-10-28   v1.2.14
TG-bot SSH 登录提醒支持非 root 用户登录。
1.原来配置文件仅 root 可读，用普通用户（如 sudo 用户）SSH 登录时提醒脚本读不到配置，不会发通知。
2.现在部署时新增 sudoers 规则 /etc/sudoers.d/nimbus-tg-ssh（0440，写入前用 visudo 校验）：只允许免密以 root 运行 /usr/local/bin/tg-ssh-notify.sh 这一个脚本。普通用户登录时脚本经 sudo -n 以 root 重新运行，登录名取 SUDO_USER，登录 IP 作为参数传入并只接受 IP 字符；配置文件仍是 0600。
3.触发条件不变：sshrc 中的 SSH_TTY 判断保证只有交互式登录才提醒，sudo -i、tmux、scp/sftp 等不会触发；sshrc 挂载行不变，已部署的机器重新运行菜单即可。
4.未安装 sudo 的系统给出提示，仅 root 登录提醒；卸载时一并删除 sudoers 规则。
------------------------
2026-10-28   v1.2.15
系统更新前检查更新源能否连通，连不上时可一键切换镜像。
1.原因：DD 后的国内机器常常仍用 security.debian.org 等境外源，apt update 会卡在连接上很久（默认每个地址等 120 秒，还会逐个尝试 IPv4 / IPv6）。
2.Debian / Ubuntu 更新前先检查所有 apt 源（不依赖 curl），有连不上的就列出来并提供选择：阿里云 / 腾讯云机器切换到内网镜像（mirrors.cloud.aliyuncs.com / mirrors.tencentyun.com，不占公网流量），其他国内机器切换到阿里云公共镜像，也可以不切换继续或取消。
3.只替换官方格式的源（路径为 /debian、/debian-security、/ubuntu、/ubuntu-ports），docker、nodesource、xanmod 等第三方源不动；原文件备份到 /etc/apt/nimbus-backup/。
4.apt update 的连接超时改为 20 秒，个别源连不上时不会再卡几分钟。
------------------------
2026-10-28   v1.2.16
BBRv3 适配无国际出口的国内机器，并修复中文系统找不到内核包。
1.原来安装 XanMod 要从 dl.xanmod.org 下载公钥、从 deb.xanmod.org 装内核，连不上境外的机器会卡住很久（wget 默认等 15 分钟并重试 20 次）。
2.现在先检查 deb.xanmod.org 能否连接，连不上就改用清华 TUNA 的 XanMod 镜像（与官方同步）；公钥依次尝试官方、GitHub 备份，都不可用时使用脚本内置的官方公钥（指纹 D38D 7D1D A134 9567 ADED 882D 86F7 D09E E734 E623），下载都加了超时。
3.修复系统语言为中文时提示「软件源中未找到适配此 CPU 的 XanMod LTS 内核包」：检测候选版本时 apt 输出的是「候选：」而不是「Candidate:」，现改为按英文输出检测。
------------------------
2026-10-28   v1.2.17
BBRv3 的国内 XanMod 镜像改为优先南京大学。
1.清华 TUNA 对非教育网限速明显，实测腾讯云广州下载内核只有约 160 KB/s，一个内核要十几分钟；南京大学镜像约 17 MB/s，内容与官方同步。
2.官方仓库连不上时依次尝试南京大学、清华 TUNA、北外镜像，使用第一个能连上的。已用 TUNA 装过的机器重新执行 BBRv3 的「更新内核」即会切换。
------------------------
2026-10-28   v1.2.18
Realm 端口转发：无国际出口的国内机器也能首次安装。
1.原来首次安装直接运行 xwPF 的安装命令，它会直连 GitHub 下载脚本和 realm，国内机器会卡住或失败。
2.现在 xwPF 脚本和 realm 压缩包都由 Nimbus 下载（国内自动走代理），再交给 xwPF 自己的安装流程：跳过它直连 GitHub 的脚本下载，realm 通过它的「离线安装」选项使用已下载的压缩包。配置文件和 systemd / OpenRC 服务仍由 xwPF 生成，与原来的安装结果一致。
3.realm 版本取 xwPF 中适配过的 REALM_VERSION。xwPF 安装时仍会查询一次 GitHub 上的最新版本，国内机器会等待约 10 秒后自动使用该版本继续。
4.安装和「更新 xwPF 脚本和 realm」改为共用同一套下载代码。
------------------------
2026-10-28   v1.2.19
修复开启密钥登录 / 切换密码登录后 SSH 端口被改回 22。
1.原因：开启密钥登录、切换回密码登录（含新机开荒第 2 步修改 root 密码）时会删除 /etc/ssh/sshd_config.d/ 下的全部文件，而 DD 脚本（bin456789/reinstall）和部分云镜像把 SSH 端口写在这里，删掉后端口回到 22，按原端口就连不上了。还会顺带删掉 SSH 客户端的 /etc/ssh/ssh_config.d/。
2.现在只把 sshd_config.d 中与登录方式有关的设置（PermitRootLogin、PasswordAuthentication、PubkeyAuthentication、ChallengeResponseAuthentication、KbdInteractiveAuthentication）注释掉，标记为「# [nimbus 已停用]」，端口等其他配置保留；不再动 ssh_config.d。
3.已受影响的机器：用原来的 22 端口登录，再用 nb 修改 SSH 端口（新机开荒第 13 步）改回原端口。
------------------------
