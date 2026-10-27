#!/bin/bash
# Nimbus TG-bot SSH 登录提醒
# 部署位置 /usr/local/bin/tg-ssh-notify.sh，由 /etc/ssh/sshrc 在后台调用：
#   [ -n "$SSH_TTY" ] && /usr/local/bin/tg-ssh-notify.sh </dev/null >/dev/null 2>&1 &
# 配置由 nimbus 菜单「TG-bot系统监控预警」生成；配置缺失或不可读时静默退出，不影响登录
# 非 root 用户登录时读不到 0600 的配置文件，通过 sudoers 规则（/etc/sudoers.d/nimbus-tg-ssh）
# 以 root 重新运行本脚本，登录 IP 作为参数传入，登录名取 SUDO_USER

CONFIG_FILE="/etc/nimbus/tg-notify.conf"
SELF="/usr/local/bin/tg-ssh-notify.sh"

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -n "$SELF" "$(echo "$SSH_CONNECTION" | awk '{print $1}')" 2>/dev/null
    exit 0
fi

if [ -n "${SUDO_USER:-}" ]; then
    # 经 sudo 运行：参数可由任意本地用户传入，只接受 IP 字符
    IP="$1"
    [[ "$IP" =~ ^[0-9A-Fa-f.:]{2,45}$ ]] || IP="未知"
    USERNAME="$SUDO_USER"
else
    IP=$(echo "$SSH_CONNECTION" | awk '{print $1}')
    USERNAME=$(whoami)
fi

[ -r "$CONFIG_FILE" ] || exit 0
# shellcheck source=/dev/null
. "$CONFIG_FILE" 2>/dev/null || exit 0
[ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$CHAT_ID" ] || exit 0

TIME=$(date +"%Y年%m月%d日 %H:%M:%S")
# 查询IP地址对应的地区信息
LOCATION=$(curl -s -m 5 "http://opendata.baidu.com/api.php?query=$IP&co=&resource_id=6006&oe=utf8&format=json" 2>/dev/null |
    jq -r '.data[0].location // empty' 2>/dev/null)
[ -n "$LOCATION" ] || LOCATION="未知"
# 发送Telegram消息
MESSAGE="ℹ️ 登录信息：
登录机器：${isp_info:-Unknown}-${country:-Unknown}-${masked_ip:-Unknown}
登录名：$USERNAME
登录IP：$IP
登录时间：$TIME
登录地区：$LOCATION"

# 配置了 SSH_THREAD_ID 时发到话题群的对应话题
thread_args=()
[ -n "${SSH_THREAD_ID:-}" ] && thread_args=(--data-urlencode "message_thread_id=${SSH_THREAD_ID}")

# Token 经 stdin 传给 curl，不出现在进程参数中
printf 'url = "https://api.telegram.org/bot%s/sendMessage"\n' "$TELEGRAM_BOT_TOKEN" |
    curl -s -m 10 -X POST -K - \
        --data-urlencode "chat_id=${CHAT_ID}" \
        "${thread_args[@]}" \
        --data-urlencode "text=${MESSAGE}" >/dev/null 2>&1
