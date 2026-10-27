#!/bin/bash
# shellcheck disable=SC2154  # isp_info / country / masked_ip 等变量来自配置文件
# Nimbus TG-bot 资源监控：CPU / 内存 / 硬盘 / 流量超过阈值时推送 Telegram 告警
# 配置由 nimbus 菜单「TG-bot系统监控预警」交互生成，写入 /etc/nimbus/tg-notify.conf
# 部署位置 /root/TG-check-notify.sh，由 systemd 服务 tg-check-notify.service 托管

# 固定 C 语言环境，避免 free/df 输出被本地化后 awk 匹配失败
export LC_ALL=C

CONFIG_FILE="/etc/nimbus/tg-notify.conf"

if [ ! -r "$CONFIG_FILE" ]; then
    echo "配置文件不存在或不可读: $CONFIG_FILE，请先运行 nimbus 菜单「TG-bot系统监控预警」" >&2
    exit 1
fi
# shellcheck source=/dev/null
. "$CONFIG_FILE"

for required in TELEGRAM_BOT_TOKEN CHAT_ID isp_info country masked_ip \
    CPU_THRESHOLD MEMORY_THRESHOLD DISK_THRESHOLD NETWORK_THRESHOLD_GB; do
    if [ -z "${!required}" ]; then
        echo "配置不完整: $CONFIG_FILE 缺少 $required，请重新运行 nimbus 菜单配置" >&2
        exit 1
    fi
done

# 发送Telegram通知的函数（Token 经 stdin 传给 curl，不出现在进程参数中）
# 配置了 MONITOR_THREAD_ID 时发到话题群的对应话题
send_tg_notification() {
    local MESSAGE=$1
    local -a thread_args=()
    [ -n "${MONITOR_THREAD_ID:-}" ] && thread_args=(--data-urlencode "message_thread_id=${MONITOR_THREAD_ID}")
    printf 'url = "https://api.telegram.org/bot%s/sendMessage"\n' "$TELEGRAM_BOT_TOKEN" |
        curl -s -m 10 -X POST -K - \
            --data-urlencode "chat_id=${CHAT_ID}" \
            "${thread_args[@]}" \
            --data-urlencode "text=${MESSAGE}" >/dev/null
}


# 获取CPU使用率
get_cpu_usage() {
    awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
        <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat)
}

# 获取内存使用率
get_memory_usage() {
    free | awk '/Mem/ {printf("%.0f"), $3/$2 * 100}'
}

# 获取硬盘使用率
get_disk_usage() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# 获取总的接收流量（以 GB 为单位）
get_rx_bytes() {
    awk 'BEGIN { rx_total = 0 }
        # 匹配常见的公网网卡命名: eth*, ens*, enp*, eno*
        $1 ~ /^(eth|ens|enp|eno)[0-9]+/ { rx_total += $2 }
        END {
            printf("%.2f", rx_total / (1024 * 1024 * 1024));
        }' /proc/net/dev
}

# 获取总的发送流量（以 GB 为单位）
get_tx_bytes() {
    awk 'BEGIN { tx_total = 0 }
        # 匹配常见的公网网卡命名: eth*, ens*, enp*, eno*
        $1 ~ /^(eth|ens|enp|eno)[0-9]+/ { tx_total += $10 }
        END {
            printf("%.2f", tx_total / (1024 * 1024 * 1024));
        }' /proc/net/dev
}

# 检查并发送通知
check_and_notify() {
    local USAGE="$1"
    local TYPE="$2"
    local THRESHOLD="$3"
    # shellcheck disable=SC2034  # 保留原接口的第 4 个参数
    local CURRENT_VALUE="$4"

    if (( $(echo "$USAGE > $THRESHOLD" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的 $TYPE 使用率已达到 $USAGE%，超过阈值 $THRESHOLD%。"
    fi
}

# 主循环
while true; do
    CPU_USAGE=$(get_cpu_usage)
    MEMORY_USAGE=$(get_memory_usage)
    DISK_USAGE=$(get_disk_usage)
    RX_GB=$(get_rx_bytes)
    TX_GB=$(get_tx_bytes)

    check_and_notify "$CPU_USAGE" "CPU" "$CPU_THRESHOLD" "$CPU_USAGE"
    check_and_notify "$MEMORY_USAGE" "内存" "$MEMORY_THRESHOLD" "$MEMORY_USAGE"
    check_and_notify "$DISK_USAGE" "硬盘" "$DISK_THRESHOLD" "$DISK_USAGE"

    # 检查入站流量是否超过阈值
    if (( $(echo "$RX_GB > $NETWORK_THRESHOLD_GB" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的入站流量已达到 ${RX_GB}GB，超过阈值 ${NETWORK_THRESHOLD_GB}GB。"
    fi

    # 检查出站流量是否超过阈值
    if (( $(echo "$TX_GB > $NETWORK_THRESHOLD_GB" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的出站流量已达到 ${TX_GB}GB，超过阈值 ${NETWORK_THRESHOLD_GB}GB。"
    fi

    # 休眠5分钟
    sleep 300
done
