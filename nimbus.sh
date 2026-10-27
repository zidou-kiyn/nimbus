#!/bin/bash
# Nimbus · 云服务器工具箱  https://github.com/zidou-kiyn/nimbus
# Copyright 2026 zidou-kiyn. Licensed under Apache-2.0; derived from kejilion/sh, see NOTICE.
sh_v="1.2.21"


gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_cyan='\033[96m'


canshu="default"



# GitHub 下载代理（CN/V6 模式使用）；公共代理，失效时改这里即可，备选: https://gh-proxy.com/
gh_proxy_mirror="https://ghfast.top/"
# 本仓库的国内镜像（cnb.cool，GitHub 每次 push 由 Actions 自动同步）。GitHub 和代理都连不上（无国际出口）时使用
nb_cnb_raw="https://cnb.cool/zidou-kiyn/nimbus/-/git/raw/main/"

quanju_canshu() {
if [ "$canshu" = "CN" ]; then
	zhushi=0
	gh_proxy="$gh_proxy_mirror"
elif [ "$canshu" = "V6" ]; then
	zhushi=1
	gh_proxy="$gh_proxy_mirror"
else
	zhushi=1  # 0 表示执行，1 表示不执行
	gh_proxy="https://"
fi

gh_https_url="https://"

}
quanju_canshu



canshu_v6() {
	if grep -q '^canshu="V6"' /usr/local/bin/nb > /dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/nimbus.sh
	elif grep -q '^canshu="V6"' ~/nimbus.sh.bak > /dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/nimbus.sh
	fi
}



canshu_v6

# 内容不同才替换；先写临时文件再 mv，避免改写正在执行的脚本
nb_atomic_copy() {
	local src="$1" dst="$2"
	cmp -s "$src" "$dst" 2>/dev/null && return 0
	cp -f "$src" "$dst.nbtmp.$$" 2>/dev/null || return 1
	chmod 755 "$dst.nbtmp.$$" 2>/dev/null
	mv -f "$dst.nbtmp.$$" "$dst" 2>/dev/null || { rm -f "$dst.nbtmp.$$"; return 1; }
}

# 安装 ~/nimbus.sh 与快捷命令 nb
# - 从文件运行（nb / ./nimbus.sh）：复制自身
# - 通过 bash <(curl ...) 运行：磁盘上没有脚本文件，下载一份；直连失败则走镜像并切换为 CN 模式
nimbus_self_install() {
	local src tmp url had_nb=false
	local raw_url="https://raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh"
	[ -x /usr/local/bin/nb ] && had_nb=true
	src=$(readlink -f "$0" 2>/dev/null)

	if [ -f "$src" ] && grep -q '^sh_v=' "$src" 2>/dev/null; then
		[ "$src" = "$(readlink -f ~/nimbus.sh 2>/dev/null)" ] || nb_atomic_copy "$src" ~/nimbus.sh
	elif ! grep -q "^sh_v=\"$sh_v\"" ~/nimbus.sh 2>/dev/null; then
		tmp=$(mktemp 2>/dev/null) || return 0
		for url in "$raw_url" "${gh_proxy_mirror}${raw_url}" "${nb_cnb_raw}nimbus.sh"; do
			if curl -fsSL --connect-timeout 5 -m 60 -o "$tmp" "$url" 2>/dev/null && head -1 "$tmp" | grep -q '^#!/bin/bash' && grep -q '^sh_v=' "$tmp"; then
				if [ "$url" != "$raw_url" ]; then
					sed -i 's/^canshu="default"/canshu="CN"/' "$tmp"
					canshu="CN"
					quanju_canshu
				fi
				nb_atomic_copy "$tmp" ~/nimbus.sh
				break
			fi
		done
		rm -f "$tmp"
	fi

	[ -f ~/nimbus.sh ] || return 0
	chmod +x ~/nimbus.sh 2>/dev/null
	if [ "$EUID" -eq 0 ]; then
		nb_atomic_copy ~/nimbus.sh /usr/local/bin/nb
		[ "$(readlink -f /usr/bin/nb 2>/dev/null)" = /usr/local/bin/nb ] || ln -sf /usr/local/bin/nb /usr/bin/nb 2>/dev/null
		[ "$had_nb" = false ] && [ -x /usr/local/bin/nb ] && NB_FIRST_INSTALL=true
	fi
}
nimbus_self_install

# 脚本自动更新的定时任务（参数: 分钟）
nb_update_cron_line() {
	echo "$1 2 * * * bash ~/nimbus.sh self-update >/dev/null 2>&1"
}

# 旧版自动更新任务是 bash -c '…' 内联命令，引号嵌套导致 CN/V6 设置每次更新后被还原；迁移为 nb self-update
nb_migrate_update_cron() {
	command -v crontab >/dev/null 2>&1 || return 0
	local min
	min=$(crontab -l 2>/dev/null | grep -F 'nimbus_tmp.XXXXXX' | awk 'NR==1{print $1}')
	[ -n "$min" ] || return 0
	case "$min" in *[!0-9]*) min=$(shuf -i 0-59 -n 1) ;; esac
	(crontab -l 2>/dev/null | grep -v "nimbus.sh"; nb_update_cron_line "$min") | crontab -
}
nb_migrate_update_cron



ip_address() {

get_public_ip() {
	curl -s --connect-timeout 3 -m 5 https://ipinfo.io/ip && echo
}

get_local_ip() {
	ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || \
	hostname -I 2>/dev/null | awk '{print $1}' || \
	ifconfig 2>/dev/null | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1
}

public_ip=$(get_public_ip)
isp_info=$(curl -s --max-time 3 http://ipinfo.io/org)


if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
  ipv4_address=$(get_local_ip)
else
  ipv4_address="$public_ip"
fi


# ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}



install() {
	if [ $# -eq 0 ]; then
		echo "未提供软件包参数!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_cyan}正在安装 $package...${gl_bai}"
			if command -v dnf &>/dev/null; then
				dnf -y update
				dnf install -y epel-release
				dnf install -y "$package"
			elif command -v yum &>/dev/null; then
				yum -y update
				yum install -y epel-release
				yum install -y "$package"
			elif command -v apt &>/dev/null; then
				apt update -y
				apt install -y "$package"
			elif command -v apk &>/dev/null; then
				apk update
				apk add "$package"
			elif command -v pacman &>/dev/null; then
				pacman -Syu --noconfirm
				pacman -S --noconfirm "$package"
			elif command -v zypper &>/dev/null; then
				zypper refresh
				zypper install -y "$package"
			elif command -v opkg &>/dev/null; then
				opkg update
				opkg install "$package"
			elif command -v pkg &>/dev/null; then
				pkg update
				pkg install -y "$package"
			else
				echo "未知的包管理器!"
				return 1
			fi
		fi
	done
}


check_disk_space() {
	local required_gb=$1
	local path=${2:-/}

	mkdir -p "$path"

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang}提示: ${gl_bai}磁盘空间不足！"
		echo "当前可用空间: $((available_space_mb/1024))G"
		echo "最小需求空间: ${required_gb}G"
		echo "无法继续安装，请清理磁盘空间后重试。"
		break_end
		nimbus_home
	fi
}



remove() {
	if [ $# -eq 0 ]; then
		echo "未提供软件包参数!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_cyan}正在卸载 $package...${gl_bai}"
		if command -v dnf &>/dev/null; then
			dnf remove -y "$package"
		elif command -v yum &>/dev/null; then
			yum remove -y "$package"
		elif command -v apt &>/dev/null; then
			apt purge -y "$package"
		elif command -v apk &>/dev/null; then
			apk del "$package"
		elif command -v pacman &>/dev/null; then
			pacman -Rns --noconfirm "$package"
		elif command -v zypper &>/dev/null; then
			zypper remove -y "$package"
		elif command -v opkg &>/dev/null; then
			opkg remove "$package"
		elif command -v pkg &>/dev/null; then
			pkg delete -y "$package"
		else
			echo "未知的包管理器!"
			return 1
		fi
	done
}


# 通用 systemctl 函数，适用于各种发行版
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 重启服务
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务已重启。"
	else
		echo "错误：重启 $1 服务失败。"
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务已启动。"
	else
		echo "错误：启动 $1 服务失败。"
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务已停止。"
	else
		echo "错误：停止 $1 服务失败。"
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务状态已显示。"
	else
		echo "错误：无法显示 $1 服务状态。"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME 已设置为开机自启。"
}



break_end() {
	  echo -e "${gl_lv}操作完成${gl_bai}"
	  echo "按任意键继续..."
	  read -n 1 -s -r -p ""
	  echo ""
	  clear
}

nimbus_home() {
			cd ~
			nimbus_main
}



install_add_docker_cn() {

local country=$(nb_country)
if [ "$country" = "CN" ]; then
	cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
	"https://docker.1ms.run",
	"https://docker.m.ixdev.cn",
	"https://hub.rat.dev",
	"https://dockerproxy.net",
	"https://docker-registry.nmqu.com",
	"https://docker.amingg.com",
	"https://docker.hlmirror.com",
	"https://hub1.nat.tf",
	"https://hub2.nat.tf",
	"https://hub3.nat.tf",
	"https://docker.m.daocloud.io",
	"https://docker.367231.xyz",
	"https://hub.1panel.dev",
	"https://dockerproxy.cool",
	"https://docker.apiba.cn",
	"https://proxy.vvvv.ee"
  ]
}
EOF
fi


enable docker
start docker
restart docker

}



linuxmirrors_install_docker() {

local country=$(nb_country)
if [ "$country" = "CN" ]; then
	bash <(curl -sSL https://linuxmirrors.cn/docker.sh) \
	  --source mirrors.huaweicloud.com/docker-ce \
	  --source-registry docker.1ms.run \
	  --protocol https \
	  --use-intranet-source false \
	  --install-latest true \
	  --close-firewall false \
	  --ignore-backup-tips
else
	bash <(curl -sSL https://linuxmirrors.cn/docker.sh) \
	  --source download.docker.com \
	  --source-registry registry.hub.docker.com \
	  --protocol https \
	  --use-intranet-source false \
	  --install-latest true \
	  --close-firewall false \
	  --ignore-backup-tips
fi

install_add_docker_cn

}



install_add_docker() {
	echo -e "${gl_cyan}正在安装docker环境...${gl_bai}"
	if command -v apt &>/dev/null || command -v yum &>/dev/null || command -v dnf &>/dev/null; then
		linuxmirrors_install_docker
	else
		install docker docker-compose
		install_add_docker_cn

	fi
	sleep 2
}


install_docker() {
	if ! command -v docker &>/dev/null; then
		install_add_docker
	fi
}


docker_ps() {
while true; do
	clear
	echo "Docker容器列表"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "容器操作"
	echo "------------------------"
	echo "1. 创建新的容器"
	echo "------------------------"
	echo "2. 启动指定容器             6. 启动所有容器"
	echo "3. 停止指定容器             7. 停止所有容器"
	echo "4. 删除指定容器             8. 删除所有容器"
	echo "5. 重启指定容器             9. 重启所有容器"
	echo "------------------------"
	echo "11. 进入指定容器           12. 查看容器日志"
	echo "13. 查看容器网络           14. 查看容器占用"
	echo "------------------------"
	echo "15. 开启容器端口访问       16. 关闭容器端口访问"
	echo "------------------------"
	echo "0. 返回上一级选单"
	echo "------------------------"
	read -e -p "请输入你的选择: " sub_choice
	case $sub_choice in
		1)
			read -e -p "请输入创建命令: " dockername
			$dockername
			;;
		2)
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker start $dockername
			;;
		3)
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker stop $dockername
			;;
		4)
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker rm -f $dockername
			;;
		5)
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker restart $dockername
			;;
		6)
			docker start $(docker ps -a -q)
			;;
		7)
			docker stop $(docker ps -q)
			;;
		8)
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "无效的选择，请输入 Y 或 N。"
				;;
			esac
			;;
		9)
			docker restart $(docker ps -q)
			;;
		11)
			read -e -p "请输入容器名: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			read -e -p "请输入容器名: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"
			for container_id in $container_ids; do
				local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")
				local container_name=$(echo "$container_info" | awk '{print $1}')
				local network_info=$(echo "$container_info" | cut -d' ' -f2-)
				while IFS= read -r line; do
					local network_name=$(echo "$line" | awk '{print $1}')
					local ip_address=$(echo "$line" | awk '{print $2}')
					printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
				done <<< "$network_info"
			done
			break_end
			;;
		14)
			docker stats --no-stream
			break_end
			;;

		15)
			read -e -p "请输入容器名: " docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address" || return 1
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			read -e -p "请输入容器名: " docker_name
			ip_address
			block_container_port "$docker_name" "$ipv4_address" || return 1
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done
}


docker_image() {
while true; do
	clear
	echo "Docker镜像列表"
	docker image ls
	echo ""
	echo "镜像操作"
	echo "------------------------"
	echo "1. 获取指定镜像             3. 删除指定镜像"
	echo "2. 更新指定镜像             4. 删除所有镜像"
	echo "------------------------"
	echo "0. 返回上一级选单"
	echo "------------------------"
	read -e -p "请输入你的选择: " sub_choice
	case $sub_choice in
		1)
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_cyan}正在获取镜像: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_cyan}正在更新镜像: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "无效的选择，请输入 Y 或 N。"
				;;
			esac
			;;
		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done


}



check_crontab_installed() {
	if ! command -v crontab >/dev/null 2>&1; then
		install_crontab
	fi
}



install_crontab() {
	local package_manager

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|debian|kali)
				apt update
				apt install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			centos|rhel|almalinux|rocky|fedora)
				if command -v dnf >/dev/null 2>&1; then
					package_manager=dnf
				elif command -v yum >/dev/null 2>&1; then
					package_manager=yum
				else
					echo "错误: 未找到 DNF/YUM，无法安装 cronie"
					return 1
				fi
				"$package_manager" install -y cronie || return 1
				/bin/systemctl enable --now crond.service || return 1
				command -v crontab >/dev/null 2>&1 || return 1
				/bin/systemctl is-active --quiet crond.service || return 1
				;;
			alpine)
				apk add --no-cache cronie
				rc-update add crond
				rc-service crond start
				;;
			arch|manjaro)
				pacman -S --noconfirm cronie
				systemctl enable cronie
				systemctl start cronie
				;;
			opensuse|suse|opensuse-tumbleweed)
				zypper install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			iStoreOS|openwrt|ImmortalWrt|lede)
				opkg update
				opkg install cron
				/etc/init.d/cron enable
				/etc/init.d/cron start
				;;
			FreeBSD)
				pkg install -y cronie
				sysrc cron_enable="YES"
				service cron start
				;;
			*)
				echo "不支持的发行版: $ID"
				return
				;;
		esac
	else
		echo "无法确定操作系统。"
		return
	fi

	command -v crontab >/dev/null 2>&1 || return 1
	echo -e "${gl_lv}crontab 已安装且 cron 服务正在运行。${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 检查配置文件是否存在，如果不存在则创建文件并写入默认设置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# 使用jq处理配置文件的更新
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 检查当前配置是否已经有 ipv6 设置
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 更新配置，开启 IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 对比原始配置与新配置
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}当前已开启ipv6访问${gl_bai}"
		else
			echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
			restart docker
		fi
	fi
}


docker_ipv6_off() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"

	# 检查配置文件是否存在
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}配置文件不存在${gl_bai}"
		return
	fi

	# 读取当前配置
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# 使用jq处理配置文件的更新
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 检查当前的 ipv6 状态
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 对比原始配置与新配置
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}当前已关闭ipv6访问${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}已成功关闭ipv6访问${gl_bai}"
	fi
}



ip6tables_available() {
	command -v ip6tables >/dev/null 2>&1 && ip6tables -L >/dev/null 2>&1
}

# 去掉 fail2ban 的链（f2b-*）：它们由 fail2ban 自己维护，存进去开机恢复后，
# 当时被封的 IP 会变成永久封禁（fail2ban 不知道这些规则，也不会解封）
nb_strip_f2b_rules() {
	grep -vE '^:f2b-|^-A f2b-|-j f2b-'
}

save_iptables_rules() {
	mkdir -p /etc/iptables
	local rules_temp rules6_temp out
	rules_temp=$(mktemp /etc/iptables/.rules.v4.XXXXXX) || return 1
	ip6tables_available && rules6_temp=$(mktemp /etc/iptables/.rules.v6.XXXXXX)
	if ! out=$(iptables-save) || ! printf '%s\n' "$out" | nb_strip_f2b_rules > "$rules_temp" || ! mv -f -- "$rules_temp" /etc/iptables/rules.v4; then
		rm -f -- "$rules_temp" "$rules6_temp"
		return 1
	fi
	if [ -n "${rules6_temp:-}" ]; then
		if ! out=$(ip6tables-save) || ! printf '%s\n' "$out" | nb_strip_f2b_rules > "$rules6_temp" || ! mv -f -- "$rules6_temp" /etc/iptables/rules.v6; then
			rm -f -- "$rules6_temp"
			return 1
		fi
	fi
	check_crontab_installed || return 1
	crontab -l | grep -v 'iptables-restore' | grep -v 'ip6tables-restore' | crontab - > /dev/null 2>&1 || return 1
	(crontab -l ; echo '@reboot iptables-restore < /etc/iptables/rules.v4') | crontab - > /dev/null 2>&1 || return 1
	if [ -n "${rules6_temp:-}" ]; then
		(crontab -l ; echo '@reboot ip6tables-restore < /etc/iptables/rules.v6') | crontab - > /dev/null 2>&1 || return 1
	fi

}



iptables_open() {
	install iptables || return 1
	save_iptables_rules || return 1
	iptables -P INPUT ACCEPT || return 1
	iptables -P FORWARD ACCEPT || return 1
	iptables -P OUTPUT ACCEPT || return 1
	iptables -F || return 1

	ip6tables -P INPUT ACCEPT || return 1
	ip6tables -P FORWARD ACCEPT || return 1
	ip6tables -P OUTPUT ACCEPT || return 1
	ip6tables -F || return 1

}



open_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "请提供至少一个端口号"
		return 1
	fi

	install iptables || return 1
	local ipv6_ready=false
	ip6tables_available && ipv6_ready=true

	for port in "${ports[@]}"; do
		# 删除已存在的关闭规则
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 添加打开规则
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT || return 1
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT || return 1
			echo "已打开端口 $port"
		fi
	done

	if [ "$ipv6_ready" = true ]; then
		for port in "${ports[@]}"; do
			ip6tables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
			ip6tables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

			if ! ip6tables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
				ip6tables -I INPUT 1 -p tcp --dport $port -j ACCEPT || return 1
			fi

			if ! ip6tables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
				ip6tables -I INPUT 1 -p udp --dport $port -j ACCEPT || return 1
			fi
		done
	fi

	save_iptables_rules || return 1
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "请提供至少一个端口号"
		return 1
	fi

	install iptables || return 1
	local ipv6_ready=false
	ip6tables_available && ipv6_ready=true

	for port in "${ports[@]}"; do
		# 删除已存在的打开规则
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 添加关闭规则
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP || return 1
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP || return 1
			echo "已关闭端口 $port"
		fi
	done

	if [ "$ipv6_ready" = true ]; then
		for port in "${ports[@]}"; do
			ip6tables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
			ip6tables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

			if ! ip6tables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
				ip6tables -I INPUT 1 -p tcp --dport $port -j DROP || return 1
			fi

			if ! ip6tables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
				ip6tables -I INPUT 1 -p udp --dport $port -j DROP || return 1
			fi
		done

		# 删除已存在的规则（如果有）
		ip6tables -D INPUT -i lo -j ACCEPT 2>/dev/null
		ip6tables -D FORWARD -i lo -j ACCEPT 2>/dev/null

		# 插入新规则到第一条
		ip6tables -I INPUT 1 -i lo -j ACCEPT || return 1
		ip6tables -I FORWARD 1 -i lo -j ACCEPT || return 1
	fi

	# 删除已存在的规则（如果有）
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 插入新规则到第一条
	iptables -I INPUT 1 -i lo -j ACCEPT || return 1
	iptables -I FORWARD 1 -i lo -j ACCEPT || return 1

	save_iptables_rules || return 1
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "请提供至少一个IP地址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "已放行IP $ip"
		fi
	done

	save_iptables_rules
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "请提供至少一个IP地址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "已阻止IP $ip"
		fi
	done

	save_iptables_rules
}



enable_ddos_defense() {
	# 开启防御 DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

}

# 关闭DDoS防御
disable_ddos_defense() {
	# 关闭防御 DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

}



# 管理国家IP规则的函数
manage_country_rules() {
	local action="$1"
	shift  # 去掉第一个参数，剩下的全是国家代码

	install ipset

	for country_code in "$@"; do
		local ipset_name="${country_code,,}_block"
		local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

		case "$action" in
			block)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "错误：下载 $country_code 的 IP 区域文件失败"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "已成功阻止 $country_code 的 IP 地址"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "错误：下载 $country_code 的 IP 区域文件失败"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "已成功允许 $country_code 的 IP 地址"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "已成功解除 $country_code 的 IP 地址限制"
				;;

			*)
				echo "用法: manage_country_rules {block|allow|unblock} <country_code...>"
				;;
		esac
	done
}



iptables_panel() {
  root_use
  install iptables
  save_iptables_rules
  while true; do
		  clear
		  echo "高级防火墙管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "防火墙管理"
		  echo "------------------------"
		  echo "1.  开放指定端口                 2.  关闭指定端口"
		  echo "3.  开放所有端口                 4.  关闭所有端口"
		  echo "------------------------"
		  echo "5.  IP白名单                  	 6.  IP黑名单"
		  echo "7.  清除指定IP"
		  echo "------------------------"
		  echo "11. 允许PING                  	 12. 禁止PING"
		  echo "------------------------"
		  echo "13. 启动DDOS防御                 14. 关闭DDOS防御"
		  echo "------------------------"
		  echo "15. 阻止指定国家IP               16. 仅允许指定国家IP"
		  echo "17. 解除指定国家IP限制"
		  echo "------------------------"
		  echo "0. 返回上一级选单"
		  echo "------------------------"
		  read -e -p "请输入你的选择: " sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "请输入开放的端口号: " o_port
				  open_port $o_port
				  ;;
			  2)
				  read -e -p "请输入关闭的端口号: " c_port
				  close_port $c_port
				  ;;
			  3)
				  # 开放所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT ACCEPT
				  iptables -P FORWARD ACCEPT
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  if ip6tables_available; then
					  ip6tables -F
					  ip6tables -X
					  ip6tables -P INPUT ACCEPT
					  ip6tables -P FORWARD ACCEPT
					  ip6tables -P OUTPUT ACCEPT
					  ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
					  ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
					  ip6tables -A INPUT -i lo -j ACCEPT
					  ip6tables -A FORWARD -i lo -j ACCEPT
					  ip6tables -A INPUT -p tcp --dport $current_port -j ACCEPT
					  ip6tables-save > /etc/iptables/rules.v6
				  fi
				  save_iptables_rules
				  ;;
			  4)
				  # 关闭所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT DROP
				  iptables -P FORWARD DROP
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  if ip6tables_available; then
					  ip6tables -F
					  ip6tables -X
					  ip6tables -P INPUT DROP
					  ip6tables -P FORWARD DROP
					  ip6tables -P OUTPUT ACCEPT
					  ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
					  ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
					  ip6tables -A INPUT -i lo -j ACCEPT
					  ip6tables -A FORWARD -i lo -j ACCEPT
					  ip6tables -A INPUT -p tcp --dport $current_port -j ACCEPT
					  ip6tables-save > /etc/iptables/rules.v6
				  fi
				  save_iptables_rules
				  ;;

			  5)
				  # IP 白名单
				  read -e -p "请输入放行的IP或IP段: " o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 黑名单
				  read -e -p "请输入封锁的IP或IP段: " c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 清除指定 IP
				  read -e -p "请输入清除的IP: " d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  save_iptables_rules
				  ;;
			  11)
				  # 允许 PING
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  save_iptables_rules
				  ;;
			  12)
				  # 禁用 PING
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  save_iptables_rules
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "请输入阻止的国家代码（多个国家代码可用空格隔开如 CN US JP）: " country_code
				  manage_country_rules block $country_code
				  ;;
			  16)
				  read -e -p "请输入允许的国家代码（多个国家代码可用空格隔开如 CN US JP）: " country_code
				  manage_country_rules allow $country_code
				  ;;

			  17)
				  read -e -p "请输入清除的国家代码（多个国家代码可用空格隔开如 CN US JP）: " country_code
				  manage_country_rules unblock $country_code
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}



add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 获取当前系统中所有的 swap 分区
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍历并删除所有的 swap 分区
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 确保 /swapfile 不再被使用
	swapoff /swapfile

	# 删除旧的 /swapfile
	rm -f /swapfile

	# 创建新的 swap 分区
	fallocate -l ${new_swap}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	sed -i '/\/swapfile/d' /etc/fstab
	echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

	if [ -f /etc/alpine-release ]; then
		echo "nohup swapon /swapfile" > /etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	fi

	echo -e "虚拟内存大小已调整为${gl_huang}${new_swap}${gl_bai}M"
}



check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 判断是否需要创建虚拟内存
[ "$swap_total" -gt 0 ] || add_swap 1024


}



prefer_ipv4() {
grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null \
	|| echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
echo "已切换为 IPv4 优先"
}



check_docker_app_ip() {
echo "------------------------"
echo "访问地址:"
ip_address



if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:${docker_port}"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:${docker_port}"
fi



}



get_container_ipv4_addresses() {
	local container_name_or_id=$1
	local container_ips

	container_ips=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{if .IPAddress}}{{println .IPAddress}}{{end}}{{end}}' "$container_name_or_id" 2>/dev/null) || return 1
	printf '%s\n' "$container_ips" | awk 'NF && !seen[$0]++'
}

ensure_docker_user_rule() {
	if ! iptables -C DOCKER-USER "$@" &>/dev/null; then
		iptables -I DOCKER-USER "$@"
	fi
}

remove_docker_user_rule() {
	if iptables -C DOCKER-USER "$@" &>/dev/null; then
		iptables -D DOCKER-USER "$@"
	fi
}

block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2
	local container_ips
	local container_ip

	# 获取容器在所有 Docker 网络中的 IPv4 地址，逐个应用规则。
	container_ips=$(get_container_ipv4_addresses "$container_name_or_id")
	if [ -z "$container_ips" ]; then
		echo "错误：无法获取容器 ${container_name_or_id} 的 IPv4 地址。" >&2
		return 1
	fi

	install iptables || return 1

	while IFS= read -r container_ip; do
		ensure_docker_user_rule -p tcp -d "$container_ip" -j DROP || return 1
		ensure_docker_user_rule -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -p udp -d "$container_ip" -j DROP || return 1
		ensure_docker_user_rule -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		ensure_docker_user_rule -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT || return 1
	done <<< "$container_ips"

	echo "已阻止IP+端口访问该服务"
	save_iptables_rules || return 1
}



clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2
	local container_ips
	local container_ip

	# 获取容器在所有 Docker 网络中的 IPv4 地址，逐个清除规则。
	container_ips=$(get_container_ipv4_addresses "$container_name_or_id")
	if [ -z "$container_ips" ]; then
		echo "错误：无法获取容器 ${container_name_or_id} 的 IPv4 地址。" >&2
		return 1
	fi

	install iptables || return 1

	while IFS= read -r container_ip; do
		remove_docker_user_rule -p tcp -d "$container_ip" -j DROP || return 1
		remove_docker_user_rule -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -p udp -d "$container_ip" -j DROP || return 1
		remove_docker_user_rule -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT || return 1
		remove_docker_user_rule -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT || return 1
	done <<< "$container_ips"

	echo "已允许IP+端口访问该服务"
	save_iptables_rules || return 1
}



f2b_status() {
	 fail2ban-client reload
	 sleep 3
	 fail2ban-client status
}

f2b_status_xxx() {
	fail2ban-client status $xxx
}

check_f2b_status() {
	if command -v fail2ban-client >/dev/null 2>&1; then
		check_f2b_status="${gl_lv}已安装${gl_bai}"
	else
		check_f2b_status="${gl_hui}未安装${gl_bai}"
	fi
}

# sshd 的端口列表（逗号分隔）：配置中的 Port/ListenAddress ∪ sshd 进程实际监听的端口
# - sshd -T 在 Debian/Ubuntu 缺少 /run/sshd 时会失败，回退为直接解析 sshd_config 及 sshd_config.d/*.conf
# - 合并实际监听端口：Ubuntu ssh.socket 等改了配置却仍在旧端口监听的情况也能覆盖
nb_ssh_ports() {
	local sshd_bin ports
	sshd_bin=$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)
	ports=$(
		{
			if [ -x "$sshd_bin" ] && "$sshd_bin" -T >/dev/null 2>&1; then
				"$sshd_bin" -T 2>/dev/null | awk '$1=="port"{print $2} $1=="listenaddress" && match($2,/:[0-9]+$/){print substr($2,RSTART+1)}'
			else
				cat /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk 'tolower($1)=="port"{print $2}'
			fi
			ss -Htlnp 2>/dev/null | awk '/"sshd"/{n=split($4,a,":"); print a[n]}'
		} | grep -E '^[0-9]+$' | sort -un | paste -sd, -
	)
	echo "${ports:-22}"
}

# fail2ban 中所有已启用、与 SSH 相关的 jail（Debian/CentOS: sshd；Alpine: sshd + sshd-ddos）
f2b_ssh_jails() {
	fail2ban-client -d 2>/dev/null | sed -n "s/^\['add', '\([^']*\)'.*/\1/p" | grep -i ssh | sort -u
}

# 主 SSH jail 名称（查看状态、写基础参数用）
f2b_ssh_jail() {
	local jails
	jails=$(f2b_ssh_jails)
	if [ -z "$jails" ] || echo "$jails" | grep -qx sshd; then
		echo sshd
	else
		echo "$jails" | head -n1
	fi
}

# 在 ini 文件的 [section] 中设置 key = value（没有该段则追加到末尾）
f2b_ini_set() {
	local file=$1 section=$2 key=$3 value=$4
	awk -v s="[$section]" -v k="$key" -v v="$value" '
		function emit() { if (insec && !done) { print k " = " v; done = 1 } }
		/^[[:space:]]*\[/ { t = $0; gsub(/[[:space:]]/, "", t); emit(); insec = (t == s); if (insec) found = 1; print; next }
		insec && $0 ~ ("^[[:space:]]*" k "[[:space:]]*=") { if (!done) { print k " = " v; done = 1 }; next }
		{ print }
		END { emit(); if (!found) { print ""; print s; print k " = " v } }
	' "$file" > "$file.nbtmp" && cat "$file.nbtmp" > "$file"
	rm -f "$file.nbtmp"
}

nb_firewalld_running() {
	command -v firewall-cmd >/dev/null 2>&1 && [ "$(firewall-cmd --state 2>/dev/null)" = "running" ]
}

# 某个封禁动作在本机能否真正执行（防火墙不可用时 fail2ban 只记日志、不会真的拦截）
f2b_action_usable() {
	case "$1" in
		firewallcmd*) nb_firewalld_running ;;
		nftables*) command -v nft >/dev/null 2>&1 ;;
		iptables*) command -v iptables >/dev/null 2>&1 ;;
		*) return 0 ;;
	esac
}

# 按本机实际在用的防火墙选封禁动作：firewalld 运行中 > nftables > iptables
f2b_pick_banaction() {
	if nb_firewalld_running; then
		echo firewallcmd-rich-rules
	elif command -v nft >/dev/null 2>&1; then
		if [ -f /etc/fail2ban/action.d/nftables.conf ]; then echo nftables; else echo nftables-multiport; fi
	elif command -v iptables >/dev/null 2>&1; then
		echo iptables-multiport
	fi
}

# 把 sshd 实际使用的端口同步到 fail2ban 所有 SSH jail（默认 port = ssh 只对 22 端口生效），
# 并在当前封禁动作无法执行时（如 firewalld 没运行、只有 nftables 没有 iptables）换成本机可用的动作
# 用法：f2b_sync_ssh_port [quiet]   quiet：没有变化时不输出
f2b_sync_ssh_port() {
	command -v fail2ban-client >/dev/null 2>&1 || return 0
	[ -d /etc/fail2ban ] || return 0
	local quiet=$1 conf="/etc/fail2ban/jail.d/sshd.local" ports jails j a tmp dump enable= ban_new= ban_fix=
	# 迁移旧版本的错误配置：Alpine 的 jail 名是 sshd（alpine-sshd 只是过滤器名），旧版写成 [alpine-sshd] 导致端口不生效
	if grep -qs '^\[alpine-sshd\]' "$conf" && ! grep -qs '^\[alpine-sshd\]' /etc/fail2ban/jail.conf /etc/fail2ban/jail.local /etc/fail2ban/jail.d/*.conf; then
		if grep -qs '^\[sshd\]' "$conf"; then
			awk '/^\[/{skip=($0=="[alpine-sshd]")} !skip' "$conf" > "$conf.nbtmp" && cat "$conf.nbtmp" > "$conf"
			rm -f "$conf.nbtmp"
		else
			sed -i 's/^\[alpine-sshd\]/[sshd]/' "$conf"
		fi
	fi
	ports=$(nb_ssh_ports)
	dump=$(fail2ban-client -d 2>/dev/null)
	jails=$(echo "$dump" | sed -n "s/^\['add', '\([^']*\)'.*/\1/p" | grep -i ssh | sort -u)
	if [ -z "$jails" ]; then
		jails=sshd
		[ -f "$conf" ] || enable=1
	fi
	mkdir -p /etc/fail2ban/jail.d
	tmp=$(mktemp) || return 1
	if [ -f "$conf" ]; then
		cat "$conf" > "$tmp"
	else
		echo "# Managed by nimbus：SSH 端口、封禁动作由 nimbus 自动同步" > "$tmp"
	fi
	for j in $jails; do
		f2b_ini_set "$tmp" "$j" port "$ports"
		[ -n "$enable" ] && f2b_ini_set "$tmp" "$j" enabled true
		# 只在当前动作用不了时才改，能用的配置（如 Debian 13 默认的 nftables）保持不动
		for a in $(echo "$dump" | sed -n "s/^\['set', '$j', 'addaction', '\([^'\[]*\).*/\1/p"); do
			f2b_action_usable "$a" && continue
			[ -n "$ban_new" ] || ban_new=$(f2b_pick_banaction)
			if [ -n "$ban_new" ]; then
				f2b_ini_set "$tmp" "$j" banaction "$ban_new"
				ban_fix="$a -> $ban_new"
			else
				ban_fix="$a"
			fi
			break
		done
	done
	if [ -f "$conf" ] && cmp -s "$tmp" "$conf"; then
		rm -f "$tmp"
		[ "$quiet" = quiet ] || echo -e "fail2ban SSH 端口已是最新: ${gl_huang}${ports}${gl_bai}"
		[ -n "$ban_fix" ] && [ -z "$ban_new" ] && echo -e "${gl_hong}注意：${gl_bai}fail2ban 的封禁动作 $ban_fix 在本机无法执行，且没有找到 nft / iptables，实际不会拦截任何 IP"
		f2b_check_effective_port "$dump" "$ports" $jails
		return 0
	fi
	cat "$tmp" > "$conf"
	rm -f "$tmp"
	chmod 644 "$conf"
	fail2ban-client reload >/dev/null 2>&1 || true
	echo -e "fail2ban 已同步 SSH 端口: ${gl_huang}${ports}${gl_bai}（jail: $(echo $jails | tr ' ' ',')）"
	if [ -n "$ban_fix" ]; then
		if [ -n "$ban_new" ]; then
			echo -e "fail2ban 原封禁动作在本机无法执行，已改为: ${gl_huang}${ban_fix}${gl_bai}"
		else
			echo -e "${gl_hong}注意：${gl_bai}fail2ban 的封禁动作 $ban_fix 在本机无法执行，且没有找到 nft / iptables，实际不会拦截任何 IP"
		fi
	fi
	f2b_check_effective_port "$(fail2ban-client -d 2>/dev/null)" "$ports" $jails
}

# 核对 fail2ban 实际生效的端口：排在 sshd.local 之后的 jail.d/*.local 若也写了 port，会覆盖 nimbus 的设置
# 用法：f2b_check_effective_port "<fail2ban-client -d 输出>" <端口> <jail...>
f2b_check_effective_port() {
	local dump=$1 ports=$2 j eff bad= conf="/etc/fail2ban/jail.d/sshd.local"
	shift 2
	for j in "$@"; do
		eff=$(echo "$dump" | grep -F "['multi-set', '$j', 'action'," | grep -oE "\['port', '[^']*'\]" | head -n1 | cut -d"'" -f4)
		[ -n "$eff" ] && [ "$eff" != "$ports" ] && bad="$bad $j=$eff"
	done
	[ -n "$bad" ] || return 0
	echo -e "${gl_hong}注意：${gl_bai}fail2ban 实际生效的端口与 SSH 不一致:${bad}（SSH: $ports）"
	echo "以下文件也设置了 port 并覆盖了 $conf，请删除其中的 port 行或改成 $ports："
	grep -lE '^[[:space:]]*port[[:space:]]*=' /etc/fail2ban/jail.d/*.local 2>/dev/null | grep -vxF "$conf" | sed 's/^/  /'
	return 1
}

f2b_install_sshd() {

	docker rm -f fail2ban >/dev/null 2>&1
	local had_firewalld=
	command -v firewall-cmd >/dev/null 2>&1 && had_firewalld=1
	install fail2ban || return 1
	# RHEL 系的 fail2ban 依赖 fail2ban-firewalld，会连带装上 firewalld 并设为开机自启；
	# 它本来不是这台机器的防火墙，重启后却会按默认规则只放行 22，导致改过端口的 SSH 连不上
	if [ -z "$had_firewalld" ] && command -v firewall-cmd >/dev/null 2>&1 && ! nb_firewalld_running; then
		systemctl disable firewalld >/dev/null 2>&1 || true
		echo "安装 fail2ban 时连带装上了 firewalld（未运行），已取消其开机自启；封禁改用 nftables / iptables"
	fi

	if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
		install rsyslog || return 1
		/bin/systemctl enable --now rsyslog.service || return 1
		cd /etc/fail2ban/jail.d/
		nb_download raw.githubusercontent.com/zidou-kiyn/nimbus/main/res/config/fail2ban/centos-ssh.conf centos-ssh.conf || return 1
		if [ ! -e /var/log/secure ]; then
			touch /var/log/secure || return 1
			chmod 0600 /var/log/secure || return 1
			command -v restorecon >/dev/null 2>&1 && restorecon /var/log/secure || true
		fi
	fi

	if command -v apt &>/dev/null; then
		install rsyslog || return 1
		/bin/systemctl enable --now rsyslog.service || return 1
		# rsyslog 收到第一条认证日志前不会创建 auth.log，fail2ban（Debian 12 按文件读取）会因找不到日志而启动失败
		if [ ! -e /var/log/auth.log ]; then
			touch /var/log/auth.log && chmod 0640 /var/log/auth.log
			chown root:adm /var/log/auth.log 2>/dev/null || true
		fi
	fi

	if command -v apk >/dev/null 2>&1; then
		rc-update add fail2ban default || return 1
		rc-service fail2ban start || return 1
	else
		/bin/systemctl enable --now fail2ban.service || return 1
	fi
	fail2ban-client -t >/dev/null 2>&1 || return 1
	if ! fail2ban-client reload >/dev/null 2>&1; then
		if command -v apk >/dev/null 2>&1; then
			rc-service fail2ban restart || return 1
		else
			/bin/systemctl restart fail2ban.service || return 1
		fi
	fi
	f2b_sync_ssh_port

}



f2b_sshd() {
	local j
	for j in $(f2b_ssh_jails); do
		xxx=$j
		f2b_status_xxx
	done
	[ -n "$j" ] || { xxx=sshd; f2b_status_xxx; }
}

# 基础参数配置：封禁时长(bantime)、时间窗口(findtime)、重试次数(maxretry)
# 说明：
# - 优先写入 /etc/fail2ban/jail.d/sshd.local（覆盖默认 jail 配置，升级不易丢）
# - jail 名称按实际加载的配置取（Alpine 也是 sshd，过滤器才叫 alpine-sshd）
f2b_basic_config() {
	root_use
	install nano

	if ! command -v fail2ban-client >/dev/null 2>&1; then
		echo -e "${gl_hui}未检测到 fail2ban-client，请先安装 fail2ban。${gl_bai}"
		return
	fi

	local jail_name
	jail_name=$(f2b_ssh_jail)

	echo "即将配置 SSH jail：$jail_name"
	read -e -p "封禁时长 bantime (秒/分钟/小时，如 3600 或 1h) [默认 1h]: " bantime
	read -e -p "时间窗口 findtime (秒/分钟/小时，如 600 或 10m) [默认 10m]: " findtime
	read -e -p "重试次数 maxretry (整数) [默认 5]: " maxretry

	bantime=${bantime:-1h}
	findtime=${findtime:-10m}
	maxretry=${maxretry:-5}

	mkdir -p /etc/fail2ban/jail.d
	cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[$jail_name]
# Managed by nimbus
# Note: enable the jail so these parameters take effect
enabled = true
bantime = $bantime
findtime = $findtime
maxretry = $maxretry
EOF

	# Ensure a logfile exists for sshd jail on Debian/Ubuntu minimal images
	# (without it, fail2ban-server may refuse to start)
	if [ "$jail_name" = "sshd" ] && command -v apt >/dev/null 2>&1; then
		if [ -f /etc/fail2ban/jail.d/sshd.local ]; then
			grep -qE '^\s*logpath\s*=' /etc/fail2ban/jail.d/sshd.local || echo 'logpath = /var/log/auth.log' >> /etc/fail2ban/jail.d/sshd.local
		fi
	fi

	echo -e "${gl_lv}已写入配置${gl_bai}: /etc/fail2ban/jail.d/sshd.local"
	f2b_sync_ssh_port
	fail2ban-client reload >/dev/null 2>&1 || true
	sleep 2
	fail2ban-client status $jail_name || true
}

# 直接打开主配置/覆盖配置编辑（nano）
# 优先编辑 /etc/fail2ban/jail.d/sshd.local（更安全），若不存在则创建
f2b_edit_config() {
	root_use
	install nano

	if [ ! -d /etc/fail2ban ]; then
		echo -e "${gl_hui}/etc/fail2ban 不存在，请先安装 fail2ban。${gl_bai}"
		return
	fi

	mkdir -p /etc/fail2ban/jail.d
	local cfg="/etc/fail2ban/jail.d/sshd.local"
	[ -f "$cfg" ] || printf "[%s]\n# bantime/findtime/maxretry\n" "$(f2b_ssh_jail)" > "$cfg"

	nano "$cfg"
	echo -e "${gl_lv}已保存${gl_bai}，正在 reload fail2ban..."
	# port 以 sshd 实际端口为准，手动改错也会被纠正
	f2b_sync_ssh_port quiet
	fail2ban-client reload >/dev/null 2>&1 || true
}



server_reboot() {

	read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
	case "$rboot" in
	  [Yy])
		echo "已重启"
		reboot
		;;
	  *)
		echo "已取消"
		;;
	esac


}



output_status() {
	output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
		$1 ~ /^(eth|ens|enp|eno)[0-9]+/ {
			rx_total += $2
			tx_total += $10
		}
		END {
			rx_units = "Bytes";
			tx_units = "Bytes";
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "K"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "M"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "G"; }

			if (tx_total > 1024) { tx_total /= 1024; tx_units = "K"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "M"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "G"; }

			printf("%.2f%s %.2f%s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)

	rx=$(echo "$output" | awk '{print $1}')
	tx=$(echo "$output" | awk '{print $2}')

}



current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
	   date +"%Z %z"
	else
	   timedatectl | grep "Time zone" | awk '{print $3}'
	fi

}


set_timedate() {
	local shiqu="$1"
	if grep -q 'Alpine' /etc/issue; then
		install tzdata
		cp /usr/share/zoneinfo/${shiqu} /etc/localtime
		hwclock --systohc
	else
		timedatectl set-timezone ${shiqu}
	fi
}



# apt 源里的主机（scheme://host，去重）
nb_apt_hosts() {
	cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null |
		grep -vE '^[[:space:]]*#' | grep -oE 'https?://[^/[:space:]]+' | awk '!seen[$0]++'
}

# TCP 能否连通（参数：主机 端口），不依赖 curl，最多等 5 秒
nb_tcp_ok() {
	timeout 5 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null
}

# 把标准布局的 Debian / Ubuntu 源（路径为 /debian /debian-security /ubuntu /ubuntu-ports）换成指定镜像（参数：scheme://host）
# 第三方源（docker、nodesource 等）路径不同，不会被改；原文件备份到 /etc/apt/nimbus-backup/时间戳/
nb_apt_set_mirror() {
	local base="$1" f dir changed=0
	local re='https?://[^/[:space:]]+/(debian|debian-security|ubuntu|ubuntu-ports)(/?)([[:space:]]|$)'
	dir="/etc/apt/nimbus-backup/$(date +%Y%m%d-%H%M%S)"
	for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
		[ -f "$f" ] && grep -qE "$re" "$f" || continue
		mkdir -p "$dir" && cp -a "$f" "$dir/"
		sed -i -E "s#${re}#${base}/\\1\\2\\3#g" "$f"
		changed=$((changed + 1))
	done
	if [ "$changed" -gt 0 ]; then
		echo -e "${gl_lv}已切换到 ${base#*://}${gl_bai}（原文件备份在 $dir）"
	else
		echo -e "${gl_huang}没有找到可替换的 Debian / Ubuntu 官方格式源，未修改${gl_bai}"
	fi
}

# 更新前检查 apt 源能否连通：连不上的源会让 apt update 卡很久（如 DD 后的国内机器仍用 security.debian.org）
# 阿里云 / 腾讯云推荐内网镜像，其他国内机器推荐公共镜像。返回 1 表示用户取消更新
nb_apt_source_check() {
	local hosts h hp port bad="" mirror="" label="" choice
	hosts=$(nb_apt_hosts)
	[ -n "$hosts" ] || return 0
	echo "正在检查更新源连通性..."
	for h in $hosts; do
		hp=${h#*://}
		port=80
		[ "${h%%://*}" = https ] && port=443
		nb_tcp_ok "$hp" "$port" || bad="$bad $hp"
	done
	[ -n "$bad" ] || return 0

	echo -e "${gl_huang}以下更新源无法连接，直接更新会长时间卡住:${gl_bai}"
	for h in $bad; do echo "  $h"; done
	case "$(nb_cloud_vendor)" in
		aliyun) mirror="http://mirrors.cloud.aliyuncs.com"; label="阿里云内网镜像" ;;
		tencent) mirror="http://mirrors.tencentyun.com"; label="腾讯云内网镜像" ;;
	esac
	[ -n "$mirror" ] && ! nb_tcp_ok "${mirror#*://}" 80 && mirror=""
	if [ -z "$mirror" ] && nb_in_cn && nb_tcp_ok mirrors.aliyun.com 80; then
		mirror="http://mirrors.aliyun.com"; label="阿里云公共镜像"
	fi

	if [ -z "$mirror" ]; then
		echo "可先到 系统工具 → 20 切换更新源，再执行更新"
		read -r -e -p "仍然继续更新吗？(y/N): " choice
		[[ "$choice" =~ ^[Yy]$ ]]
		return
	fi
	echo "------------------------"
	echo "1. 切换到${label} ${mirror#*://}（推荐）"
	echo "2. 不切换，继续更新"
	echo "0. 取消更新"
	echo "------------------------"
	read -r -e -p "请输入你的选择 [默认 1]: " choice
	case "${choice:-1}" in
		1) nb_apt_set_mirror "$mirror" ;;
		2) ;;
		*) return 1 ;;
	esac
	return 0
}

# 修复dpkg中断问题
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_cyan}正在系统更新...${gl_bai}"
	if command -v dnf &>/dev/null; then
		dnf -y update
	elif command -v yum &>/dev/null; then
		yum -y update
	elif command -v apt &>/dev/null; then
		fix_dpkg
		nb_apt_source_check || { echo "已取消更新"; return 1; }
		# 连不上的源最多等 20 秒（默认 120 秒，且会逐个尝试 IPv4 / IPv6 地址）
		DEBIAN_FRONTEND=noninteractive apt -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20 update -y
		DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
	elif command -v apk &>/dev/null; then
		apk update && apk upgrade
	elif command -v pacman &>/dev/null; then
		pacman -Syu --noconfirm
	elif command -v zypper &>/dev/null; then
		zypper refresh
		zypper update
	elif command -v opkg &>/dev/null; then
		opkg update
	else
		echo "未知的包管理器!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_cyan}正在系统清理...${gl_bai}"
	if command -v dnf &>/dev/null; then
		rpm --rebuilddb
		dnf autoremove -y
		dnf clean all
		dnf makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v yum &>/dev/null; then
		rpm --rebuilddb
		yum autoremove -y
		yum clean all
		yum makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apt &>/dev/null; then
		fix_dpkg
		apt autoremove --purge -y
		apt clean -y
		apt autoclean -y
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apk &>/dev/null; then
		echo "清理包管理器缓存..."
		apk cache clean
		echo "删除系统日志..."
		rm -rf /var/log/*
		echo "删除APK缓存..."
		rm -rf /var/cache/apk/*
		echo "删除临时文件..."
		rm -rf /tmp/*

	elif command -v pacman &>/dev/null; then
		pacman -Rns $(pacman -Qdtq) --noconfirm
		pacman -Scc --noconfirm
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v zypper &>/dev/null; then
		zypper clean --all
		zypper refresh
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v opkg &>/dev/null; then
		echo "删除系统日志..."
		rm -rf /var/log/*
		echo "删除临时文件..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "清理未使用的依赖..."
		pkg autoremove -y
		echo "清理包管理器缓存..."
		pkg clean -y
		echo "删除系统日志..."
		rm -rf /var/log/*
		echo "删除临时文件..."
		rm -rf /tmp/*

	else
		echo "未知的包管理器!"
		return
	fi
	return
}



# XanMod 官方 APT 公钥（https://dl.xanmod.org/archive.key，指纹 D38D 7D1D A134 9567 ADED 882D 86F7 D09E E734 E623）
# 官方地址和 GitHub 都连不上时（如无国际出口的国内机器）使用
nb_xanmod_key() {
	cat <<'NB_XANMOD_KEY'
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

mQENBFhxW04BCAC61HuxBVf1XJiQjXu/DSAtVcnuK38geDoDjcqFtHskFy32NgJG
X118EFNym6noF+oibaSftI9yjHthWvMnYZ/+DPwd7YZhbAjBvxMIQCsP6cFVxrgc
VV8g+uh4TCfbpalDBFoncRhQCgkmDN9Vd4kIWRh6BHJuzpKB/h2KxUHZVEKgWlK2
dR1xUtbrc+kp8gLwPbxTgC3tZ4x2uMMMlnbyCMSRa5oJ/AvoW4W1XphKL9ivsFHM
PSQkUBDvgv2RPw+0XBxPy8SYE0r0onx0ZIpjJRTODt3bSV6/0owwlpNogV9bT8HY
kl3+w3mTwax6S1akHZuJtLkZS0uUBz1BHt5bABEBAAG0IVhhbk1vZCBLZXJuZWwg
PGtlcm5lbEB4YW5tb2Qub3JnPokBNwQTAQgAIQUCWHFbTgIbAwULCQgHAgYVCAkK
CwIEFgIDAQIeAQIXgAAKCRCG99Ce5zTmIwTmB/9/S4rmwU6efDgEaBDwBDbOfLBA
P2+kDpabjG4K+V4NSvDqlPN49KrI7C21jHghAa2VuTPbSZVQ9ziUd5DjX9OuXov8
CYVG+rrlG1UadHS8SBpgw0gNylEvo9/U6u0hl8mrbVOlpzu+eE+e4cMTHax2y580
fC2xmnM8wKgyRFEyVc6ilWU+UNTAeUFlg0YfU3cV1Ut4DzVFfamtNYg0p7Q/9MSy
VgFpt5C2U5prk4wi++51OgrtaNhMrUhzYXLINWVF6IrXhQ+mkI/FWXUZ0oyVo55v
+dQzuds/gos90q+tKyE514pYAmwQSftSjf+RmHOMpPQyMZZKSywrz4vlfveDuQEN
BFhxW04BCACs5bXq73MDb2+AsvNL2XkkbnzmE4K3k0gejB9OxrO+puAZn3wWyYIk
b0Op8qVUh+/FIiW/uFfmdFD8BypC3YkCNfg6e74f5TT3qQciccpMGy62teo3jfhT
T8E1OL1i76ALq7eNbByJKiKLBrTUDM6BDIeRZBWXQMase4+aqUAP47Kd/ByPsmCh
/pzb6yPdDPKwkspELssdPXYI7enddjQsCPoBko0j8CTPgKqMTeCuKMXCtD2gtRBN
eoVj4cbjZoZvBh8oJktzbYA8FX8eKdxIXhSP9MoVOPSWhxIQdwzkzUPK+0vUV8jA
NBTnGOkrRJPOHGPJWFWnTUGrzvcwi7czABEBAAGJAR8EGAEIAAkFAlhxW04CGwwA
CgkQhvfQnuc05iMIswgAmzSpCHFGKdkFLdC673FidJcL8adKFTO5Mpyholc5N8vG
ROJbpso+DpssF14NKoBfBWqPRgHxYzHakxHiNf0R2+EEwXH3rblzpx3PXzB0OgNe
T9T0UStrGgc9nZ8nZVURHZZ2z5zakEWS+rB2TiSxz3YArR3wiTHQW49G09uZvfp6
5Mim2w+eUxbQ689eT0DlDI1d2eDP/j5lrv1elsg3kBE2Awzdvi8DdGUpMFrSsYJw
WS85uZrwbeAs/nPO62wNIvAbbRsWnDg3AV3vc02eRvy52tTBY1W/67N02M4AxgPd
ukDDFZMifwa03yTHD/a57O4dFOnzsEVojBnbzQ7W7w==
=HKlF
-----END PGP PUBLIC KEY BLOCK-----
NB_XANMOD_KEY
}

bbr_on() {

# BBR + fq 统一写入 sysctl.d
local CONF="/etc/sysctl.d/99-nimbus-bbr.conf"
mkdir -p /etc/sysctl.d
echo "net.core.default_qdisc=fq" > "$CONF"
echo "net.ipv4.tcp_congestion_control=bbr" >> "$CONF"

# 清理可能导致冲突的旧版 sysctl.conf 残留
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf 2>/dev/null

sysctl -p "$CONF" >/dev/null 2>&1 || sysctl --system >/dev/null 2>&1

}


# 云厂商（按 DMI 信息判断）：输出 aliyun / tencent，其他输出为空
nb_cloud_vendor() {
	case "$(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>/dev/null)" in
		*Alibaba*|*Aliyun*) echo aliyun ;;
		*Tencent*) echo tencent ;;
	esac
}

# DHCP 下发的 DNS（依次查 dhcpcd、dhclient、systemd-networkd、NetworkManager），取不到时用云厂商内网 DNS；输出空格分隔的地址
nb_default_dns() {
	local ifc ns="" lease
	ifc=$(ip route show default 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit }}')
	if [ -n "$ifc" ]; then
		command -v dhcpcd >/dev/null 2>&1 &&
			ns=$(dhcpcd -U "$ifc" 2>/dev/null | sed -n 's/^domain_name_servers=//p' | tr -d "'\"")
		if [ -z "$ns" ]; then
			lease=$(ls -t /var/lib/dhcp/dhclient*"$ifc"*.lease* /var/lib/dhcp/dhclient.lease* /var/lib/dhclient/*.lease* 2>/dev/null | head -1)
			[ -n "$lease" ] && ns=$(grep -h 'option domain-name-servers' "$lease" 2>/dev/null | tail -1 | sed 's/.*domain-name-servers //; s/;//; s/,/ /g')
		fi
		[ -z "$ns" ] && ns=$(cat /run/systemd/netif/leases/* 2>/dev/null | sed -n 's/^DNS=//p' | head -1)
		[ -z "$ns" ] && command -v nmcli >/dev/null 2>&1 &&
			ns=$(nmcli -g IP4.DNS device show "$ifc" 2>/dev/null | tr '|' ' ')
	fi
	ns=$(printf '%s\n' $ns | grep -E '^[0-9A-Fa-f.:]+$' | awk '!seen[$0]++' | paste -sd' ' -)
	if [ -z "$ns" ]; then
		case "$(nb_cloud_vendor)" in
			aliyun) ns="100.100.2.136 100.100.2.138" ;;
			tencent) ns="183.60.83.19 183.60.82.98" ;;
		esac
	fi
	[ -n "$ns" ] && echo "$ns"
}

# 写入 /etc/resolv.conf：参数 1 为写入后是否锁定（true/false），其余为 nameserver 地址
# 写入前备份；原来是链接（如指向 systemd-resolved）时替换为普通文件，避免写进 /run 下的临时文件
# 写入后验证解析，不通则还原原配置（例如国内无国际出口的机器选了国外 DNS）
nb_write_resolv() {
	local lock="$1" conf=/etc/resolv.conf bak link="" was_immutable=false d
	shift
	lsattr "$conf" 2>/dev/null | awk '{print $1}' | grep -q i && was_immutable=true
	bak=$(mktemp "$conf.bak.$(date +%Y%m%d-%H%M%S).XXXX")
	chattr -i "$conf" 2>/dev/null
	cat "$conf" > "$bak" 2>/dev/null
	if [ -L "$conf" ]; then
		link=$(readlink "$conf")
		rm -f "$conf"
	fi
	for d in "$@"; do echo "nameserver $d"; done > "$conf"

	echo "正在验证 DNS 解析..."
	if command -v getent >/dev/null 2>&1 &&
		! RES_OPTIONS="timeout:2 attempts:1" timeout 15 getent ahosts www.qq.com >/dev/null 2>&1 &&
		! RES_OPTIONS="timeout:2 attempts:1" timeout 15 getent ahosts www.baidu.com >/dev/null 2>&1; then
		if [ -n "$link" ]; then
			rm -f "$conf"; ln -s "$link" "$conf"
		else
			cat "$bak" > "$conf"
		fi
		[ "$was_immutable" = true ] && chattr +i "$conf" 2>/dev/null
		echo -e "${gl_hong}新的 DNS 无法解析域名，已还原原配置${gl_bai}（本机可能无法访问这些 DNS 服务器，国内机器请选国内 DNS）"
		return 1
	fi
	[ "$lock" = true ] && chattr +i "$conf" 2>/dev/null
	echo -e "${gl_lv}DNS 已更新${gl_bai}（原配置备份在 $bak）"
}

# 写入 DNS（地址取自调用方的 dns1_ipv4 等变量）。按默认路由判断 IPv4/IPv6，不查公网 IP（无国际出口时会卡住）
set_dns() {
	local -a ns=()
	[ -n "$(ip -4 route show default 2>/dev/null)" ] && ns+=("$dns1_ipv4" "$dns2_ipv4")
	[ -n "$(ip -6 route show default 2>/dev/null)" ] && ns+=("$dns1_ipv6" "$dns2_ipv6")
	[ "${#ns[@]}" -gt 0 ] || ns=("$dns1_ipv4" "$dns2_ipv4")
	nb_write_resolv true "${ns[@]}"
}

# 恢复默认 DNS：systemd-resolved 管理的恢复为 stub 链接；否则写回 DHCP 下发的 DNS（阿里云 / 腾讯云即内网 DNS），不锁定，交还 DHCP 维护
nb_dns_restore_default() {
	local conf=/etc/resolv.conf ns bak
	if command systemctl is-active --quiet systemd-resolved 2>/dev/null && [ -e /run/systemd/resolve/stub-resolv.conf ]; then
		chattr -i "$conf" 2>/dev/null
		if [ "$(readlink "$conf")" != "../run/systemd/resolve/stub-resolv.conf" ]; then
			bak=$(mktemp "$conf.bak.$(date +%Y%m%d-%H%M%S).XXXX")
			cat "$conf" > "$bak" 2>/dev/null
			rm -f "$conf"
			ln -s ../run/systemd/resolve/stub-resolv.conf "$conf"
			systemctl restart systemd-resolved 2>/dev/null
			echo -e "${gl_lv}已恢复由 systemd-resolved 管理 DNS${gl_bai}（原配置备份在 $bak）"
		else
			echo -e "${gl_lv}DNS 已由 systemd-resolved 管理，无需恢复${gl_bai}"
		fi
		return 0
	fi
	ns=$(nb_default_dns)
	if [ -z "$ns" ]; then
		echo -e "${gl_hong}未能获取 DHCP 下发的 DNS，也未识别到云厂商，请用手动编辑${gl_bai}"
		return 1
	fi
	echo "默认 DNS: $ns"
	# shellcheck disable=SC2086
	nb_write_resolv false $ns
}

set_dns_ui() {
root_use
local vendor
vendor=$(nb_cloud_vendor)
while true; do
	clear
	echo "优化DNS地址"
	echo "------------------------"
	echo "当前DNS地址"
	grep -vE '^[[:space:]]*(#|$)' /etc/resolv.conf
	echo "------------------------"
	case "$vendor" in
		aliyun) echo -e "${gl_huang}检测到阿里云，推荐选 4 恢复内网 DNS（延迟最低，不受公网波动影响）${gl_bai}" ;;
		tencent) echo -e "${gl_huang}检测到腾讯云，推荐选 4 恢复内网 DNS（延迟最低，不受公网波动影响）${gl_bai}" ;;
	esac
	echo ""
	echo "1. 国外DNS优化: "
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 国内DNS优化: "
	echo " v4: 223.5.5.5 119.29.29.29"
	echo " v6: 2400:3200::1 2402:4e00::"
	echo "3. 手动编辑DNS配置"
	echo "4. 恢复默认DNS（DHCP 下发，阿里云 / 腾讯云为内网 DNS）"
	echo "------------------------"
	echo "0. 返回上一级选单"
	echo "------------------------"
	read -e -p "请输入你的选择: " Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		break_end
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="119.29.29.29"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2402:4e00::"
		set_dns
		break_end
		;;
	  3)
		install nano
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
		;;
	  4)
		nb_dns_restore_default
		break_end
		;;
	  *)
		break
		;;
	esac
done

}



# 重启 SSH 服务，返回值代表是否成功
# - Ubuntu 22.10+ 默认由 ssh.socket 监听端口：需 daemon-reload 让生成器按 sshd_config 重新生成监听地址，
#   再重启 ssh.socket 与 ssh.service（已有会话不会断开，ssh.service 为 KillMode=process）
# - Debian/Ubuntu 的服务名是 ssh，RHEL/Fedora 是 sshd，Alpine 用 OpenRC
# 注释掉 /etc/ssh/sshd_config.d/*.conf 中与登录方式有关的设置：云镜像常自带 PasswordAuthentication 等，
# 且 Include 在主配置开头，会抢先生效。端口等其他配置保留（以前直接删除整个目录，会丢掉 DD 时设置的 SSH 端口）
nb_sshd_dropin_neutralize() {
	local f
	for f in /etc/ssh/sshd_config.d/*.conf; do
		[ -f "$f" ] || continue
		sed -i -E 's/^([[:space:]]*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|ChallengeResponseAuthentication|KbdInteractiveAuthentication)[[:space:]].*)$/# [nimbus 已停用] \1/I' "$f"
	done
}

restart_ssh() {
	if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
		if systemctl is-active --quiet ssh.socket 2>/dev/null || systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
			systemctl daemon-reload || return 1
			systemctl restart ssh.socket || return 1
			systemctl restart ssh.service >/dev/null 2>&1 || true
			return 0
		fi
		local unit
		for unit in ssh sshd; do
			if systemctl cat "$unit.service" >/dev/null 2>&1; then
				systemctl restart "$unit.service"
				return $?
			fi
		done
		return 1
	elif command -v rc-service >/dev/null 2>&1; then
		rc-service sshd restart >/dev/null 2>&1
	elif command -v service >/dev/null 2>&1; then
		service ssh restart >/dev/null 2>&1 || service sshd restart >/dev/null 2>&1
	else
		return 1
	fi
}



correct_ssh_config() {

	local sshd_config="/etc/ssh/sshd_config"


	if grep -Eq "^\s*PasswordAuthentication\s+no" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	else
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin yes/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication yes/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' "$sshd_config"
	fi

	nb_sshd_dropin_neutralize
}


# 在 firewalld 中放行端口（运行中：立即生效并写入永久配置；未运行：只写永久配置，防止开机自启后拦截新端口）
nb_firewalld_allow_port() {
	local port=$1
	command -v firewall-cmd >/dev/null 2>&1 || return 0
	if nb_firewalld_running; then
		firewall-cmd --permanent --add-port="$port/tcp" >/dev/null || return 1
		firewall-cmd --reload >/dev/null || return 1
		echo "firewalld 已放行 TCP $port"
	elif command -v firewall-offline-cmd >/dev/null 2>&1; then
		firewall-offline-cmd --add-port="$port/tcp" >/dev/null 2>&1 && echo "firewalld 未运行，已在其永久配置中放行 TCP $port"
	fi
	return 0
}

# 本机自己维护的 nftables 表（排除 iptables-nft、fail2ban、Docker、firewalld 自动生成的表）
nb_nft_custom_tables() {
	command -v nft >/dev/null 2>&1 || return 0
	nft list tables 2>/dev/null | awk '$1=="table"{print $2" "$3}' \
		| grep -vE '^(ip|ip6|inet|arp|bridge) (filter|nat|mangle|raw|security)$|f2b-table|^inet firewalld$|docker'
}

new_ssh_port() {

  local new_port=$1 sshd_bin out rc

  # 先放行新端口，再改配置、重启 sshd：防火墙放行失败时 sshd_config 保持原样
  open_port "$new_port" || return 1
  # 不再卸载 firewalld：RHEL 系上 dnf remove firewalld 会连带卸掉 fail2ban；改为在 firewalld 里放行新端口
  nb_firewalld_allow_port "$new_port" || return 1
  remove iptables-persistent ufw iptables-services > /dev/null 2>&1

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i '/^\s*#\?\s*Port\s\+/d' /etc/ssh/sshd_config
  sed -i "1i Port $new_port" /etc/ssh/sshd_config

  correct_ssh_config

  # 配置有误时还原，避免重启后 sshd 起不来
  sshd_bin=$(command -v sshd 2>/dev/null || echo /usr/sbin/sshd)
  if [ -x "$sshd_bin" ] && ! out=$("$sshd_bin" -t 2>&1) && ! echo "$out" | grep -qi 'privilege separation'; then
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    echo "sshd 配置检查失败，已还原 /etc/ssh/sshd_config："
    echo "$out"
    return 1
  fi

  restart_ssh
  rc=$?
  # 无论重启是否成功，sshd_config 已改，先同步 fail2ban
  f2b_sync_ssh_port
  if [ $rc -ne 0 ]; then
    echo -e "${gl_hong}重启 SSH 服务失败${gl_bai}，请保持当前会话，检查 systemctl status ssh / sshd"
    return 1
  fi

  sleep 1
  if command -v ss >/dev/null 2>&1 && ! ss -Htln 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${new_port}\$"; then
    echo -e "${gl_hong}未检测到端口 $new_port 在监听${gl_bai}，请保持当前会话，检查 systemctl status ssh / sshd"
    return 1
  fi

  echo "SSH 端口已修改为: $new_port"
  local nft_tables
  nft_tables=$(nb_nft_custom_tables | paste -sd, -)
  if [ -n "$nft_tables" ]; then
    echo -e "${gl_huang}注意：${gl_bai}检测到自定义 nftables 规则（${nft_tables}）。"
    echo "nimbus 只在 iptables / firewalld 中放行了 TCP $new_port，不会改你的 nftables 配置；"
    echo "请确认这些规则也放行了新端口，否则用新端口可能连不上。"
  fi

  sleep 1

}



sshkey_on() {

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	nb_sshd_dropin_neutralize
	restart_ssh
	echo -e "${gl_lv}用户密钥登录模式已开启，已关闭密码登录模式，重连将会生效${gl_bai}"

}



add_sshkey() {
	chmod 700 "${HOME}"
	mkdir -p "${HOME}/.ssh"
	chmod 700 "${HOME}/.ssh"
	touch "${HOME}/.ssh/authorized_keys"

	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f "${HOME}/.ssh/sshkey" -N ""

	cat "${HOME}/.ssh/sshkey.pub" >> "${HOME}/.ssh/authorized_keys"
	chmod 600 "${HOME}/.ssh/authorized_keys"

	ip_address
	echo -e "私钥信息已生成，务必复制保存，可保存成 ${gl_huang}${ipv4_address}_ssh.key${gl_bai} 文件，用于以后的SSH登录"

	echo "--------------------------------"
	cat "${HOME}/.ssh/sshkey"
	echo "--------------------------------"

	sshkey_on
}



import_sshkey() {

	local public_key="$1"
	local base_dir="${2:-$HOME}"
	local ssh_dir="${base_dir}/.ssh"
	local auth_keys="${ssh_dir}/authorized_keys"

	if [[ -z "$public_key" ]]; then
		read -e -p "请输入您的SSH公钥内容（通常以 'ssh-rsa' 或 'ssh-ed25519' 开头）: " public_key
	fi

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}错误：未输入公钥内容。${gl_bai}"
		return 1
	fi

	if [[ ! "$public_key" =~ ^ssh-(rsa|ed25519|ecdsa) ]]; then
		echo -e "${gl_hong}错误：看起来不像合法的 SSH 公钥。${gl_bai}"
		return 1
	fi

	if grep -Fxq "$public_key" "$auth_keys" 2>/dev/null; then
		echo "该公钥已存在，无需重复添加"
		return 0
	fi

	mkdir -p "$ssh_dir"
	chmod 700 "$ssh_dir"
	touch "$auth_keys"
	echo "$public_key" >> "$auth_keys"
	chmod 600 "$auth_keys"

	sshkey_on
}



fetch_remote_ssh_keys() {

	local keys_url="$1"
	local base_dir="${2:-$HOME}"
	local ssh_dir="${base_dir}/.ssh"
	local authorized_keys="${ssh_dir}/authorized_keys"
	local temp_file

	if [[ -z "${keys_url}" ]]; then
		read -e -p "请输入您的远端公钥URL： " keys_url
	fi

	echo "此脚本将从远程 URL 拉取 SSH 公钥，并添加到 ${authorized_keys}"
	echo ""
	echo "远程公钥地址："
	echo "  ${keys_url}"
	echo ""

	# 创建临时文件
	temp_file=$(mktemp)

	# 下载公钥
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 10 "${keys_url}" -o "${temp_file}" || {
			echo "错误：无法从 URL 下载公钥（网络问题或地址无效）" >&2
			rm -f "${temp_file}"
			return 1
		}
	elif command -v wget >/dev/null 2>&1; then
		wget -q --timeout=10 -O "${temp_file}" "${keys_url}" || {
			echo "错误：无法从 URL 下载公钥（网络问题或地址无效）" >&2
			rm -f "${temp_file}"
			return 1
		}
	else
		echo "错误：系统中未找到 curl 或 wget，无法下载公钥" >&2
		rm -f "${temp_file}"
		return 1
	fi

	# 检查内容是否有效
	if [[ ! -s "${temp_file}" ]]; then
		echo "错误：下载到的文件为空，URL 可能不包含任何公钥" >&2
		rm -f "${temp_file}"
		return 1
	fi

	mkdir -p "${ssh_dir}"
	chmod 700 "${ssh_dir}"
	touch "${authorized_keys}"
	chmod 600 "${authorized_keys}"

	# 备份原有 authorized_keys
	if [[ -f "${authorized_keys}" ]]; then
		cp "${authorized_keys}" "${authorized_keys}.bak.$(date +%Y%m%d-%H%M%S)"
		echo "已备份原有 authorized_keys 文件"
	fi

	# 追加公钥（避免重复）
	local added=0
	while IFS= read -r line; do
		[[ -z "${line}" || "${line}" =~ ^# ]] && continue

		if ! grep -Fxq "${line}" "${authorized_keys}" 2>/dev/null; then
			echo "${line}" >> "${authorized_keys}"
			((added++))
		fi
	done < "${temp_file}"

	rm -f "${temp_file}"

	echo ""
	if (( added > 0 )); then
		echo "成功添加 ${added} 条新的公钥到 ${authorized_keys}"
		sshkey_on
	else
		echo "没有新的公钥需要添加（可能已全部存在）"
	fi

	echo ""
}



fetch_github_ssh_keys() {

	local username="$1"
	local base_dir="${2:-$HOME}"

	echo "操作前，请确保您已在 GitHub 账户中添加了 SSH 公钥："
	echo "  1. 登录 ${gh_https_url}github.com/settings/keys"
	echo "  2. 点击 New SSH key 或 Add SSH key"
	echo "  3. Title 可随意填写（例如：Home Laptop 2026）"
	echo "  4. 将本地公钥内容（通常是 ~/.ssh/id_ed25519.pub 或 id_rsa.pub 的全部内容）粘贴到 Key 字段"
	echo "  5. 点击 Add SSH key 完成添加"
	echo ""
	echo "添加完成后，GitHub 会公开提供您的所有公钥，地址为："
	echo "  ${gh_https_url}github.com/您的用户名.keys"
	echo ""


	if [[ -z "${username}" ]]; then
		read -e -p "请输入您的 GitHub 用户名（username，不含 @）： " username
	fi

	if [[ -z "${username}" ]]; then
		echo "错误：GitHub 用户名不能为空" >&2
		return 1
	fi

	keys_url="${gh_https_url}github.com/${username}.keys"

	fetch_remote_ssh_keys "${keys_url}" "${base_dir}"

}


sshkey_panel() {
  root_use
  while true; do
	  clear
	  local REAL_STATUS=$(grep -i "^PubkeyAuthentication" /etc/ssh/sshd_config | tr '[:upper:]' '[:lower:]')
	  if [[ "$REAL_STATUS" =~ "yes" ]]; then
		  IS_KEY_ENABLED="${gl_lv}已启用${gl_bai}"
	  else
	  	  IS_KEY_ENABLED="${gl_hui}未启用${gl_bai}"
	  fi
  	  echo -e "用户密钥登录模式 ${IS_KEY_ENABLED}"
  	  echo "------------------------------------------------"
  	  echo "将会生成密钥对，更安全的方式SSH登录"
	  echo "------------------------"
	  echo "1. 生成新密钥对                  2. 手动输入已有公钥"
	  echo "3. 从GitHub导入已有公钥          4. 从URL导入已有公钥"
	  echo "5. 编辑公钥文件                  6. 查看本机密钥"
	  echo "------------------------"
	  echo "0. 返回上一级选单"
	  echo "------------------------"
	  read -e -p "请输入你的选择: " host_dns
	  case $host_dns in
		  1)
	  		add_sshkey
			break_end
			  ;;
		  2)
			import_sshkey
			break_end
			  ;;
		  3)
			fetch_github_ssh_keys
			break_end
			  ;;
		  4)
			read -e -p "请输入您的远端公钥URL： " keys_url
			fetch_remote_ssh_keys "${keys_url}"
			break_end
			  ;;

		  5)
			install nano
			nano ${HOME}/.ssh/authorized_keys
			break_end
			  ;;

		  6)
			echo "------------------------"
			echo "公钥信息"
			cat ${HOME}/.ssh/authorized_keys
			echo "------------------------"
			echo "私钥信息"
			cat ${HOME}/.ssh/sshkey
			echo "------------------------"
			break_end
			  ;;
		  *)
			  break  # 跳出循环，退出菜单
			  ;;
	  esac
  done


}



add_sshpasswd() {

	root_use
	echo "设置密码登录模式"

	local target_user="$1"

	# 如果没有通过参数传入，则交互输入
	if [[ -z "$target_user" ]]; then
		read -e -p "请输入要修改密码的用户名（默认 root）: " target_user
	fi

	# 回车不输入，默认 root
	target_user=${target_user:-root}

	# 校验用户是否存在
	if ! id "$target_user" >/dev/null 2>&1; then
		echo "错误：用户 $target_user 不存在"
		return 1
	fi

	passwd "$target_user"

	if [[ "$target_user" == "root" ]]; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	fi

	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	nb_sshd_dropin_neutralize

	restart_ssh

	echo -e "${gl_lv}密码设置完毕，已更改为密码登录模式！${gl_bai}"
}



root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！" && break_end && nimbus_home
}



# 下载重装脚本：优先 InstallNET（GitHub，国内走代理）；GitHub 及代理都不通时（如国内无国际出口的机器）
# 改用 bin456789/reinstall 的国内镜像 cnb.cool，它在国内会自动使用国内源。成功时设置 NB_DD_ENGINE / NB_DD_INSTALLER
nb_dd_fetch_installer() {
	local f
	NB_DD_ENGINE="" NB_DD_INSTALLER=""
	f=/root/InstallNET.sh
	if nb_download raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh "$f" && head -1 "$f" | grep -q '^#!/'; then
		NB_DD_ENGINE="installnet" NB_DD_INSTALLER="$f"
		return 0
	fi
	rm -f "$f"
	f=/root/reinstall.sh
	if { curl -fsSL --connect-timeout 8 -m 120 -o "$f" "https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh" 2>/dev/null ||
		nb_download raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh "$f"; } && head -1 "$f" | grep -q '^#!/'; then
		NB_DD_ENGINE="reinstall" NB_DD_INSTALLER="$f"
		return 0
	fi
	rm -f "$f"
	return 1
}

dd_xitong() {
	root_use
	local choice sys rsys ver rver label raid_ok pwd pwd2 port raid disks disk_list confirm engine installer name
	local -a args

	install curl wget
	echo "正在下载重装脚本..."
	if ! nb_dd_fetch_installer; then
		echo -e "${gl_hong}重装脚本下载失败（GitHub、代理和国内镜像 cnb.cool 都无法访问），请检查网络后重试${gl_bai}"
		break_end
		return 1
	fi
	engine="$NB_DD_ENGINE" installer="$NB_DD_INSTALLER"
	[ "$engine" = installnet ] && name="InstallNET" || name="reinstall"

	while true; do
		clear
		echo "一键重装系统"
		echo "------------------------------------------------"
		if [ "$engine" = installnet ]; then
			echo "使用 InstallNET 通过官方网络安装器重装原版系统，可自定义 root 密码、SSH 端口和软 RAID"
		else
			echo -e "${gl_huang}本机无法访问 GitHub，已改用 bin456789/reinstall（国内镜像 cnb.cool，安装时自动使用国内源）${gl_bai}"
			echo "可自定义 root 密码和 SSH 端口，不支持软 RAID"
		fi
		echo -e "${gl_hong}注意: 将清空硬盘上的全部数据！${gl_bai}重装约需 10~30 分钟，期间无法连接，请提前备份"
		if [ "$engine" = installnet ]; then
			echo -e "${gl_hui}脚本来源: https://github.com/leitbogioro/Tools${gl_bai}"
		else
			echo -e "${gl_hui}脚本来源: https://github.com/bin456789/reinstall${gl_bai}"
		fi
		echo "------------------------"
		echo "1. Debian 13 ★                2. Debian 12"
		echo "3. Ubuntu 24.04               4. Ubuntu 22.04"
		echo "5. AlmaLinux 9                6. Rocky Linux 9"
		if [ "$engine" = installnet ]; then
			echo "7. Alpine Linux (edge)"
		else
			echo "7. Alpine Linux (最新稳定版)"
		fi
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -r -e -p "请选择要重装的系统: " choice
		raid_ok=false
		# sys/ver: InstallNET 参数；rsys/rver: reinstall 参数（rver 为空表示最新版）
		case "$choice" in
			1) sys="-debian"; rsys="debian"; ver="13"; rver="13"; label="Debian 13"; raid_ok=true ;;
			2) sys="-debian"; rsys="debian"; ver="12"; rver="12"; label="Debian 12"; raid_ok=true ;;
			3) sys="-ubuntu"; rsys="ubuntu"; ver="24.04"; rver="24.04"; label="Ubuntu 24.04" ;;
			4) sys="-ubuntu"; rsys="ubuntu"; ver="22.04"; rver="22.04"; label="Ubuntu 22.04" ;;
			5) sys="-almalinux"; rsys="almalinux"; ver="9"; rver="9"; label="AlmaLinux 9"; raid_ok=true ;;
			6) sys="-rockylinux"; rsys="rocky"; ver="9"; rver="9"; label="Rocky Linux 9"; raid_ok=true ;;
			7) sys="-alpine"; rsys="alpine"; ver="edge"; rver=""; label="Alpine Linux edge"
			   [ "$engine" = reinstall ] && label="Alpine Linux（最新稳定版）" ;;
			0) return ;;
			*) continue ;;
		esac
		break
	done
	[ "$engine" = reinstall ] && raid_ok=false

	echo ""
	echo -e "${gl_cyan}重装为 ${label}${gl_bai}"
	echo "------------------------"

	# root 密码（InstallNET 未对密码加引号，仅允许安全字符）
	if [ "$engine" = installnet ] && [ "$sys" = "-alpine" ]; then
		pwd="LeitboGi0ro"
		echo -e "Alpine 不支持自定义密码，初始 root 密码固定为: ${gl_huang}${pwd}${gl_bai}"
	else
		while true; do
			read -r -s -p "设置 root 密码（直接回车随机生成）: " pwd
			echo ""
			if [ -z "$pwd" ]; then
				pwd=$(tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 16)
				echo -e "已生成随机密码: ${gl_huang}${pwd}${gl_bai}  ${gl_hong}请务必记下${gl_bai}"
				break
			fi
			if ! [[ "$pwd" =~ ^[A-Za-z0-9@#%+=:,._-]{6,64}$ ]]; then
				echo -e "${gl_hong}密码需为 6-64 位，仅可包含字母、数字和 @ # % + = : , . _ -${gl_bai}"
				continue
			fi
			read -r -s -p "再次输入确认: " pwd2
			echo ""
			[ "$pwd" = "$pwd2" ] || { echo -e "${gl_hong}两次输入不一致${gl_bai}"; continue; }
			if [ "${#pwd}" -lt 12 ] || [[ "$pwd" =~ ^[0-9]+$ ]]; then
				echo -e "${gl_huang}这是弱密码，仅适合临时使用，重装后请立即修改（新机开荒第 2 步）${gl_bai}"
			fi
			break
		done
	fi

	# SSH 端口
	while true; do
		read -r -e -p "设置 SSH 端口 [默认 22]: " port
		port=${port:-22}
		[[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ] && break
		echo -e "${gl_hong}端口需为 1-65535 的数字${gl_bai}"
	done

	# 软 RAID（多块硬盘时可选）
	raid=""
	disk_list=$(lsblk -dn -o NAME,SIZE,TYPE,MODEL 2>/dev/null | awk '$3=="disk" && $1 !~ /^(loop|ram|zram|sr|fd)/')
	disks=$(printf '%s\n' "$disk_list" | grep -c .)
	if [ "$disks" -ge 2 ]; then
		echo "------------------------"
		echo "检测到 $disks 块硬盘:"
		printf '%s\n' "$disk_list" | sed 's/^/  /'
		if [ "$raid_ok" = true ]; then
			echo "软 RAID: 0. 不使用（默认）  1. RAID 0  2. RAID 1  3. RAID 5  4. RAID 6  5. RAID 10"
			echo -e "${gl_hui}RAID 0 容量最大但任一硬盘损坏即丢失全部数据；RAID 1 镜像最安全；RAID 5 至少 3 块，RAID 6/10 至少 4 块${gl_bai}"
			while true; do
				read -r -e -p "请选择 [默认 0]: " choice
				case "${choice:-0}" in
					0) raid=""; break ;;
					1) raid="0" ;;
					2) raid="1" ;;
					3) raid="5"; [ "$disks" -ge 3 ] || { echo "RAID 5 至少需要 3 块硬盘"; continue; } ;;
					4) raid="6"; [ "$disks" -ge 4 ] || { echo "RAID 6 至少需要 4 块硬盘"; continue; } ;;
					5) raid="10"; [ "$disks" -ge 4 ] || { echo "RAID 10 至少需要 4 块硬盘"; continue; } ;;
					*) continue ;;
				esac
				break
			done
			if [ -n "$raid" ]; then
				echo -e "${gl_huang}OVH 独服提示: 请先在 OVH 面板用官方模板、默认分区方式安装一次系统，再执行本重装，否则可能无法引导${gl_bai}"
			fi
		elif [ "$engine" = reinstall ]; then
			echo -e "${gl_hui}reinstall 不支持软 RAID，将安装到当前系统所在硬盘${gl_bai}"
		else
			echo -e "${gl_hui}${label} 不支持 InstallNET 的软 RAID，将安装到单块硬盘${gl_bai}"
		fi
	fi

	if [ "$engine" = installnet ]; then
		args=("$sys" "$ver")
		[ "$sys" = "-alpine" ] || args+=(-pwd "$pwd")
		args+=(-port "$port")
		[ -n "$raid" ] && args+=(-raid "$raid")
	else
		args=("$rsys")
		[ -n "$rver" ] && args+=("$rver")
		args+=(--password "$pwd" --ssh-port "$port")
	fi

	echo ""
	echo -e "${gl_cyan}确认重装信息${gl_bai}"
	echo "------------------------"
	echo "系统      : $label"
	echo -e "root 密码 : ${gl_huang}${pwd}${gl_bai}"
	echo "SSH 端口  : $port"
	if [ -n "$raid" ]; then echo "软 RAID   : RAID $raid"; else echo "软 RAID   : 不使用"; fi
	echo "执行命令  : bash ${installer##*/} ${args[*]}" | sed -E "s/(-pwd|--password) [^ ]*/\1 ******/"
	echo "------------------------"
	echo -e "${gl_hong}硬盘数据将被全部清除，且无法恢复！${gl_bai}"
	read -r -e -p "确认重装请输入 yes: " confirm
	[ "$confirm" = "yes" ] || { echo "已取消"; return 1; }

	chmod +x "$installer"
	if (cd /root && bash "$installer" "${args[@]}"); then
		echo ""
		echo -e "${gl_lv}安装环境已准备好，重启后开始重装${gl_bai}（可在服务商 VNC 中查看进度）"
		echo -e "重装完成后用 ${gl_huang}root / 上面的密码 / 端口 ${port}${gl_bai} 登录"
		server_reboot
	else
		echo -e "${gl_hong}${name} 执行失败，未重启。请根据上方输出排查${gl_bai}"
		return 1
	fi
}



# 是否为 Proxmox VE 宿主机
# 不依赖主机名：pveversion 命令、/etc/pve（pmxcfs）或已安装 pve-manager 任一满足即视为 PVE
nb_is_pve() {
	command -v pveversion >/dev/null 2>&1 && return 0
	[ -d /etc/pve ] && return 0
	dpkg-query -W -f='${Status}' pve-manager 2>/dev/null | grep -q 'install ok installed'
}

# 不更换内核，只开启当前内核自带的 BBR + fq
nb_bbr_only() {
	local reason="$1" choice
	clear
	echo "BBR 加速（不更换内核）"
	echo "------------------------------------------------"
	echo -e "$reason"
	echo "将使用当前内核自带的 BBR 拥塞控制 + fq 队列，写入 /etc/sysctl.d/99-nimbus-bbr.conf"
	echo "当前内核: $(uname -r)    当前算法: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null) / $(sysctl -n net.core.default_qdisc 2>/dev/null)"
	echo "------------------------------------------------"
	read -r -e -p "确定开启吗？(Y/N): " choice
	case "$choice" in
		[Yy]) ;;
		*) echo "已取消"; return ;;
	esac
	modprobe tcp_bbr >/dev/null 2>&1
	if ! sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
		echo -e "${gl_hong}当前内核不支持 BBR（或容器内无权修改），未做更改${gl_bai}"
		return 1
	fi
	bbr_on
	echo -e "${gl_lv}已开启: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null) / $(sysctl -n net.core.default_qdisc 2>/dev/null)，无需重启${gl_bai}"
}

bbrv3() {
			  root_use

		  xanmod_add_repo() {
				local keyring="/usr/share/keyrings/xanmod-archive-keyring.gpg"
				local list_file="/etc/apt/sources.list.d/xanmod-release.list"
				local key_url="https://dl.xanmod.org/archive.key"
				local os_codename="" repo tmpkey m

				if command -v lsb_release >/dev/null 2>&1; then
					os_codename=$(lsb_release -sc)
				elif [ -r /etc/os-release ]; then
					os_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
				fi

				# 兼容官方已移除的老系统代号（回退使用 releases 尝试旧包库）
				if ! echo "bookworm trixie forky sid noble plucky questing resolute faye gigi wilma xia zara zena" | grep -qw "$os_codename"; then
					os_codename="releases"
				fi

				# 官方已彻底移除对 jammy, focal, bullseye 等老系统的 apt 支持
				if echo "jammy focal bullseye buster" | grep -qw "$os_codename" || [ "$os_codename" = "releases" ]; then
					echo -e "${gl_hong}XanMod 官方已停止对当前系统($os_codename)的 APT 源支持，请升级至 Debian12 / Ubuntu24 或更高版本。${gl_bai}"
					return 1
				fi

				if [ -z "$os_codename" ]; then
					echo "无法获取系统代号，无法配置XanMod源"
					return 1
				fi

				install wget gnupg ca-certificates
				mkdir -p /usr/share/keyrings /etc/apt/sources.list.d

				# 仓库：官方 deb.xanmod.org 连不上时（如无国际出口的国内机器）改用国内镜像，与官方同步
				# 南京大学在前：清华 TUNA 对非教育网限速明显（实测腾讯云广州 ~160 KB/s，南大 ~17 MB/s）
				repo=""
				if nb_tcp_ok deb.xanmod.org 80; then
					repo="http://deb.xanmod.org"
				else
					for m in mirror.nju.edu.cn mirrors.tuna.tsinghua.edu.cn mirrors.bfsu.edu.cn; do
						if nb_tcp_ok "$m" 443; then
							repo="https://$m/xanmod"
							echo "XanMod 官方仓库无法连接，改用国内镜像 $m"
							break
						fi
					done
				fi
				if [ -z "$repo" ]; then
					echo -e "${gl_hong}XanMod 官方仓库和国内镜像都无法连接，请检查网络${gl_bai}"
					return 1
				fi

				# 公钥：官方 → GitHub 备份（国内走代理）→ 内置；官方仓库连不上时直接用内置公钥，避免逐个等待超时
				tmpkey=$(mktemp)
				if [ "$repo" = "http://deb.xanmod.org" ] &&
					{ wget -q -T 15 -t 2 -O "$tmpkey" "$key_url" && grep -q 'BEGIN PGP PUBLIC KEY' "$tmpkey"; }; then
					:
				elif [ "$repo" = "http://deb.xanmod.org" ] &&
					nb_download raw.githubusercontent.com/zidou-kiyn/nimbus/main/archive.key "$tmpkey" && grep -q 'BEGIN PGP PUBLIC KEY' "$tmpkey"; then
					echo "官方密钥下载失败，已使用备用下载源"
				else
					nb_xanmod_key > "$tmpkey"
				fi
				if ! gpg --dearmor < "$tmpkey" > "$keyring.tmp" 2>/dev/null || [ ! -s "$keyring.tmp" ]; then
					rm -f "$tmpkey" "$keyring.tmp"
					echo "XanMod 公钥导入失败"
					return 1
				fi
				rm -f "$tmpkey"
				mv -f "$keyring.tmp" "$keyring"
				chmod 644 "$keyring"
				echo "deb [signed-by=$keyring] $repo $os_codename main" > "$list_file"
		  }

		  xanmod_detect_psabi_level() {
				local psabi_output=""
				psabi_output=$(awk 'BEGIN {
					while (!/flags/) if (getline < "/proc/cpuinfo" != 1) exit 1
					if (/lm/&&/cmov/&&/cx8/&&/fpu/&&/fxsr/&&/mmx/&&/syscall/&&/sse2/) level = 1
					if (level == 1 && /cx16/&&/lahf/&&/popcnt/&&/sse4_1/&&/sse4_2/&&/ssse3/) level = 2
					if (level == 2 && /avx/&&/avx2/&&/bmi1/&&/bmi2/&&/f16c/&&/fma/&&/abm/&&/movbe/&&/xsave/) level = 3
					if (level == 3 && /avx512f/&&/avx512bw/&&/avx512cd/&&/avx512dq/&&/avx512vl/) level = 4
					if (level > 0) { print level; exit }
					exit 1
				}' /proc/cpuinfo 2>/dev/null) || return 1
				printf '%s' "$psabi_output" | tr -dc '0-9' | head -c 1
		  }

		  xanmod_package_available() {
				local package="$1"
				LC_ALL=C apt-cache policy "$package" 2>/dev/null | grep -q 'Candidate: [^ ]'
		  }

		  xanmod_detect_package() {
				local psabi_level=""
				local level=""
				local package=""
				local prefix_list="linux-xanmod-lts"

				psabi_level=$(xanmod_detect_psabi_level) || return 1
				[ -n "$psabi_level" ] || return 1
				[ "$psabi_level" -gt 3 ] && psabi_level=3

				apt update -y >/dev/null 2>&1

				for prefix in $prefix_list; do
					level="$psabi_level"
					while [ "$level" -ge 1 ]; do
						package="${prefix}-x64v${level}"
						if xanmod_package_available "$package"; then
							echo "已匹配 XanMod LTS 内核包: $package" >&2
							printf '%s\n' "$package"
							return 0
						fi
						level=$((level - 1))
					done
				done

				echo "软件源中未找到适配此CPU的XanMod LTS内核包" >&2
				return 1
		  }

		  xanmod_installed() {
				dpkg-query -W -f='${Package}\n' 'linux-*xanmod*' 2>/dev/null | grep -q '^linux-.*xanmod'
		  }

		  xanmod_install_or_update() {
				local action="$1"
				local package=""

				check_disk_space 3
				check_swap
				xanmod_add_repo || {
					echo "XanMod官方仓库配置失败，请稍后重试"
					return 1
				}

				package=$(xanmod_detect_package) || {
					echo "无法识别当前CPU或找不到匹配内核包，已取消安装"
					return 1
				}

				apt update -y
				if [ "$action" = "update" ]; then
					apt install -y --only-upgrade "$package" || apt install -y "$package" || {
						echo "XanMod内核更新失败，请检查软件源或稍后重试"
						return 1
					}
				else
					apt install -y "$package" || {
						echo "XanMod内核安装失败，请检查软件源或稍后重试"
						return 1
					}
				fi

				bbr_on || {
					echo "BBRv3参数写入失败，请检查系统配置"
					return 1
				}
				echo "XanMod LTS 内核安装完成，已设置 BBRv3 + fq，重启后生效"
				server_reboot
		  }

		  xanmod_uninstall() {
				apt purge -y 'linux-*xanmod*'
				apt autoremove -y
				update-grub 2>/dev/null || true
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f /usr/share/keyrings/xanmod-archive-keyring.gpg
				echo "XanMod内核已卸载。重启后生效"
				server_reboot
		  }


		  local cpu_arch virt_c os_id=""
		  cpu_arch=$(uname -m)
		  if nb_is_pve; then
			nb_bbr_only "检测到 ${gl_huang}Proxmox VE 宿主机${gl_bai}：不安装 XanMod。PVE 依赖自带的 proxmox-kernel（ZFS、KVM/LXC 支持随它发布），更换内核会失去官方支持"
			return
		  fi
		  virt_c=$(systemd-detect-virt -c 2>/dev/null)
		  if [ -n "$virt_c" ] && [ "$virt_c" != "none" ]; then
			nb_bbr_only "检测到容器环境（${virt_c}），无法更换内核"
			return
		  fi
		  if [ "$cpu_arch" != "x86_64" ]; then
			nb_bbr_only "XanMod 内核仅支持 x86_64，当前架构: $cpu_arch"
			return
		  fi
		  # shellcheck source=/dev/null
		  [ -r /etc/os-release ] && os_id=$(. /etc/os-release && echo "$ID")
		  if [ "$os_id" != "debian" ] && [ "$os_id" != "ubuntu" ]; then
			nb_bbr_only "XanMod 仅支持 Debian / Ubuntu，当前系统: ${os_id:-未知}"
			return
		  fi

		  if xanmod_installed; then
			while true; do
				  clear
				  local kernel_version=$(uname -r)
				  echo "已安装 XanMod 内核"
				  echo "当前内核版本: $kernel_version"
				  echo "当前TCP算法: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null) $(sysctl -n net.core.default_qdisc 2>/dev/null)"

				  echo ""
				  echo "内核管理"
				  echo "------------------------"
				  echo "1. 更新XanMod LTS内核         2. 卸载XanMod内核"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						xanmod_install_or_update update
						;;
					  2)
						xanmod_uninstall
						;;
					  *)
						break
						;;

				  esac
			done
		else

		  clear
		  echo "BBRv3 加速"
		  echo "------------------------------------------------"
		  echo "将安装 XanMod LTS 内核，开启 BBRv3 拥塞控制，队列算法使用 fq"
		  echo "仅支持 Debian/Ubuntu x86_64，请提前备份数据，安装后需重启"
		  echo "------------------------------------------------"
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			xanmod_install_or_update install
			  ;;
			[Nn])
			  echo "已取消"
			  ;;
			*)
			  echo "无效的选择，请输入 Y 或 N。"
			  ;;
		  esac
		fi

}



update_locale() {
	local lang=$1
	local locale_file=$2

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case $ID in
			debian|ubuntu|kali)
				install locales
				sed -i "s/^\s*#\?\s*${locale_file}/${locale_file}/" /etc/locale.gen
				locale-gen
				echo "LANG=${lang}" > /etc/default/locale
				export LANG=${lang}
				echo -e "${gl_lv}系统语言已经修改为: $lang 重新连接SSH生效。${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}系统语言已经修改为: $lang 重新连接SSH生效。${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "不支持的系统: $ID"
				break_end
				;;
		esac
	else
		echo "不支持的系统，无法识别系统类型。"
		break_end
	fi
}



linux_language() {
root_use
while true; do
  clear
  echo "当前系统语言: $LANG"
  echo "------------------------"
  echo "1. 英文          2. 简体中文          3. 繁体中文"
  echo "------------------------"
  echo "0. 返回上一级选单"
  echo "------------------------"
  read -e -p "输入你的选择: " choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  ;;
	  *)
		  break
		  ;;
  esac
done
}



# PS1 写在哪个文件：登录时会加载 ~/.bashrc 就写 ~/.bashrc（ble.sh 在 .bashrc 末尾 ble-attach，
# 之后再设的 PS1 会被它还原，所以必须写在 .bashrc 里、attach 之前）；否则写 ~/.profile（如 Alpine）
nb_ps1_rc() {
	local f
	for f in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
		[ -f "$f" ] || continue
		grep -qs '\.bashrc' "$f" && echo "$HOME/.bashrc" || echo "$HOME/.profile"
		return
	done
	echo "$HOME/.profile"
}

# 把 stdin 里的 nimbus PS1 块写进 $1：有 ble.sh attach 块时插在它前面，否则追加到末尾
nb_ps1_insert() {
	local rc="$1" blk tmp
	blk=$(cat)
	[ -n "$blk" ] || return 0
	touch "$rc"
	if grep -q '^# >>> nimbus ble\.sh attach >>>' "$rc"; then
		tmp=$(mktemp) || return 1
		BLK="$blk" awk '/^# >>> nimbus ble\.sh attach >>>/ && !done { print ENVIRON["BLK"]; done = 1 } { print }' "$rc" > "$tmp" &&
			cat "$tmp" > "$rc"
		rm -f "$tmp"
	else
		printf '%s\n' "$blk" >> "$rc"
	fi
}

shell_bianse_profile() {
	# PS1 使用 bash 专有转义：放在 if [ -n "$BASH" ] 中，避免 dash 等 sh 登录时原样打印
	local rc
	rc=$(nb_ps1_rc)
	# 清理旧版直接写入的 PS1= 行和 .profile / .bashrc 里已有的 nimbus 配置块
	nb_ps1_profile_clean
	[ -f "$HOME/.bashrc" ] && sed -i -e '/^PS1=/d' -e '/^# >>> nimbus PS1 >>>$/,/^# <<< nimbus PS1 <<<$/d' "$HOME/.bashrc"
	if [ -n "$bianse" ]; then
		{
			echo '# >>> nimbus PS1 >>>'
			# shellcheck disable=SC2016  # 有意写入字面量 $BASH
			echo 'if [ -n "$BASH" ]; then'
			echo "	${bianse}"
			echo 'fi'
			echo '# <<< nimbus PS1 <<<'
		} | nb_ps1_insert "$rc"
	fi
	echo -e "${gl_lv}变更完成（写入 $rc）。重新连接SSH后可查看变化！${gl_bai}"
	hash -r
	break_end
}



shell_bianse() {
  root_use
  while true; do
	clear
	echo "命令行美化工具"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#  ${gl_huang}★${gl_bai}"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 返回上一级选单"
	echo "------------------------"
	read -e -p "输入你的选择: " choice

	case $choice in
	  1)
		local bianse="PS1='\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;31m\]\w\[\033[0m\] # '"
		shell_bianse_profile

		;;
	  2)
		local bianse="PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;33m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  3)
		local bianse="PS1='\[\033[1;31m\]\u\[\033[0m\]@\[\033[1;32m\]\h\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  4)
		local bianse="PS1='\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\] \[\033[1;37m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  5)
		local bianse="PS1='\[\033[1;37m\]\u\[\033[0m\]@\[\033[1;31m\]\h\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  6)
		local bianse="PS1='\[\033[1;33m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;35m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  7)
		local bianse=""
		shell_bianse_profile
		;;
	  *)
		break
		;;
	esac

  done
}



# 创建备份
create_backup() {
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 提示用户输入备份目录
	echo "创建备份示例："
	echo "  - 备份单个目录: /var/www"
	echo "  - 备份多个目录: /etc /home /var/log"
	echo "  - 直接回车将使用默认目录 (/etc /usr /home)"
	read -e -p "请输入要备份的目录（多个目录用空格分隔，直接回车则使用默认目录）：" input

	# 如果用户没有输入目录，则使用默认目录
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# 将用户输入的目录按空格分隔成数组
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# 生成备份文件前缀
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 提取目录名称并去除斜杠
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 去除最后一个下划线
	local PREFIX=${PREFIX%_}

	# 生成备份文件名
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 打印用户选择的目录
	echo "您选择的备份目录为："
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "正在创建备份 $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "备份创建成功: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "备份创建失败！"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	# 选择要恢复的备份
	read -e -p "请输入要恢复的备份文件名: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "备份文件不存在！"
		exit 1
	fi

	echo "正在恢复备份 $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "备份恢复成功！"
	else
		echo "备份恢复失败！"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "可用的备份："
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {

	read -e -p "请输入要删除的备份文件名: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "备份文件不存在！"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "备份删除成功！"
	else
		echo "备份删除失败！"
		exit 1
	fi
}

# 备份主菜单
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		echo "系统备份功能"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. 创建备份        2. 恢复备份        3. 删除备份"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "按回车键继续..."
	done
}



# SSH 输入标准化函数
nb_ssh_validate_host() {
	local host="$1"
	[[ -n "$host" && ! "$host" =~ [[:space:]] && "$host" =~ ^[A-Za-z0-9._:-]+$ ]]
}

nb_ssh_validate_port() {
	local port="$1"
	[[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

nb_ssh_validate_user() {
	local user="$1"
	[[ -n "$user" && "$user" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]]
}

nb_ssh_read_host_port() {
	local host_prompt="$1"
	local port_prompt="$2"
	local default_port="${3:-22}"

	while true; do
		read -e -p "$host_prompt" NB_SSH_HOST
		if nb_ssh_validate_host "$NB_SSH_HOST"; then
			break
		fi
		echo "错误: 请输入有效的服务器地址。"
	done

	while true; do
		read -e -p "$port_prompt" NB_SSH_PORT
		NB_SSH_PORT=${NB_SSH_PORT:-$default_port}
		if nb_ssh_validate_port "$NB_SSH_PORT"; then
			break
		fi
		echo "错误: 端口必须是 1-65535 之间的数字。"
	done
}

nb_ssh_read_host_user_port() {
	local host_prompt="$1"
	local user_prompt="$2"
	local port_prompt="$3"
	local default_user="${4:-root}"
	local default_port="${5:-22}"

	nb_ssh_read_host_port "$host_prompt" "$port_prompt" "$default_port"

	while true; do
		read -e -p "$user_prompt" NB_SSH_USER
		NB_SSH_USER=${NB_SSH_USER:-$default_user}
		if nb_ssh_validate_user "$NB_SSH_USER"; then
			break
		fi
		echo "错误: 用户名格式不正确。"
	done
}



# 列出可用的硬盘分区
list_partitions() {
	echo "可用的硬盘分区："
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}


# 持久化挂载分区
mount_partition() {
	read -e -p "请输入要挂载的分区名称（例如 sda1）: " PARTITION

	DEVICE="/dev/$PARTITION"
	MOUNT_POINT="/mnt/$PARTITION"

	# 检查分区是否存在
	if ! lsblk -no NAME | grep -qw "$PARTITION"; then
		echo "分区不存在！"
		return 1
	fi

	# 检查是否已挂载
	if mount | grep -qw "$DEVICE"; then
		echo "分区已经挂载！"
		return 1
	fi

	# 获取 UUID
	UUID=$(blkid -s UUID -o value "$DEVICE")
	if [ -z "$UUID" ]; then
		echo "无法获取 UUID！"
		return 1
	fi

	# 获取文件系统类型
	FSTYPE=$(blkid -s TYPE -o value "$DEVICE")
	if [ -z "$FSTYPE" ]; then
		echo "无法获取文件系统类型！"
		return 1
	fi

	# 创建挂载点
	mkdir -p "$MOUNT_POINT"

	# 挂载
	if ! mount "$DEVICE" "$MOUNT_POINT"; then
		echo "分区挂载失败！"
		rmdir "$MOUNT_POINT"
		return 1
	fi

	echo "分区已成功挂载到 $MOUNT_POINT"

	# 检查 /etc/fstab 是否已经存在 UUID 或挂载点
	if grep -qE "UUID=$UUID|[[:space:]]$MOUNT_POINT[[:space:]]" /etc/fstab; then
		echo "/etc/fstab 中已存在该分区记录，跳过写入"
		return 0
	fi

	# 写入 /etc/fstab
	echo "UUID=$UUID $MOUNT_POINT $FSTYPE defaults,nofail 0 2" >> /etc/fstab

	echo "已写入 /etc/fstab，实现持久化挂载"
}


# 卸载分区
unmount_partition() {
	read -e -p "请输入要卸载的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "分区未挂载！"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "分区卸载成功: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "分区卸载失败！"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "已挂载的分区："
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	read -e -p "请输入要格式化的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "分区不存在！"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "分区已经挂载，请先卸载！"
		return
	fi

	# 选择文件系统类型
	echo "请选择文件系统类型："
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "请输入你的选择: " FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "无效的选择！"; return ;;
	esac

	# 确认格式化
	read -e -p "确认格式化分区 /dev/$PARTITION 为 $FS_TYPE 吗？(y/n): " CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作已取消。"
		return
	fi

	# 格式化分区
	echo "正在格式化分区 /dev/$PARTITION 为 $FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "分区格式化成功！"
	else
		echo "分区格式化失败！"
	fi
}

# 检查分区状态
check_partition() {
	read -e -p "请输入要检查的分区名称（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "分区不存在！"
		return
	fi

	# 检查分区状态
	echo "检查分区 /dev/$PARTITION 的状态："
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	while true; do
		clear
		echo "硬盘分区管理"
		echo -e "${gl_huang}该功能内部测试阶段，请勿在生产环境使用。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. 挂载分区        2. 卸载分区        3. 查看已挂载分区"
		echo "4. 格式化分区      5. 检查分区状态"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "按回车键继续..."
	done
}



linux_info() {



	clear
	echo -e "${gl_cyan}正在查询系统信息……${gl_bai}"

	ip_address

	local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

	local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
		<(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

	local cpu_cores=$(nproc)

	local cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')

	local mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2fM (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

	local disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

	local ipinfo=$(curl -s --connect-timeout 3 -m 5 ipinfo.io)
	local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
	local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
	local isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')
	[ -n "$country" ] || country=$(nb_country)

	local load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
	local dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)


	local cpu_arch=$(uname -m)

	local hostname=$(uname -n)

	local kernel_version=$(uname -r)

	local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
	local queue_algorithm=$(sysctl -n net.core.default_qdisc)

	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')

	output_status

	local current_time=$(date "+%Y-%m-%d %I:%M %p")


	local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

	local timezone=$(current_timezone)

	local tcp_count=$(ss -t | wc -l)
	local udp_count=$(ss -u | wc -l)

	clear
	echo -e "系统信息查询"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}主机名:         ${gl_bai}$hostname"
	echo -e "${gl_cyan}系统版本:       ${gl_bai}$os_info"
	echo -e "${gl_cyan}Linux版本:      ${gl_bai}$kernel_version"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}CPU架构:        ${gl_bai}$cpu_arch"
	echo -e "${gl_cyan}CPU型号:        ${gl_bai}$cpu_info"
	echo -e "${gl_cyan}CPU核心数:      ${gl_bai}$cpu_cores"
	echo -e "${gl_cyan}CPU频率:        ${gl_bai}$cpu_freq"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}CPU占用:        ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_cyan}系统负载:       ${gl_bai}$load"
	echo -e "${gl_cyan}TCP|UDP连接数:  ${gl_bai}$tcp_count|$udp_count"
	echo -e "${gl_cyan}物理内存:       ${gl_bai}$mem_info"
	echo -e "${gl_cyan}虚拟内存:       ${gl_bai}$swap_info"
	echo -e "${gl_cyan}硬盘占用:       ${gl_bai}$disk_info"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}总接收:         ${gl_bai}$rx"
	echo -e "${gl_cyan}总发送:         ${gl_bai}$tx"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}网络算法:       ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}运营商:         ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_cyan}IPv4地址:       ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_cyan}IPv6地址:       ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_cyan}DNS地址:        ${gl_bai}$dns_addresses"
	echo -e "${gl_cyan}地理位置:       ${gl_bai}$country $city"
	echo -e "${gl_cyan}系统时间:       ${gl_bai}$timezone $current_time"
	echo -e "${gl_cyan}-------------"
	echo -e "${gl_cyan}运行时长:       ${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  echo -e "基础工具"

	  tools=(
		curl wget sudo socat htop iftop unzip tar tmux ffmpeg
		btop ranger ncdu fzf
		vim nano git realm
	  )

	  if command -v apt >/dev/null 2>&1; then
		PM="apt"
	  elif command -v dnf >/dev/null 2>&1; then
		PM="dnf"
	  elif command -v yum >/dev/null 2>&1; then
		PM="yum"
	  elif command -v pacman >/dev/null 2>&1; then
		PM="pacman"
	  elif command -v apk >/dev/null 2>&1; then
		PM="apk"
	  elif command -v zypper >/dev/null 2>&1; then
		PM="zypper"
	  elif command -v opkg >/dev/null 2>&1; then
		PM="opkg"
	  elif command -v pkg >/dev/null 2>&1; then
		PM="pkg"
	  else
		echo "❌ 未识别的包管理器"
		exit 1
	  fi

	  echo "📦 使用包管理器: $PM"
	  echo -e "${gl_cyan}------------------------${gl_bai}"

	  for ((i=0; i<${#tools[@]}; i+=2)); do
		# 左列
		if command -v "${tools[i]}" >/dev/null 2>&1; then
		  left=$(printf "✅ %-12s 已安装" "${tools[i]}")
		else
		  left=$(printf "❌ %-12s 未安装" "${tools[i]}")
		fi

		# 右列（防止数组越界）
		if [[ -n "${tools[i+1]}" ]]; then
		  if command -v "${tools[i+1]}" >/dev/null 2>&1; then
			right=$(printf "✅ %-12s 已安装" "${tools[i+1]}")
		  else
			right=$(printf "❌ %-12s 未安装" "${tools[i+1]}")
		  fi
		  printf "%-42s %s\n" "$left" "$right"
		else
		  printf "%s\n" "$left"
		fi
	  done

	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}1.   ${gl_bai}curl 下载工具 ${gl_huang}★${gl_bai}                   ${gl_cyan}2.   ${gl_bai}wget 下载工具 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}3.   ${gl_bai}sudo 超级管理权限工具             ${gl_cyan}4.   ${gl_bai}socat 通信连接工具"
	  echo -e "${gl_cyan}5.   ${gl_bai}htop 系统监控工具                 ${gl_cyan}6.   ${gl_bai}iftop 网络流量监控工具"
	  echo -e "${gl_cyan}7.   ${gl_bai}unzip ZIP压缩解压工具             ${gl_cyan}8.   ${gl_bai}tar GZ压缩解压工具"
	  echo -e "${gl_cyan}9.   ${gl_bai}tmux 多路后台运行工具             ${gl_cyan}10.  ${gl_bai}ffmpeg 视频编码直播推流工具"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}11.  ${gl_bai}btop 现代化监控工具 ${gl_huang}★${gl_bai}             ${gl_cyan}12.  ${gl_bai}ranger 文件管理工具"
	  echo -e "${gl_cyan}13.  ${gl_bai}ncdu 磁盘占用查看工具             ${gl_cyan}14.  ${gl_bai}fzf 全局搜索工具"
	  echo -e "${gl_cyan}15.  ${gl_bai}vim 文本编辑器                    ${gl_cyan}16.  ${gl_bai}nano 文本编辑器 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}17.  ${gl_bai}git 版本控制系统                  ${gl_cyan}18.  ${gl_bai}realm 端口转发（xwPF）"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}31.  ${gl_bai}全部安装 ${gl_huang}★${gl_bai}                        ${gl_cyan}32.  ${gl_bai}全部卸载"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}41.  ${gl_bai}安装指定工具                      ${gl_cyan}42.  ${gl_bai}卸载指定工具"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_cyan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "工具已安装，使用方法如下："
			  curl --help
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "工具已安装，使用方法如下："
			  wget --help
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "工具已安装，使用方法如下："
			  sudo --help
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "工具已安装，使用方法如下："
			  socat -h
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "工具已安装，使用方法如下："
			  unzip
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "工具已安装，使用方法如下："
			  tar --help
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "工具已安装，使用方法如下："
			  tmux --help
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "工具已安装，使用方法如下："
			  ffmpeg --help
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  ;;

			18)
			  clear
			  realm_xwpf
			  ;;

		  31)
			  clear
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  32)
			  clear
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "请输入安装的工具名（wget curl sudo htop）: " installname
			  install $installname
			  ;;
		  42)
			  clear
			  read -e -p "请输入卸载的工具名（htop ufw tmux）: " removename
			  remove $removename
			  ;;

		  0)
			  nimbus_home
			  ;;

		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end
  done



}


linux_bbr() {
	bbrv3
}



docker_ssh_migration() {

	is_compose_container() {
		local container=$1
		docker inspect "$container" | jq -e '.[0].Config.Labels["com.docker.compose.project"]' >/dev/null 2>&1
	}

	list_backups() {
		local BACKUP_ROOT="/tmp"
		echo -e "${gl_cyan}当前备份列表:${gl_bai}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "无备份"
	}



	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {

		echo -e "${gl_cyan}正在备份 Docker 容器...${gl_bai}"
		docker ps --format '{{.Names}}'
		read -e -p  "请输入要备份的容器名（多个空格分隔，回车备份全部运行中容器）: " containers

		install tar jq gzip
		install_docker

		local BACKUP_ROOT="/tmp"
		local DATE_STR=$(date +%Y%m%d_%H%M%S)
		local TARGET_CONTAINERS=()
		if [ -z "$containers" ]; then
			mapfile -t TARGET_CONTAINERS < <(docker ps --format '{{.Names}}')
		else
			read -ra TARGET_CONTAINERS <<< "$containers"
		fi
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${gl_hong}没有找到容器${gl_bai}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# 自动生成的还原脚本" >> "$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${gl_lv}备份容器: $c${gl_bai}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${gl_cyan}检测到 $c 是 docker-compose 容器${gl_bai}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "未检测到 compose 目录，请手动输入路径: " project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${gl_huang}Compose 项目 [$project_name] 已备份过，跳过重复打包...${gl_bai}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose 恢复: $project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${gl_lv}Compose 项目 [$project_name] 已打包: ${project_dir}${gl_bai}"
				else
					echo -e "${gl_hong}未找到 docker-compose.yml，跳过此容器...${gl_bai}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "打包卷: $path"
					tar -czpf "${BACKUP_DIR}/${c}_$(basename $path).tar.gz" -C / "$(echo $path | sed 's/^\///')"
				done

				# 端口
				local PORT_ARGS=""
				mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[] | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$inspect_file" 2>/dev/null)
				for p in "${PORTS[@]}"; do PORT_ARGS+="-p $p "; done

				# 环境变量
				local ENV_VARS=""
				mapfile -t ENVS < <(jq -r '.[0].Config.Env[] | @sh' "$inspect_file")
				for e in "${ENVS[@]}"; do ENV_VARS+="-e $e "; done

				# 卷映射
				local VOL_ARGS=""
				for path in $VOL_PATHS; do VOL_ARGS+="-v $path:$path "; done

				# 镜像
				local IMAGE
				IMAGE=$(jq -r '.[0].Config.Image' "$inspect_file")

				echo -e "\n# 还原容器: $c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${gl_cyan}备份 /home/docker 下的文件...${gl_bai}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${gl_lv}/home/docker 下的文件已打包到: ${BACKUP_DIR}/home_docker_files.tar.gz${gl_bai}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${gl_lv}备份完成: ${BACKUP_DIR}${gl_bai}"
		echo -e "${gl_lv}可用还原脚本: ${RESTORE_SCRIPT}${gl_bai}"


	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		read -e -p  "请输入要还原的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${gl_hong}备份目录不存在${gl_bai}"; return; }

		echo -e "${gl_cyan}开始执行还原操作...${gl_bai}"

		install tar jq gzip
		install_docker

		# --------- 优先还原 Compose 项目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p  "未找到原始路径，请输入还原目录路径: " original_path

				# 检查该 compose 项目的容器是否已经在运行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${gl_huang}Compose 项目 [$project_name] 已有容器在运行，跳过还原...${gl_bai}"
					continue
				fi

				read -e -p  "确认还原 Compose 项目 [$project_name] 到路径 [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "请输入新的还原路径: " original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${gl_lv}Compose 项目 [$project_name] 已解压到: $original_path${gl_bai}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${gl_lv}Compose 项目 [$project_name] 还原完成！${gl_bai}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${gl_cyan}检查并还原普通 Docker 容器...${gl_bai}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${gl_lv}处理容器: $container${gl_bai}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${gl_huang}容器 [$container] 已在运行，跳过还原...${gl_bai}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${gl_hong}未找到镜像信息，跳过: $container${gl_bai}"; continue; }

			# 端口映射
			PORT_ARGS=""
			mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$json")
			for p in "${PORTS[@]}"; do
				[[ -n "$p" ]] && PORT_ARGS="$PORT_ARGS -p $p"
			done

			# 环境变量
			ENV_ARGS=""
			mapfile -t ENVS < <(jq -r '.[0].Config.Env[]' "$json")
			for e in "${ENVS[@]}"; do
				ENV_ARGS="$ENV_ARGS -e \"$e\""
			done

			# 卷映射 + 卷数据恢复
			VOL_ARGS=""
			mapfile -t VOLS < <(jq -r '.[0].Mounts[] | "\(.Source):\(.Destination)"' "$json")
			for v in "${VOLS[@]}"; do
				VOL_SRC=$(echo "$v" | cut -d':' -f1)
				VOL_DST=$(echo "$v" | cut -d':' -f2)
				mkdir -p "$VOL_SRC"
				VOL_ARGS="$VOL_ARGS -v $VOL_SRC:$VOL_DST"

				VOL_FILE="$BACKUP_DIR/${container}_$(basename $VOL_SRC).tar.gz"
				if [[ -f "$VOL_FILE" ]]; then
					echo "恢复卷数据: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${gl_huang}容器 [$container] 存在但未运行，删除旧容器...${gl_bai}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "执行还原命令: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${gl_huang}未找到普通容器的备份信息${gl_bai}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${gl_cyan}正在还原 /home/docker 下的文件...${gl_bai}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${gl_lv}/home/docker 下的文件已还原完成${gl_bai}"
		else
			echo -e "${gl_huang}未找到 /home/docker 下文件的备份，跳过...${gl_bai}"
		fi


	}


	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		install jq
		read -e -p  "请输入要迁移的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${gl_hong}备份目录不存在${gl_bai}"; return; }

		nb_ssh_read_host_user_port "目标服务器IP: " "目标服务器SSH用户名 [默认root]: " "目标服务器SSH端口 [默认22]: " "root" "22"
		local TARGET_IP="$NB_SSH_HOST"
		local TARGET_USER="$NB_SSH_USER"
		local TARGET_PORT="$NB_SSH_PORT"

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${gl_huang}传输备份中...${gl_bai}"
		if [[ -z "$TARGET_PASS" ]]; then
			# 使用密钥登录
			scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no -r "$LATEST_TAR" "$TARGET_USER@$TARGET_IP:/tmp/"
		fi

	}

	# ----------------------------
	# 删除备份
	# ----------------------------
	delete_backup() {
		read -e -p  "请输入要删除的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${gl_hong}备份目录不存在${gl_bai}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${gl_lv}已删除备份: ${BACKUP_DIR}${gl_bai}"
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker备份/迁移/还原工具"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. 备份docker项目"
			echo -e "2. 迁移docker项目"
			echo -e "3. 还原docker项目"
			echo -e "4. 删除docker项目的备份文件"
			echo "------------------------"
			echo -e "0. 返回上一级选单"
			echo "------------------------"
			read -e -p  "请选择: " choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${gl_hong}无效选项${gl_bai}" ;;
			esac
		break_end
		done
	}

	main_menu
}



linux_docker() {

	while true; do
	  clear
	  echo -e "Docker管理"
	  docker_tato
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}1.   ${gl_bai}安装更新Docker环境 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}2.   ${gl_bai}查看Docker全局状态 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}3.   ${gl_bai}Docker容器管理 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}4.   ${gl_bai}Docker镜像管理"
	  echo -e "${gl_cyan}5.   ${gl_bai}Docker网络管理"
	  echo -e "${gl_cyan}6.   ${gl_bai}Docker卷管理"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}7.   ${gl_bai}清理无用的docker容器和镜像网络数据卷"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}8.   ${gl_bai}更换Docker源"
	  echo -e "${gl_cyan}9.   ${gl_bai}编辑daemon.json文件"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}11.  ${gl_bai}开启Docker-ipv6访问"
	  echo -e "${gl_cyan}12.  ${gl_bai}关闭Docker-ipv6访问"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}19.  ${gl_bai}备份/迁移/还原Docker环境"
	  echo -e "${gl_cyan}20.  ${gl_bai}卸载Docker环境"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_cyan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			clear
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  echo "Docker版本"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker镜像: ${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Docker容器: ${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Docker卷: ${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker网络: ${gl_lv}$network_count${gl_bai}"
			  docker network ls
			  echo ""

			  ;;
		  3)
			  docker_ps
			  ;;
		  4)
			  docker_image
			  ;;

		  5)
			  while true; do
				  clear
				  echo "Docker网络列表"
				  echo "------------------------------------------------------------"
				  docker network ls
				  echo ""

				  echo "------------------------------------------------------------"
				  container_ids=$(docker ps -q)
				  printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

				  for container_id in $container_ids; do
					  local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

					  local container_name=$(echo "$container_info" | awk '{print $1}')
					  local network_info=$(echo "$container_info" | cut -d' ' -f2-)

					  while IFS= read -r line; do
						  local network_name=$(echo "$line" | awk '{print $1}')
						  local ip_address=$(echo "$line" | awk '{print $2}')

						  printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
					  done <<< "$network_info"
				  done

				  echo ""
				  echo "网络操作"
				  echo "------------------------"
				  echo "1. 创建网络"
				  echo "2. 加入网络"
				  echo "3. 退出网络"
				  echo "4. 删除网络"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "设置新网络名: " dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  read -e -p "加入网络名: " dockernetwork
						  read -e -p "那些容器加入该网络（多个容器名请用空格分隔）: " dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  read -e -p "退出网络名: " dockernetwork
						  read -e -p "那些容器退出该网络（多个容器名请用空格分隔）: " dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  read -e -p "请输入要删除的网络名: " dockernetwork
						  docker network rm $dockernetwork
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  6)
			  while true; do
				  clear
				  echo "Docker卷列表"
				  docker volume ls
				  echo ""
				  echo "卷操作"
				  echo "------------------------"
				  echo "1. 创建新卷"
				  echo "2. 删除指定卷"
				  echo "3. 删除所有卷"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "设置新卷名: " dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "输入删除卷名（多个卷名请用空格分隔）: " dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "无效的选择，请输入 Y 或 N。"
							  ;;
						  esac
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;
		  7)
			  clear
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
			  ;;

		  9)
			  clear
			  install nano
			  mkdir -p /etc/docker && nano /etc/docker/daemon.json
			  restart docker
			  ;;



		  11)
			  clear
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  docker_ipv6_off
			  ;;

		  19)
			  docker_ssh_migration
			  ;;


		  20)
			  clear
			  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定卸载docker环境吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				  remove docker docker-compose docker-ce docker-ce-cli containerd.io
				  rm -f /etc/docker/daemon.json
				  hash -r
				  ;;
				[Nn])
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  0)
			  nimbus_home
			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  echo -e "测试脚本合集"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}IP及解锁状态检测"
	  echo -e "${gl_cyan}1.   ${gl_bai}ChatGPT 解锁状态检测"
	  echo -e "${gl_cyan}2.   ${gl_bai}Region 流媒体解锁测试"
	  echo -e "${gl_cyan}3.   ${gl_bai}yeahwu 流媒体解锁检测"
	  echo -e "${gl_cyan}4.   ${gl_bai}xykt IP质量体检脚本 ${gl_huang}★${gl_bai}"

	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}网络线路测速"
	  echo -e "${gl_cyan}11.  ${gl_bai}besttrace 三网回程延迟路由测试"
	  echo -e "${gl_cyan}12.  ${gl_bai}mtr_trace 三网回程线路测试"
	  echo -e "${gl_cyan}13.  ${gl_bai}Superspeed 三网测速"
	  echo -e "${gl_cyan}14.  ${gl_bai}nxtrace 快速回程测试脚本"
	  echo -e "${gl_cyan}15.  ${gl_bai}nxtrace 指定IP回程测试脚本"
	  echo -e "${gl_cyan}16.  ${gl_bai}ludashi2020 三网线路测试"
	  echo -e "${gl_cyan}17.  ${gl_bai}i-abc 多功能测速脚本"
	  echo -e "${gl_cyan}18.  ${gl_bai}NetQuality 网络质量体检脚本 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}19.  ${gl_bai}TcpQuality TCP重传探测脚本 ${gl_huang}★${gl_bai}"

	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}硬件性能测试"
	  echo -e "${gl_cyan}21.  ${gl_bai}yabs 性能测试"
	  echo -e "${gl_cyan}22.  ${gl_bai}icu/gb5 CPU性能测试脚本"

	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}综合性测试"
	  echo -e "${gl_cyan}31.  ${gl_bai}bench 性能测试"
	  echo -e "${gl_cyan}32.  ${gl_bai}spiritysdx 融合怪测评 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}33.  ${gl_bai}nodequality 融合怪测评 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_cyan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  echo "可参考的IP列表"
			  echo "------------------------"
			  echo "北京电信: 219.141.136.12"
			  echo "北京联通: 202.106.50.1"
			  echo "北京移动: 221.179.155.161"
			  echo "上海电信: 202.96.209.133"
			  echo "上海联通: 210.22.97.1"
			  echo "上海移动: 211.136.112.200"
			  echo "广州电信: 58.60.188.222"
			  echo "广州联通: 210.21.196.6"
			  echo "广州移动: 120.196.165.24"
			  echo "成都电信: 61.139.2.69"
			  echo "成都联通: 119.6.6.6"
			  echo "成都移动: 211.137.96.205"
			  echo "湖南电信: 36.111.200.100"
			  echo "湖南联通: 42.48.16.100"
			  echo "湖南移动: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "输入一个指定IP: " testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  19)
			  clear
			  bash <(curl -sL https://raw.githubusercontent.com/ibsgss/TcpQuality/main/runTcpQuality.sh)
			  ;;

		  21)
			  clear
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  check_swap
			  bash <(curl -fsSL ${gh_proxy}raw.githubusercontent.com/i-abc/GB5/main/gb5-test.sh)
			  ;;

		  31)
			  clear
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  clear
			  curl -L ${gh_proxy}github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  33)
			  clear
			  bash <(curl -sL https://run.NodeQuality.com)
			  ;;



		  0)
			  nimbus_home

			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done


}



docker_tato() {

	local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
	local image_count=$(docker images -q 2>/dev/null | wc -l)
	local network_count=$(docker network ls -q 2>/dev/null | wc -l)
	local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

	if command -v docker &> /dev/null; then
		echo -e "${gl_cyan}------------------------"
		echo -e "${gl_lv}环境已经安装${gl_bai}  容器: ${gl_lv}$container_count${gl_bai}  镜像: ${gl_lv}$image_count${gl_bai}  网络: ${gl_lv}$network_count${gl_bai}  卷: ${gl_lv}$volume_count${gl_bai}"
	fi
}



# 应用市场配置位于本仓库 apps/ 目录；浅克隆整个仓库后读取其中的 apps/



# 智能切换镜像源函数
switch_mirror() {
	# 可选参数，默认为 false
	local upgrade_software=${1:-false}
	local clean_cache=${2:-false}

	# 获取用户国家
	local country
	country=$(nb_country)

	echo "检测到国家：$country"

	if [ "$country" = "CN" ]; then
		echo "使用国内镜像源..."
		bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
		  --source mirrors.huaweicloud.com \
		  --protocol https \
		  --use-intranet-source false \
		  --backup true \
		  --upgrade-software "$upgrade_software" \
		  --clean-cache "$clean_cache" \
		  --ignore-backup-tips \
		  --install-epel false \
		  --pure-mode
	else
		echo "使用海外镜像源..."
		if [ -f /etc/os-release ] && grep -qi "oracle" /etc/os-release; then
			bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
			  --source mirrors.xtom.com \
			  --protocol https \
			  --use-intranet-source false \
			  --backup true \
			  --upgrade-software "$upgrade_software" \
			  --clean-cache "$clean_cache" \
			  --ignore-backup-tips \
			  --install-epel false \
			  --pure-mode
		else
			bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
				--use-official-source true \
				--protocol https \
				--use-intranet-source false \
				--backup true \
				--upgrade-software "$upgrade_software" \
				--clean-cache "$clean_cache" \
				--ignore-backup-tips \
				--install-epel false \
				--pure-mode
		fi
	fi
}


fail2ban_panel() {
		  root_use
		  # SSH 端口可能在别处被改过（手动修改、安装 fail2ban 前已改），进入面板时自动对齐
		  f2b_sync_ssh_port quiet
		  while true; do

				check_f2b_status
				echo -e "SSH防御程序 $check_f2b_status"
				echo "fail2ban是一个SSH防止暴力破解工具"
				echo "官网介绍: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 安装防御程序"
				echo "------------------------"
				echo "2. 查看SSH拦截记录"
				echo "3. 日志实时监控"
				echo "------------------------"
				echo "4. 基础参数配置（封禁时长/时间窗口/重试次数）"
				echo "5. 编辑配置文件（nano）"
				echo "------------------------"
				echo "9. 卸载防御程序"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice
				case $sub_choice in
					1)
						f2b_install_sshd
						cd ~
						f2b_status
						break_end
						;;
					2)
						echo "------------------------"
						f2b_sshd
						echo "------------------------"
						break_end
						;;
					3)
						tail -f /var/log/fail2ban.log
						break
						;;
					4)
						f2b_basic_config
						break_end
						;;
					5)
						f2b_edit_config
						break_end
						;;
					9)
						remove fail2ban
						rm -rf /etc/fail2ban
						echo "Fail2Ban防御程序已卸载"
						break
						;;
					*)
						break
						;;
				esac
		  done

}



net_menu() {

	show_nics() {
		echo "================ 当前网卡信息 ================"
		printf "%-18s %-12s %-20s %-26s\n" "网卡名" "状态" "IP地址" "MAC地址"
		echo "------------------------------------------------"
		for nic in $(ls /sys/class/net); do
			state=$(cat /sys/class/net/$nic/operstate 2>/dev/null)
			ipaddr=$(ip -4 addr show $nic | awk '/inet /{print $2}' | head -n1)
			mac=$(cat /sys/class/net/$nic/address 2>/dev/null)
			printf "%-15s %-10s %-18s %-20s\n" "$nic" "$state" "${ipaddr:-无}" "$mac"
		done
		echo "================================================"
	}

	while true; do
		clear
		show_nics
		echo
		echo "=========== 网卡管理菜单 ==========="
		echo "1. 启用网卡"
		echo "2. 禁用网卡"
		echo "3. 查看网卡详细信息"
		echo "4. 刷新网卡信息"
		echo "0. 返回上一级选单"
		echo "===================================="
		read -erp "请选择操作: " choice

		case $choice in
			1)
				read -erp "请输入要启用的网卡名: " nic
				if ip link show "$nic" &>/dev/null; then
					ip link set "$nic" up && echo "✔ 网卡 $nic 已启用"
				else
					echo "✘ 网卡不存在"
				fi
				read -erp "按回车继续..."
				;;
			2)
				read -erp "请输入要禁用的网卡名: " nic
				if ip link show "$nic" &>/dev/null; then
					ip link set "$nic" down && echo "✔ 网卡 $nic 已禁用"
				else
					echo "✘ 网卡不存在"
				fi
				read -erp "按回车继续..."
				;;
			3)
				read -erp "请输入要查看的网卡名: " nic
				if ip link show "$nic" &>/dev/null; then
					echo "========== $nic 详细信息 =========="
					ip addr show "$nic"
					ethtool "$nic" 2>/dev/null | head -n 10
				else
					echo "✘ 网卡不存在"
				fi
				read -erp "按回车继续..."
				;;
			4)
				continue
				;;
			*)
				break
				;;
		esac
	done
}



log_menu() {

	show_log_overview() {
		echo "============= 系统日志概览 ============="
		echo "主机名: $(hostname)"
		echo "系统时间: $(date)"
		echo
		echo "[ /var/log 目录占用 ]"
		du -sh /var/log 2>/dev/null
		echo
		echo "[ journal 日志占用 ]"
		journalctl --disk-usage 2>/dev/null
		echo "========================================"
	}

	while true; do
		clear
		show_log_overview
		echo
		echo "=========== 系统日志管理菜单 ==========="
		echo "1. 查看最近系统日志（journal）"
		echo "2. 查看指定服务日志"
		echo "3. 查看登录/安全日志"
		echo "4. 实时跟踪日志"
		echo "5. 清理旧 journal 日志"
		echo "0. 返回上一级选单"
		echo "======================================="
		read -erp "请选择操作: " choice

		case $choice in
			1)
				read -erp "查看最近多少行日志？[默认 100]: " lines
				lines=${lines:-100}
				journalctl -n "$lines" --no-pager
				read -erp "按回车继续..."
				;;
			2)
				read -erp "请输入服务名（如 sshd、nginx）: " svc
				if systemctl list-unit-files | grep -q "^$svc"; then
					journalctl -u "$svc" -n 100 --no-pager
				else
					echo "✘ 服务不存在或无日志"
				fi
				read -erp "按回车继续..."
				;;
			3)
				echo "====== 最近登录日志 ======"
				last -n 10
				echo
				echo "====== 认证日志 ======"
				if [ -f /var/log/secure ]; then
					tail -n 20 /var/log/secure
				elif [ -f /var/log/auth.log ]; then
					tail -n 20 /var/log/auth.log
				else
					echo "未找到安全日志文件"
				fi
				read -erp "按回车继续..."
				;;
			4)
				echo "1) 系统日志"
				echo "2) 指定服务日志"
				read -erp "选择跟踪类型: " t
				if [ "$t" = "1" ]; then
					journalctl -f
				elif [ "$t" = "2" ]; then
					read -erp "输入服务名: " svc
					journalctl -u "$svc" -f
				else
					echo "无效选择"
				fi
				;;
			5)
				echo "⚠️ 清理 journal 日志（安全方式）"
				echo "1) 保留最近 7 天"
				echo "2) 保留最近 3 天"
				echo "3) 限制日志最大 500M"
				read -erp "请选择清理方式: " c
				case $c in
					1) journalctl --vacuum-time=7d ;;
					2) journalctl --vacuum-time=3d ;;
					3) journalctl --vacuum-size=500M ;;
					*) echo "无效选项" ;;
				esac
				echo "✔ journal 日志清理完成"
				sleep 2
				;;
			*)
				break
				;;
		esac
	done
}



env_menu() {

	BASHRC="$HOME/.bashrc"
	PROFILE="$HOME/.profile"


	show_env_vars() {
		clear
		echo "========== 当前已生效环境变量（节选） =========="
		printf "%-20s %s\n" "变量名" "值"
		echo "-----------------------------------------------"
		for v in USER HOME SHELL LANG PWD; do
			printf "%-20s %s\n" "$v" "${!v}"
		done

		echo
		echo "PATH:"
		echo "$PATH" | tr ':' '\n' | nl -ba

		echo
		echo "========== 配置文件中定义的变量（解析） =========="

		parse_file_vars() {
			local file="$1"
			[ -f "$file" ] || return

			echo
			echo ">>> 来源文件：$file"
			echo "-----------------------------------------------"

			# 提取 export VAR=xxx 或 VAR=xxx
			grep -Ev '^\s*#|^\s*$' "$file" \
			| grep -E '^(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' \
			| while read -r line; do
				var=$(echo "$line" | sed -E 's/^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\2/')
				val=$(echo "$line" | sed -E 's/^[^=]+=//')
				printf "%-20s %s\n" "$var" "$val"
			done
		}

		parse_file_vars "$HOME/.bashrc"
		parse_file_vars "$HOME/.profile"

		echo
		echo "==============================================="
		read -erp "按回车继续..."
	}


	view_file() {
		local file="$1"
		clear
		if [ -f "$file" ]; then
			echo "========== 查看文件：$file =========="
			cat -n "$file"
			echo "===================================="
		else
			echo "文件不存在：$file"
		fi
		read -erp "按回车继续..."
	}

	edit_file() {
		local file="$1"
		install nano
		nano "$file"
	}

	source_files() {
		echo "正在重新加载环境变量..."
		source "$BASHRC"
		source "$PROFILE"
		echo "✔ 环境变量已重新加载"
		read -erp "按回车继续..."
	}

	while true; do
		clear
		echo "=========== 系统环境变量管理 =========="
		echo "当前用户：$USER"
		echo "--------------------------------------"
		echo "1. 查看当前常用环境变量"
		echo "2. 查看 ~/.bashrc"
		echo "3. 查看 ~/.profile"
		echo "4. 编辑 ~/.bashrc"
		echo "5. 编辑 ~/.profile"
		echo "6. 重新加载环境变量（source）"
		echo "--------------------------------------"
		echo "0. 返回上一级选单"
		echo "--------------------------------------"
		read -erp "请选择操作: " choice

		case "$choice" in
			1)
				show_env_vars
				;;
			2)
				view_file "$BASHRC"
				;;
			3)
				view_file "$PROFILE"
				;;
			4)
				edit_file "$BASHRC"
				;;
			5)
				edit_file "$PROFILE"
				;;
			6)
				source_files
				;;
			0)
				break
				;;
			*)
				echo "无效选项"
				sleep 1
				;;
		esac
	done
}


create_user_with_sshkey() {
	local new_username="$1"
	local is_sudo="${2:-false}"
	local sshkey_vl

	if [[ -z "$new_username" ]]; then
		echo "用法：create_user_with_sshkey <用户名>"
		return 1
	fi

	# 创建用户
	useradd -m -s /bin/bash "$new_username" || return 1

	echo "导入公钥范例："
	echo "  - URL：      ${gh_https_url}github.com/torvalds.keys"
	echo "  - 直接粘贴： ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
	read -e -p "请导入 ${new_username} 的公钥: " sshkey_vl

	case "$sshkey_vl" in
		http://*|https://*)
			fetch_remote_ssh_keys "$sshkey_vl" "/home/$new_username"
			;;
		ssh-rsa*|ssh-ed25519*|ssh-ecdsa*)
			import_sshkey "$sshkey_vl" "/home/$new_username"
			;;
		*)
			echo "错误：未知参数 '$sshkey_vl'"
			return 1
			;;
	esac


	# 修正权限
	chown -R "$new_username:$new_username" "/home/$new_username/.ssh"

	install sudo

	# sudo 免密
	if [[ "$is_sudo" == "true" ]]; then
		cat >"/etc/sudoers.d/$new_username" <<EOF
$new_username ALL=(ALL) NOPASSWD:ALL
EOF
		chmod 440 "/etc/sudoers.d/$new_username"
	fi

	sed -i '/^\s*#\?\s*UsePAM\s\+/d' /etc/ssh/sshd_config
	echo 'UsePAM yes' >> /etc/ssh/sshd_config
	passwd -l "$new_username" &>/dev/null
	restart_ssh

	echo "用户 $new_username 创建完成"
}



# ---------------------------------------------------------------------------
# TG-bot 监控预警：交互配置 + systemd/sshrc 部署
# ---------------------------------------------------------------------------
TG_NOTIFY_CONF="/etc/nimbus/tg-notify.conf"
TG_NOTIFY_MONITOR="/root/TG-check-notify.sh"
TG_NOTIFY_SSH="/usr/local/bin/tg-ssh-notify.sh"
TG_NOTIFY_UNIT="/etc/systemd/system/tg-check-notify.service"
TG_NOTIFY_SSHRC="/etc/ssh/sshrc"
TG_NOTIFY_SUDOERS="/etc/sudoers.d/nimbus-tg-ssh"
TG_NOTIFY_SUDOERS_MARK="# nimbus: 本文件由 nimbus TG-bot 监控预警创建"
# shellcheck disable=SC2016  # 写入 sshrc 的原文，$SSH_TTY 由 sshrc 运行时展开
TG_NOTIFY_SSHRC_LINE='[ -n "$SSH_TTY" ] && /usr/local/bin/tg-ssh-notify.sh </dev/null >/dev/null 2>&1 &'
TG_NOTIFY_SSHRC_MARK="# nimbus: 本文件由 nimbus TG-bot 监控预警创建"
TG_NOTIFY_CRON_LINE="@reboot nohup /bin/bash $TG_NOTIFY_MONITOR >/dev/null 2>&1 &"


# 注意：本文件顶部定义了同名的 systemctl() 包装函数（只接受两个参数），这里一律用 command systemctl
tg_notify_systemd() {
	[ -d /run/systemd/system ] && type -P systemctl >/dev/null 2>&1
}

tg_notify_mask_token() {
	local token="$1"
	if [ "${#token}" -le 8 ]; then
		echo "****"
	else
		echo "${token:0:4}****${token: -4}"
	fi
}

# 单引号包裹，供写入可被 source 的配置文件
tg_notify_quote() {
	printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

# 去掉控制字符和首尾空白
tg_notify_clean() {
	printf '%s' "$1" | tr -d '\000-\037\177' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# 调用 Telegram Bot API：Token 经 stdin 交给 curl，不出现在进程参数里
tg_notify_api() {
	local token="$1" method="$2"
	shift 2
	printf 'url = "https://api.telegram.org/bot%s/%s"\n' "$token" "$method" | curl -s -m 10 -K - "$@"
}

tg_notify_json() {
	printf '%s' "$1" | jq -r "$2" 2>/dev/null
}

tg_notify_load_config() {
	tg_cfg_loaded=false
	[ -f "$TG_NOTIFY_CONF" ] || return 1
	local TELEGRAM_BOT_TOKEN="" CHAT_ID="" isp_info="" country="" masked_ip=""
	local CPU_THRESHOLD="" MEMORY_THRESHOLD="" DISK_THRESHOLD="" NETWORK_THRESHOLD_GB=""
	local SSH_THREAD_ID="" MONITOR_THREAD_ID=""
	# shellcheck source=/dev/null
	. "$TG_NOTIFY_CONF" 2>/dev/null || return 1
	tg_old_token="$TELEGRAM_BOT_TOKEN"
	tg_old_chat="$CHAT_ID"
	tg_old_ssh_thread="$SSH_THREAD_ID"
	tg_old_mon_thread="$MONITOR_THREAD_ID"
	tg_old_isp="$isp_info"
	tg_old_country="$country"
	tg_old_masked="$masked_ip"
	tg_old_cpu="$CPU_THRESHOLD"
	tg_old_mem="$MEMORY_THRESHOLD"
	tg_old_disk="$DISK_THRESHOLD"
	tg_old_net="$NETWORK_THRESHOLD_GB"
	tg_cfg_loaded=true
}

tg_notify_show_basic() {
	echo -e "  主机名               : $(hostname 2>/dev/null || cat /proc/sys/kernel/hostname 2>/dev/null)"
	echo -e "  国家代码  country    : $2"
	echo -e "  ISP/标识  isp_info   : $1"
	[ -n "$4" ] && echo -e "  公网 IPv4            : $4"
	echo -e "  打码 IP   masked_ip  : $3"
	echo -e "  消息中的机器标识     : ${gl_huang}$1-$2-$3${gl_bai}"
}

tg_notify_probe() {
	local json org ip
	echo "正在探测本机信息..."
	json=$(curl -s -m 5 https://ipinfo.io/json 2>/dev/null)
	tg_probe_country=$(tg_notify_json "$json" '.country // empty')
	[ -n "$tg_probe_country" ] || tg_probe_country=$(nb_country)
	org=$(tg_notify_json "$json" '.org // empty')
	tg_probe_isp=$(printf '%s' "$org" | awk '{print ($2 != "" ? $2 : $1)}')
	ip=$(curl -s -m 5 https://ipv4.ip.sb 2>/dev/null | tr -d '[:space:]')
	if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
		tg_probe_ipv4="$ip"
		tg_probe_masked=$(echo "$ip" | awk -F'.' '{print "*."$3"."$4}')
	else
		tg_probe_ipv4="Unknown"
		tg_probe_masked="Unknown"
	fi
	[ -n "$tg_probe_country" ] || tg_probe_country="Unknown"
	[ -n "$tg_probe_isp" ] || tg_probe_isp="Unknown"
}

tg_notify_read_value() {
	local __var="$1" prompt="$2" value
	read -r -e -p "$prompt [${!__var}]: " value
	value=$(tg_notify_clean "$value")
	[ -n "$value" ] && printf -v "$__var" '%s' "$value"
}

# 第 1 步：机器基础信息
tg_notify_step_basic() {
	local choice confirm
	echo -e "${gl_cyan}第 1 步：机器基础信息${gl_bai}"
	echo "------------------------"
	if [ "$tg_cfg_loaded" = true ] && [ -n "$tg_old_isp" ] && [ -n "$tg_old_country" ] && [ -n "$tg_old_masked" ]; then
		echo "现有配置："
		tg_notify_show_basic "$tg_old_isp" "$tg_old_country" "$tg_old_masked"
		echo "------------------------"
		echo "1. 沿用现有信息          2. 重新探测或自定义"
		echo "0. 取消"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				tg_isp="$tg_old_isp"; tg_country="$tg_old_country"; tg_masked="$tg_old_masked"
				return 0
				;;
			2) ;;
			*) return 1 ;;
		esac
	fi

	tg_notify_probe
	while true; do
		echo "------------------------"
		echo "探测结果："
		tg_notify_show_basic "$tg_probe_isp" "$tg_probe_country" "$tg_probe_masked" "$tg_probe_ipv4"
		echo "------------------------"
		echo "1. 使用以上信息继续      2. 自定义"
		echo "0. 取消"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				tg_isp="$tg_probe_isp"; tg_country="$tg_probe_country"; tg_masked="$tg_probe_masked"
				return 0
				;;
			2)
				tg_isp="$tg_probe_isp"; tg_country="$tg_probe_country"; tg_masked="$tg_probe_masked"
				while true; do
					echo "逐项输入，直接回车保留方括号中的值"
					tg_notify_read_value tg_isp "ISP/机器标识 isp_info"
					tg_notify_read_value tg_country "国家代码 country"
					echo -e "${gl_hui}masked_ip 可填打码 IP、完整 IP 或任意文本${gl_bai}"
					tg_notify_read_value tg_masked "打码 IP masked_ip"
					echo "------------------------"
					echo "自定义结果："
					tg_notify_show_basic "$tg_isp" "$tg_country" "$tg_masked"
					read -r -e -p "确认使用以上信息？(Y/N，N 重新填写): " confirm
					case "$confirm" in
						[Yy]) return 0 ;;
						*) echo "------------------------" ;;
					esac
				done
				;;
			0) return 1 ;;
			*) echo "无效的选择，请重新输入" ;;
		esac
	done
}

tg_notify_retry() {
	local choice
	read -r -e -p "1. 重新输入    0. 放弃 : " choice
	[ "$choice" = "1" ]
}

# 第 2 步：Telegram 凭据
tg_notify_step_telegram() {
	local choice token chat resp desc bot confirm text
	echo -e "${gl_cyan}第 2 步：Telegram 凭据${gl_bai}"
	echo "------------------------"
	if [ "$tg_cfg_loaded" = true ] && [ -n "$tg_old_token" ] && [ -n "$tg_old_chat" ]; then
		echo "现有配置：Bot Token $(tg_notify_mask_token "$tg_old_token")    Chat ID $tg_old_chat"
		echo "1. 沿用现有凭据          2. 重新输入"
		echo "0. 取消"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				resp=$(tg_notify_api "$tg_old_token" getMe)
				if [ "$(tg_notify_json "$resp" '.ok')" = "true" ]; then
					echo -e "${gl_lv}Token 校验通过${gl_bai}，机器人: @$(tg_notify_json "$resp" '.result.username')"
					tg_token="$tg_old_token"; tg_chat="$tg_old_chat"
					return 0
				fi
				echo -e "${gl_hong}现有 Token 校验失败${gl_bai}，请重新输入"
				;;
			2) ;;
			*) return 1 ;;
		esac
	fi

	while true; do
		read -r -s -p "请输入 Bot Token（输入内容不显示）: " token
		echo ""
		token=$(printf '%s' "$token" | tr -d '[:space:]')
		if ! [[ "$token" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
			echo -e "${gl_hong}Token 格式不正确${gl_bai}，应形如 123456789:AAxxxx"
			tg_notify_retry || return 1
			continue
		fi
		echo "Bot Token: $(tg_notify_mask_token "$token")，正在通过 getMe 校验..."
		resp=$(tg_notify_api "$token" getMe)
		if [ "$(tg_notify_json "$resp" '.ok')" != "true" ]; then
			desc=$(tg_notify_json "$resp" '.description // empty')
			[ -n "$resp" ] || desc="无法连接 api.telegram.org"
			echo -e "${gl_hong}Token 校验失败${gl_bai}: ${desc:-未知错误}"
			tg_notify_retry || return 1
			continue
		fi
		bot=$(tg_notify_json "$resp" '.result.username')
		echo -e "${gl_lv}Token 校验通过${gl_bai}，机器人: @$bot"

		while true; do
			while true; do
				read -r -p "请输入 Chat ID: " chat
				chat=$(printf '%s' "$chat" | tr -d '[:space:]')
				[[ "$chat" =~ ^-?[0-9]+$ ]] && break
				echo -e "${gl_hong}Chat ID 格式不正确${gl_bai}，只能是数字（群组可带负号）"
			done

			text="✅ Nimbus TG-bot 测试消息
机器：${tg_isp}-${tg_country}-${tg_masked}
收到这条消息说明 Bot Token 和 Chat ID 配置正确。"
			resp=$(tg_notify_api "$token" sendMessage -X POST --data-urlencode "chat_id=$chat" --data-urlencode "text=$text")
			if [ "$(tg_notify_json "$resp" '.ok')" = "true" ]; then
				read -r -e -p "测试消息已发送，是否收到？(Y/N): " confirm
				case "$confirm" in
					[Yy])
						tg_token="$token"; tg_chat="$chat"
						return 0
						;;
				esac
				echo "请检查 Chat ID 是否对应正确的账号或群组，并确认已先给机器人发送过 /start"
			else
				desc=$(tg_notify_json "$resp" '.description // empty')
				echo -e "${gl_hong}测试消息发送失败${gl_bai}: ${desc:-未知错误}"
				echo "请确认 Chat ID 正确，并且已经先给机器人发送过 /start"
			fi
			read -r -e -p "1. 重新输入 Chat ID    2. 重新输入 Bot Token    0. 放弃 : " choice
			case "$choice" in
				1) ;;
				2) continue 2 ;;
				*) return 1 ;;
			esac
		done
	done
}

# 读取话题 ID：直接回车保留原值，输入 0 清空（不使用话题）
tg_notify_read_thread() {
	local __var="$1" prompt="$2" value
	while true; do
		read -r -e -p "$prompt [${!__var:-不使用}]: " value
		value=$(printf '%s' "$value" | tr -d '[:space:]')
		if [ -z "$value" ]; then
			return 0
		elif [ "$value" = "0" ]; then
			printf -v "$__var" '%s' ""
			return 0
		elif [[ "$value" =~ ^[0-9]{1,10}$ ]]; then
			printf -v "$__var" '%s' "$((10#$value))"
			return 0
		fi
		echo -e "${gl_hong}输入无效${gl_bai}，话题 ID 是正整数，输入 0 表示不使用话题"
	done
}

# 第 2 步补充：Chat ID 是超级群时，可把 SSH 登录提醒和资源告警分别发到不同话题（Topics）
tg_notify_step_topic() {
	local choice confirm resp desc text item label thread failed
	tg_ssh_thread="" tg_mon_thread=""
	[[ "$tg_chat" == -100* ]] || return 0
	# 仍是原来的群时沿用原话题 ID
	if [ "$tg_chat" = "$tg_old_chat" ]; then
		tg_ssh_thread="$tg_old_ssh_thread"
		tg_mon_thread="$tg_old_mon_thread"
	fi
	echo ""
	echo -e "${gl_cyan}话题设置（可选）${gl_bai}"
	echo "------------------------"
	echo "群组开启了话题（Topics）时，可以把 SSH 登录提醒和资源告警分别发到不同话题"
	echo -e "${gl_hui}话题 ID：在话题里任意消息上「复制消息链接」，t.me/c/<群>/<话题ID>/<消息ID> 中间那个数字${gl_bai}"
	echo -e "${gl_hui}直接回车保留方括号中的值，输入 0 表示不使用话题（发到 General）${gl_bai}"
	while true; do
		tg_notify_read_thread tg_ssh_thread "SSH 登录提醒的话题 ID"
		tg_notify_read_thread tg_mon_thread "资源告警的话题 ID"
		[ -n "$tg_ssh_thread$tg_mon_thread" ] || return 0
		failed=false
		for item in "SSH 登录提醒:$tg_ssh_thread" "资源告警:$tg_mon_thread"; do
			label="${item%%:*}"
			thread="${item#*:}"
			[ -n "$thread" ] || continue
			text="✅ Nimbus 话题测试：${label}
机器：${tg_isp}-${tg_country}-${tg_masked}"
			resp=$(tg_notify_api "$tg_token" sendMessage -X POST --data-urlencode "chat_id=$tg_chat" \
				--data-urlencode "message_thread_id=$thread" --data-urlencode "text=$text")
			if [ "$(tg_notify_json "$resp" '.ok')" = "true" ]; then
				echo -e "${gl_lv}已发送${gl_bai}测试消息到「${label}」话题 $thread"
			else
				desc=$(tg_notify_json "$resp" '.description // empty')
				echo -e "${gl_hong}发送到「${label}」话题 $thread 失败${gl_bai}: ${desc:-未知错误}"
				failed=true
			fi
		done
		if [ "$failed" = false ]; then
			read -r -e -p "测试消息是否出现在对应话题里？(Y/N): " confirm
			[[ "$confirm" =~ ^[Yy]$ ]] && return 0
		fi
		read -r -e -p "1. 重新输入话题 ID    2. 不使用话题    0. 放弃 : " choice
		case "$choice" in
			1) ;;
			2) tg_ssh_thread="" tg_mon_thread=""; return 0 ;;
			*) return 1 ;;
		esac
	done
}

tg_notify_read_number() {
	local __var="$1" prompt="$2" default="$3" min="$4" max="$5" value
	while true; do
		read -r -e -p "$prompt [默认 $default]: " value
		value=$(printf '%s' "${value:-$default}" | tr -d '[:space:]')
		if [[ "$value" =~ ^[0-9]{1,12}$ ]]; then
			value=$((10#$value))
			if [ "$value" -ge "$min" ] && { [ -z "$max" ] || [ "$value" -le "$max" ]; }; then
				printf -v "$__var" '%s' "$value"
				return 0
			fi
		fi
		if [ -n "$max" ]; then
			echo -e "${gl_hong}输入无效${gl_bai}，请输入 ${min}-${max} 之间的整数"
		else
			echo -e "${gl_hong}输入无效${gl_bai}，请输入不小于 ${min} 的整数"
		fi
	done
}

# 第 3 步：监控阈值
tg_notify_step_threshold() {
	echo -e "${gl_cyan}第 3 步：监控阈值${gl_bai}（直接回车使用默认值）"
	echo "------------------------"
	tg_notify_read_number tg_cpu "CPU 使用率阈值 %" "${tg_old_cpu:-70}" 1 100
	tg_notify_read_number tg_mem "内存使用率阈值 %" "${tg_old_mem:-70}" 1 100
	tg_notify_read_number tg_disk "硬盘使用率阈值 %" "${tg_old_disk:-70}" 1 100
	tg_notify_read_number tg_net "入站/出站流量阈值 GB" "${tg_old_net:-1000}" 1 ""
}

tg_notify_write_config() {
	local tmp
	mkdir -p /etc/nimbus || return 1
	chmod 755 /etc/nimbus
	tmp=$(mktemp /etc/nimbus/.tg-notify.conf.XXXXXX) || return 1
	{
		echo "# Nimbus TG-bot 监控预警配置，由 nimbus 菜单「TG-bot系统监控预警」生成"
		echo "# 权限必须保持 root:root 0600"
		echo "TELEGRAM_BOT_TOKEN=$(tg_notify_quote "$tg_token")"
		echo "CHAT_ID=$(tg_notify_quote "$tg_chat")"
		echo ""
		echo "# 机器标识：消息中显示为 isp_info-country-masked_ip"
		echo "isp_info=$(tg_notify_quote "$tg_isp")"
		echo "country=$(tg_notify_quote "$tg_country")"
		echo "masked_ip=$(tg_notify_quote "$tg_masked")"
		echo ""
		echo "# 资源监控阈值"
		echo "CPU_THRESHOLD=$tg_cpu"
		echo "MEMORY_THRESHOLD=$tg_mem"
		echo "DISK_THRESHOLD=$tg_disk"
		echo "NETWORK_THRESHOLD_GB=$tg_net"
		echo ""
		echo "# 话题群（Topics）的话题 ID，留空则发到 General 或私聊"
		echo "SSH_THREAD_ID=$tg_ssh_thread"
		echo "MONITOR_THREAD_ID=$tg_mon_thread"
	} > "$tmp" || { rm -f "$tmp"; return 1; }
	chown root:root "$tmp" && chmod 600 "$tmp" && mv -f "$tmp" "$TG_NOTIFY_CONF"
}

tg_notify_fetch() {
	local name="$1" dest="$2" url tmp
	url="raw.githubusercontent.com/zidou-kiyn/nimbus/main/${name}"
	mkdir -p "$(dirname "$dest")" || return 1
	tmp=$(mktemp "${dest}.XXXXXX") || return 1
	if nb_download "$url" "$tmp" && head -1 "$tmp" | grep -q '^#!/bin/bash'; then
		chown root:root "$tmp" && chmod 755 "$tmp" && mv -f "$tmp" "$dest"
	else
		rm -f "$tmp"
		echo -e "${gl_hong}下载失败${gl_bai}: $url"
		return 1
	fi
}

# 结束非 systemd 方式启动的监控进程（不依赖 pkill）
tg_notify_kill_monitor() {
	local proc cmd
	for proc in /proc/[0-9]*; do
		cmd=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null)
		case "$cmd" in
			"/bin/bash $TG_NOTIFY_MONITOR"*|"bash $TG_NOTIFY_MONITOR"*) kill "${proc#/proc/}" 2>/dev/null ;;
		esac
	done
}

# 删除 root crontab 中所有含 TG-check-notify.sh 的 @reboot 行；删除了任何行返回 0。
# 若删除的行中有不同于当前 nohup 回退格式的（即旧版 tmux 行），置 tg_cron_legacy=true
tg_notify_crontab_clean() {
	local cur lines
	tg_cron_legacy=false
	command -v crontab >/dev/null 2>&1 || return 1
	cur=$(crontab -l 2>/dev/null)
	lines=$(printf '%s\n' "$cur" | grep '^@reboot.*TG-check-notify\.sh')
	[ -n "$lines" ] || return 1
	printf '%s\n' "$cur" | grep -v '^@reboot.*TG-check-notify\.sh' | crontab -
	printf '%s\n' "$lines" | grep -qvxF "$TG_NOTIFY_CRON_LINE" && tg_cron_legacy=true
	return 0
}

# 清理 tmux + crontab + ~/.profile 方式的旧部署（幂等）
tg_notify_migrate_legacy() {
	local home profile bashrc had_profile_line
	if command -v tmux >/dev/null 2>&1 && tmux has-session -t TG-check-notify 2>/dev/null; then
		tmux kill-session -t TG-check-notify 2>/dev/null && echo "已停止旧的 tmux 会话 TG-check-notify"
	fi
	if tg_notify_crontab_clean && { [ "$tg_cron_legacy" = true ] || tg_notify_systemd; }; then
		echo "已移除 crontab 中旧的 @reboot 自启行"
	fi

	for home in "$HOME" /root; do
		[ -d "$home" ] || continue
		profile="$home/.profile"
		bashrc="$home/.bashrc"
		had_profile_line=false
		if [ -f "$profile" ] && grep -qxF 'bash ~/TG-SSH-check-notify.sh' "$profile"; then
			had_profile_line=true
			sed -i '\#^bash ~/TG-SSH-check-notify\.sh$#d' "$profile"
			echo "已从 $profile 移除旧的 SSH 登录提醒"
		fi
		# 旧逻辑在 dnf/yum 系统上会往 ~/.bashrc 追加 source ~/.profile。
		# 仅当 ~/.profile 原本只有那一行旧内容（移除后已无有效内容）时，才认定这行是旧逻辑加的。
		if [ "$had_profile_line" = true ] && [ -f "$bashrc" ] && grep -qxF 'source ~/.profile' "$bashrc"; then
			if ! grep -qvE '^[[:space:]]*(#.*)?$' "$profile"; then
				local last
				last=$(grep -nxF 'source ~/.profile' "$bashrc" | tail -1 | cut -d: -f1)
				sed -i "${last}d" "$bashrc"
				echo "已从 $bashrc 移除旧逻辑添加的 source ~/.profile"
				# ~/.profile 是旧逻辑新建的且已无内容，一并删除
				[ -s "$profile" ] || rm -f "$profile"
			else
				echo -e "${gl_hui}提示: $bashrc 中的 source ~/.profile 可能是旧版添加的，如不需要可手动删除${gl_bai}"
			fi
		fi
		if [ -f "$home/TG-SSH-check-notify.sh" ]; then
			rm -f "$home/TG-SSH-check-notify.sh" && echo "已删除旧脚本 $home/TG-SSH-check-notify.sh"
		fi
	done
}

tg_notify_sshrc_install() {
	local created=false x11
	if [ ! -e "$TG_NOTIFY_SSHRC" ]; then
		created=true
		mkdir -p "$(dirname "$TG_NOTIFY_SSHRC")"
		echo "$TG_NOTIFY_SSHRC_MARK" > "$TG_NOTIFY_SSHRC"
		chmod 644 "$TG_NOTIFY_SSHRC"
		x11=$(sshd -T 2>/dev/null | awk 'tolower($1)=="x11forwarding" {print tolower($2)}')
		[ -n "$x11" ] || x11=$(awk 'tolower($1)=="x11forwarding" {print tolower($2); exit}' /etc/ssh/sshd_config 2>/dev/null)
		if [ "$x11" = "yes" ]; then
			# /etc/ssh/sshrc 存在时 sshd 不再自动执行 xauth，按 man sshd (SSHRC) 补上标准片段
			cat >> "$TG_NOTIFY_SSHRC" <<'XAUTH'
# >>> nimbus xauth (man sshd: SSHRC) >>>
if read proto cookie && [ -n "$DISPLAY" ]; then
	if [ `echo $DISPLAY | cut -c1-10` = 'localhost:' ]; then
		# X11UseLocalhost=yes
		echo add unix:`echo $DISPLAY |
		    cut -c11-` $proto $cookie
	else
		# X11UseLocalhost=no
		echo add $DISPLAY $proto $cookie
	fi | xauth -q -
fi
# <<< nimbus xauth <<<
XAUTH
			echo -e "${gl_huang}提示:${gl_bai} sshd 已开启 X11Forwarding，已在新建的 $TG_NOTIFY_SSHRC 中写入标准 xauth 片段"
		fi
	fi
	if grep -qxF "$TG_NOTIFY_SSHRC_LINE" "$TG_NOTIFY_SSHRC"; then
		:
	elif grep -qF "$TG_NOTIFY_SSH" "$TG_NOTIFY_SSHRC"; then
		local tmp
		tmp=$(mktemp) || return 1
		awk -v path="$TG_NOTIFY_SSH" -v line="$TG_NOTIFY_SSHRC_LINE" 'index($0, path) { if (!done) print line; done=1; next } { print }' "$TG_NOTIFY_SSHRC" > "$tmp" &&
			cat "$tmp" > "$TG_NOTIFY_SSHRC"
		rm -f "$tmp"
	else
		[ -s "$TG_NOTIFY_SSHRC" ] && [ -n "$(tail -c 1 "$TG_NOTIFY_SSHRC")" ] && echo "" >> "$TG_NOTIFY_SSHRC"
		echo "$TG_NOTIFY_SSHRC_LINE" >> "$TG_NOTIFY_SSHRC"
	fi
	[ "$created" = true ] && echo "已新建 $TG_NOTIFY_SSHRC"
	return 0
}

# 非 root 用户登录时，sshrc 以登录用户身份运行提醒脚本，读不到 0600 的配置文件；
# 这条 sudoers 规则只允许免密以 root 运行这一个脚本，由脚本自己切换（sudo -n），配置文件仍只有 root 可读
tg_notify_sudoers_install() {
	local tmp
	if ! type -P sudo >/dev/null 2>&1 || [ ! -d /etc/sudoers.d ]; then
		echo -e "${gl_huang}提示:${gl_bai} 未安装 sudo，SSH 登录提醒仅对 root 登录生效"
		return 1
	fi
	tmp=$(mktemp) || return 1
	cat > "$tmp" <<SUDOERS
$TG_NOTIFY_SUDOERS_MARK
# 允许任意用户免密以 root 运行 SSH 登录提醒脚本（读取仅 root 可读的配置文件），不授予其他权限
ALL ALL=(root) NOPASSWD: $TG_NOTIFY_SSH
Defaults!$TG_NOTIFY_SSH !requiretty
SUDOERS
	if ! visudo -cqf "$tmp" >/dev/null 2>&1; then
		rm -f "$tmp"
		echo -e "${gl_hong}sudoers 规则校验失败${gl_bai}，SSH 登录提醒仅对 root 登录生效"
		return 1
	fi
	chown root:root "$tmp" && chmod 440 "$tmp" && mv -f "$tmp" "$TG_NOTIFY_SUDOERS"
	if ! grep -qE '^[@#]includedir[[:space:]]+/etc/sudoers.d' /etc/sudoers 2>/dev/null; then
		echo -e "${gl_huang}提示:${gl_bai} /etc/sudoers 未包含 /etc/sudoers.d，非 root 用户登录不会提醒"
	fi
}

tg_notify_sudoers_remove() {
	[ -f "$TG_NOTIFY_SUDOERS" ] || return 0
	head -1 "$TG_NOTIFY_SUDOERS" | grep -qxF "$TG_NOTIFY_SUDOERS_MARK" && rm -f "$TG_NOTIFY_SUDOERS" && echo "已删除 $TG_NOTIFY_SUDOERS"
}

tg_notify_sshrc_remove() {
	[ -f "$TG_NOTIFY_SSHRC" ] || return 0
	local tmp
	tmp=$(mktemp) || return 1
	if grep -qF "$TG_NOTIFY_SSH" "$TG_NOTIFY_SSHRC"; then
		grep -vF "$TG_NOTIFY_SSH" "$TG_NOTIFY_SSHRC" > "$tmp"
		cat "$tmp" > "$TG_NOTIFY_SSHRC"
		echo "已移除 $TG_NOTIFY_SSHRC 中的登录提醒"
	fi
	if head -1 "$TG_NOTIFY_SSHRC" | grep -qxF "$TG_NOTIFY_SSHRC_MARK"; then
		# 由 nimbus 新建：去掉标记和 xauth 片段后若已无其他内容，删除文件以恢复 sshd 默认的 xauth 行为
		sed '1d; /^# >>> nimbus xauth/,/^# <<< nimbus xauth <<<$/d' "$TG_NOTIFY_SSHRC" > "$tmp"
		if ! grep -qvE '^[[:space:]]*$' "$tmp"; then
			rm -f "$TG_NOTIFY_SSHRC"
			echo "已删除由 nimbus 创建的 $TG_NOTIFY_SSHRC"
		fi
	fi
	rm -f "$tmp"
}

tg_notify_write_unit() {
	local tmp
	tmp=$(mktemp) || return 1
	cat > "$tmp" <<'UNIT'
[Unit]
Description=TG-check-notify - CPU/内存/磁盘/流量阈值 Telegram 告警
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash /root/TG-check-notify.sh
WorkingDirectory=/root
Environment=HOME=/root LC_ALL=C
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tg-check-notify

[Install]
WantedBy=multi-user.target
UNIT
	if cmp -s "$tmp" "$TG_NOTIFY_UNIT"; then
		rm -f "$tmp"
	else
		chmod 644 "$tmp" && mv -f "$tmp" "$TG_NOTIFY_UNIT"
	fi
}

tg_notify_start_monitor() {
	if tg_notify_systemd; then
		tg_notify_write_unit || return 1
		command systemctl daemon-reload
		if command systemctl is-active --quiet tg-check-notify.service; then
			command systemctl enable tg-check-notify.service >/dev/null 2>&1
			command systemctl restart tg-check-notify.service
		else
			command systemctl enable --now tg-check-notify.service
		fi
	else
		echo -e "${gl_huang}提示:${gl_bai} 未检测到 systemd，改用 crontab @reboot 方式开机自启"
		check_crontab_installed
		tg_notify_crontab_clean
		(crontab -l 2>/dev/null; echo "$TG_NOTIFY_CRON_LINE") | crontab -
		tg_notify_kill_monitor
		nohup /bin/bash "$TG_NOTIFY_MONITOR" >/dev/null 2>&1 &
	fi
}

tg_notify_monitor_status() {
	local proc
	if tg_notify_systemd; then
		command systemctl is-active tg-check-notify.service 2>/dev/null
		return
	fi
	for proc in /proc/[0-9]*; do
		case "$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null)" in
			"/bin/bash $TG_NOTIFY_MONITOR"*) echo "running (pid ${proc#/proc/}, crontab @reboot)"; return ;;
		esac
	done
	echo "inactive"
}

tg_notify_show_result() {
	echo "------------------------"
	echo -e "资源监控 tg-check-notify : ${gl_huang}$(tg_notify_monitor_status)${gl_bai}"
	if grep -qxF "$TG_NOTIFY_SSHRC_LINE" "$TG_NOTIFY_SSHRC" 2>/dev/null; then
		echo -e "SSH 登录提醒 sshrc       : ${gl_lv}已挂载${gl_bai} ($TG_NOTIFY_SSHRC 第 $(grep -nxF "$TG_NOTIFY_SSHRC_LINE" "$TG_NOTIFY_SSHRC" | cut -d: -f1) 行)"
	else
		echo -e "SSH 登录提醒 sshrc       : ${gl_hong}未挂载${gl_bai}"
	fi
	if [ -f "$TG_NOTIFY_SUDOERS" ]; then
		echo -e "非 root 登录提醒 sudoers : ${gl_lv}已启用${gl_bai} ($TG_NOTIFY_SUDOERS)"
	else
		echo -e "非 root 登录提醒 sudoers : ${gl_hui}未启用，仅 root 登录会提醒${gl_bai}"
	fi
	echo "配置文件                 : $TG_NOTIFY_CONF ($(stat -c '%a %U:%G' "$TG_NOTIFY_CONF" 2>/dev/null))"
}

tg_notify_install() {
	local confirm
	install curl bc jq
	tg_old_token="" tg_old_chat="" tg_old_isp="" tg_old_country="" tg_old_masked=""
	tg_old_cpu="" tg_old_mem="" tg_old_disk="" tg_old_net="" tg_old_ssh_thread="" tg_old_mon_thread=""
	tg_token="" tg_chat="" tg_isp="" tg_country="" tg_masked="" tg_ssh_thread="" tg_mon_thread=""
	tg_cpu="" tg_mem="" tg_disk="" tg_net=""
	tg_notify_load_config
	if [ -f "$TG_NOTIFY_CONF" ] && [ "$tg_cfg_loaded" != true ]; then
		echo -e "${gl_huang}提示:${gl_bai} 现有配置文件无法读取，将重新配置"
	fi

	echo ""
	tg_notify_step_basic || { echo "已取消"; return 1; }
	echo ""
	tg_notify_step_telegram || { echo "已取消"; return 1; }
	tg_notify_step_topic || { echo "已取消"; return 1; }
	echo ""
	tg_notify_step_threshold

	echo ""
	echo -e "${gl_cyan}第 4 步：确认配置${gl_bai}"
	echo "------------------------"
	echo "Bot Token   : $(tg_notify_mask_token "$tg_token")"
	echo "Chat ID     : $tg_chat"
	if [[ "$tg_chat" == -100* ]]; then
		echo "话题 ID     : SSH 登录提醒 ${tg_ssh_thread:-不使用}，资源告警 ${tg_mon_thread:-不使用}"
	fi
	echo -e "机器标识    : ${gl_huang}${tg_isp}-${tg_country}-${tg_masked}${gl_bai}"
	echo "CPU 阈值    : ${tg_cpu}%"
	echo "内存阈值    : ${tg_mem}%"
	echo "硬盘阈值    : ${tg_disk}%"
	echo "流量阈值    : ${tg_net}GB（入站、出站分别计算）"
	echo "------------------------"
	read -r -e -p "确认写入配置并部署？(Y/N): " confirm
	case "$confirm" in
		[Yy]) ;;
		*) echo "已取消，未做任何修改"; return 1 ;;
	esac

	tg_notify_migrate_legacy
	tg_notify_write_config || { echo -e "${gl_hong}配置写入失败${gl_bai}"; return 1; }
	echo "已写入配置 $TG_NOTIFY_CONF"
	tg_notify_fetch TG-check-notify.sh "$TG_NOTIFY_MONITOR" || return 1
	tg_notify_fetch TG-SSH-check-notify.sh "$TG_NOTIFY_SSH" || return 1
	echo "已部署 $TG_NOTIFY_MONITOR 和 $TG_NOTIFY_SSH"
	tg_notify_sshrc_install
	tg_notify_sudoers_install
	tg_notify_start_monitor

	echo ""
	echo -e "${gl_lv}TG-bot 监控预警已部署${gl_bai}"
	tg_notify_show_result
	echo -e "${gl_hui}-关于流量，重启服务器将重新计算-${gl_bai}"
	echo -e "${gl_hui}SSH 登录提醒只在交互式登录时发送；sudo -i、tmux 和 scp/sftp 等无终端连接不会触发${gl_bai}"
	echo -e "${gl_hui}其他机器请直接运行本菜单重新配置；若要复制部署，需同时带上 $TG_NOTIFY_CONF 并修改机器标识${gl_bai}"
}

tg_notify_uninstall() {
	local confirm
	echo "将停用并删除 TG-bot 监控预警的服务、sshrc 挂载、sudoers 规则、脚本和配置文件"
	read -r -e -p "确定继续吗？(Y/N): " confirm
	case "$confirm" in
		[Yy]) ;;
		*) echo "已取消"; return 1 ;;
	esac
	if type -P systemctl >/dev/null 2>&1 && [ -f "$TG_NOTIFY_UNIT" ]; then
		command systemctl disable --now tg-check-notify.service >/dev/null 2>&1
		rm -f "$TG_NOTIFY_UNIT"
		tg_notify_systemd && command systemctl daemon-reload
		echo "已停用并删除 tg-check-notify.service"
	fi
	tg_notify_crontab_clean
	tg_notify_kill_monitor
	tg_notify_migrate_legacy
	tg_notify_sshrc_remove
	tg_notify_sudoers_remove
	rm -f "$TG_NOTIFY_MONITOR" "$TG_NOTIFY_SSH" "$TG_NOTIFY_CONF"
	rmdir /etc/nimbus 2>/dev/null
	echo -e "${gl_lv}TG-bot 监控预警已卸载${gl_bai}"
}

tg_notify_menu() {
	local choice
	while true; do
		clear
		echo "TG-bot监控预警"
		echo "------------------------------------------------"
		echo "配置 Telegram 机器人后，本机 CPU、内存、硬盘、流量超过阈值，或有 SSH 登录时，会向你推送通知"
		echo "支持发到开启话题（Topics）的群组，SSH 登录提醒和资源告警可分别发到不同话题"
		echo -e "${gl_hui}-关于流量，重启服务器将重新计算-${gl_bai}"
		if [ -f "$TG_NOTIFY_CONF" ]; then
			echo -e "当前状态: 已配置，资源监控 ${gl_huang}$(tg_notify_monitor_status)${gl_bai}"
		else
			echo -e "当前状态: ${gl_hui}未配置${gl_bai}"
		fi
		echo "------------------------------------------------"
		echo "1. 安装 / 重新配置          2. 卸载"
		echo "------------------------------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------------------------------"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1) tg_notify_install; break_end ;;
			2) tg_notify_uninstall; break_end ;;
			*) break ;;
		esac
	done
}

# ---------------------------------------------------------------------------
# 通用：下载 GitHub 资源（依次尝试 gh_proxy / 直连 / 镜像），参数为不带协议的路径
# ---------------------------------------------------------------------------
nb_download() {
	local path="$1" dest="$2" url urls cnb="" tried=" "
	local own="raw.githubusercontent.com/zidou-kiyn/nimbus/main/"
	# 本仓库的文件可以从国内镜像 cnb.cool 下载；本次运行中 GitHub 已确认连不上时直接用镜像，不再逐个等超时
	case "$path" in "$own"*) cnb="${nb_cnb_raw}${path#"$own"}" ;; esac
	if [ -n "$cnb" ] && [ "$NB_GH_DEAD" = 1 ]; then
		urls="$cnb"
	else
		urls="${gh_proxy}${path} https://${path} ${gh_proxy_mirror}https://${path} $cnb"
	fi
	for url in $urls; do
		case "$tried" in *" $url "*) continue ;; esac
		tried="$tried$url "
		if curl -fsSL --connect-timeout 8 -m 120 -o "$dest" "$url" 2>/dev/null && [ -s "$dest" ]; then
			[ "$url" = "$cnb" ] && NB_GH_DEAD=1
			return 0
		fi
	done
	rm -f "$dest"
	return 1
}

# 本机 IP 所在国家代码（如 CN、US），查不到时输出为空
# 先查 ipinfo.io；连不上（如无国际出口的国内机器）时用 Cloudflare 国内节点的 trace 接口（qualcomm.cn，国内外都能访问）
nb_country() {
	local c
	c=$(curl -s --connect-timeout 3 -m 5 ipinfo.io/country 2>/dev/null | tr -d '[:space:]')
	if ! [[ "$c" =~ ^[A-Z]{2}$ ]]; then
		c=$(curl -s --connect-timeout 3 -m 5 http://www.qualcomm.cn/cdn-cgi/trace 2>/dev/null | sed -n 's/^loc=//p' | tr -d '[:space:]')
	fi
	[[ "$c" =~ ^[A-Z]{2}$ ]] && echo "$c"
}

# 是否为国内服务器（CN 模式或 IP 归属地为 CN）
nb_in_cn() {
	[ "$canshu" = "CN" ] && return 0
	[ "$(nb_country)" = "CN" ]
}

nb_service_active() {
	command systemctl is-active --quiet "$1" 2>/dev/null && return 0
	command -v rc-service >/dev/null 2>&1 && rc-service "$1" status >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# tmux 及 Nimbus 推荐配置
# ---------------------------------------------------------------------------
tmux_setup() {
	local conf="$HOME/.tmux.conf" tmp ver major minor choice bak
	clear
	echo "tmux 及推荐配置"
	echo "------------------------------------------------"
	echo "安装 tmux，并写入 Nimbus 推荐配置（鼠标、vi 复制模式、5 万行历史、OSC 52 剪贴板、Alt+拖动复制、prefix+m 开关鼠标等）"
	echo -e "${gl_hui}配置来源: res/config/tmux/tmux.conf${gl_bai}"
	echo "------------------------------------------------"
	install tmux || return 1
	tmp=$(mktemp) || return 1
	if ! nb_download raw.githubusercontent.com/zidou-kiyn/nimbus/main/res/config/tmux/tmux.conf "$tmp" || ! grep -q 'set -g mouse' "$tmp"; then
		rm -f "$tmp"
		echo -e "${gl_hong}配置文件下载失败${gl_bai}"
		return 1
	fi

	ver=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
	major=${ver%%.*}; minor=${ver#*.}
	if [ -n "$ver" ] && { [ "${major:-0}" -lt 3 ] || { [ "$major" -eq 3 ] && [ "${minor:-0}" -lt 5 ]; }; }; then
		sed -i '/extended-keys-format/d' "$tmp"
		echo -e "${gl_hui}tmux $ver < 3.5，已去掉 extended-keys-format 选项${gl_bai}"
	fi

	if [ -f "$conf" ]; then
		if cmp -s "$tmp" "$conf"; then
			rm -f "$tmp"
			echo -e "${gl_lv}tmux 配置已是最新，无需修改${gl_bai}"
			return 0
		fi
		echo -e "${gl_huang}已存在 $conf，与推荐配置的差异如下（- 现有 / + 推荐）:${gl_bai}"
		diff -u "$conf" "$tmp" | sed -n '3,200p' | grep -E '^[-+]' | head -40
		echo "------------------------"
		read -r -e -p "备份现有配置并替换吗？(Y/N): " choice
		case "$choice" in
			[Yy]) ;;
			*) rm -f "$tmp"; echo "已取消，未修改"; return 0 ;;
		esac
		bak="$conf.bak.$(date +%Y%m%d-%H%M%S)"
		cp -f "$conf" "$bak"
		echo "已备份到 $bak"
	fi
	mv -f "$tmp" "$conf"
	chmod 644 "$conf"
	echo -e "${gl_lv}已写入 $conf${gl_bai}"
	if tmux ls >/dev/null 2>&1; then
		tmux source-file "$conf" && echo "已重新加载正在运行的 tmux"
	fi
}

# ---------------------------------------------------------------------------
# ble.sh 命令行增强（语法高亮、自动建议）及 Nimbus 推荐配置，装在当前用户下
# ---------------------------------------------------------------------------
NB_BLESH_DIR="$HOME/.local/share/blesh"

nb_blesh_version() {
	grep -a -m1 -oE '_ble_init_version=[^ ;]+' "$NB_BLESH_DIR/ble.sh" 2>/dev/null | cut -d= -f2
}

# 下载 nightly 包，安装或覆盖到 ~/.local/share/blesh（国内走代理，不依赖 git / make）
nb_blesh_install() {
	local tmp src old
	if ! command -v xz >/dev/null 2>&1; then
		if command -v apt >/dev/null 2>&1; then install xz-utils; else install xz; fi
	fi
	command -v awk >/dev/null 2>&1 || install gawk
	old=$(nb_blesh_version)
	tmp=$(mktemp -d) || return 1
	echo "正在下载 ble.sh（nightly）..."
	if ! nb_download github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz "$tmp/ble.tar.xz" ||
		! tar -xJf "$tmp/ble.tar.xz" -C "$tmp" 2>/dev/null; then
		rm -rf "$tmp"
		echo -e "${gl_hong}ble.sh 下载或解压失败${gl_bai}"
		return 1
	fi
	src=$(ls -d "$tmp"/ble-nightly*/ 2>/dev/null | head -n 1)
	if [ -z "$src" ] || ! bash "${src}ble.sh" --install "$HOME/.local/share" >"$tmp/install.log" 2>&1 || [ ! -f "$NB_BLESH_DIR/ble.sh" ]; then
		tail -n 5 "$tmp/install.log" 2>/dev/null
		rm -rf "$tmp"
		echo -e "${gl_hong}ble.sh 安装失败${gl_bai}"
		return 1
	fi
	rm -rf "$tmp"
	if [ -n "$old" ] && [ "$old" != "$(nb_blesh_version)" ]; then
		echo -e "${gl_lv}ble.sh 已更新: $old → $(nb_blesh_version)${gl_bai}"
	else
		echo -e "${gl_lv}ble.sh $(nb_blesh_version) 已安装到 $NB_BLESH_DIR${gl_bai}"
	fi
}

# 在 ~/.bashrc 首尾写入加载块（官方推荐写法：开头 --attach=none，结尾 ble-attach）
# 手动添加过的 source ble.sh / ble-attach 行会被注释掉，避免重复加载
nb_blesh_bashrc() {
	local rc="$HOME/.bashrc" tmp
	[ -f "$rc" ] || touch "$rc"
	nb_ps1_migrate
	tmp=$(mktemp) || return 1
	{
		echo '# >>> nimbus ble.sh >>>'
		echo '[[ $- == *i* && -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh --attach=none'
		echo '# <<< nimbus ble.sh <<<'
		awk '
			/^# >>> nimbus ble\.sh/ { skip = 1; next }
			/^# <<< nimbus ble\.sh/ { skip = 0; next }
			skip { next }
			/^[^#]*(source|\.)[ \t]+[^#]*blesh\/ble\.sh/ || /^[^#]*ble-attach/ { print "# [nimbus] " $0; next }
			{ print }
		' "$rc"
		echo '# >>> nimbus ble.sh attach >>>'
		echo '[[ ! ${BLE_VERSION-} ]] || ble-attach'
		echo '# <<< nimbus ble.sh attach <<<'
	} > "$tmp" || { rm -f "$tmp"; return 1; }
	if cmp -s "$tmp" "$rc"; then
		rm -f "$tmp"
		echo -e "${gl_lv}~/.bashrc 已启用 ble.sh，无需修改${gl_bai}"
		return 0
	fi
	cp -f "$rc" "$rc.bak.$(date +%Y%m%d-%H%M%S)"
	cat "$tmp" > "$rc"
	rm -f "$tmp"
	echo -e "${gl_lv}已在 ~/.bashrc 启用 ble.sh（原文件已备份为 .bashrc.bak.*）${gl_bai}"
}

# 清理 ~/.profile 里的 PS1：删掉 nimbus 配置块；其余 PS1= 行（含手写在 if 里缩进的）改成 `: # [nimbus 已停用] …`
# 空操作，不直接删，避免 if 体变空导致语法错误
nb_ps1_profile_clean() {
	local p="$HOME/.profile"
	[ -f "$p" ] || return 0
	sed -i -E -e '/^# >>> nimbus PS1 >>>$/,/^# <<< nimbus PS1 <<<$/d' \
		-e 's/^([[:space:]]*)(PS1=.*)$/\1: # [nimbus 已停用] \2/' "$p"
}

# 已在 ~/.profile 设置的 PS1（Nimbus 配置块或其他 PS1= 行）挪到 ~/.bashrc：
# ble.sh 在 .bashrc 末尾 attach，登录时 .profile 之后再设的 PS1 会被它还原成 .bashrc 里的默认值
nb_ps1_migrate() {
	local p="$HOME/.profile" blk line
	[ -f "$p" ] && [ "$(nb_ps1_rc)" = "$HOME/.bashrc" ] || return 0
	blk=$(sed -n '/^# >>> nimbus PS1 >>>$/,/^# <<< nimbus PS1 <<<$/p' "$p")
	if [ -z "$blk" ]; then
		line=$(grep -E '^[[:space:]]*PS1=' "$p" | tail -n 1 | sed -E 's/^[[:space:]]+//')
		[ -n "$line" ] || return 0
		# shellcheck disable=SC2016  # 有意写入字面量 $BASH
		blk=$(printf '# >>> nimbus PS1 >>>\nif [ -n "$BASH" ]; then\n\t%s\nfi\n# <<< nimbus PS1 <<<' "$line")
	fi
	sed -i '/^# >>> nimbus PS1 >>>$/,/^# <<< nimbus PS1 <<<$/d' "$HOME/.bashrc"
	printf '%s\n' "$blk" | nb_ps1_insert "$HOME/.bashrc"
	nb_ps1_profile_clean
	echo "已将命令行美化（PS1）从 ~/.profile 移到 ~/.bashrc，避免被 ble.sh 覆盖"
}

nb_blesh_unbashrc() {
	local rc="$HOME/.bashrc" tmp
	grep -qs '^# >>> nimbus ble\.sh' "$rc" || return 0
	tmp=$(mktemp) || return 1
	awk '/^# >>> nimbus ble\.sh/ { skip = 1; next } /^# <<< nimbus ble\.sh/ { skip = 0; next } !skip' "$rc" > "$tmp" && cat "$tmp" > "$rc"
	rm -f "$tmp"
	echo "已从 ~/.bashrc 移除 ble.sh 加载块"
}

# 写入 Nimbus 推荐配置 ~/.blerc（与 tmux 一样，已有不同配置时先展示差异再确认）
nb_blesh_conf() {
	local conf="$HOME/.blerc" tmp choice bak
	tmp=$(mktemp) || return 1
	if ! nb_download raw.githubusercontent.com/zidou-kiyn/nimbus/main/res/config/blesh/blerc "$tmp" || ! grep -q 'Nimbus ble.sh' "$tmp"; then
		rm -f "$tmp"
		echo -e "${gl_hong}配置文件下载失败${gl_bai}"
		return 1
	fi
	if [ -f "$conf" ]; then
		if cmp -s "$tmp" "$conf"; then
			rm -f "$tmp"
			echo -e "${gl_lv}ble.sh 配置已是最新，无需修改${gl_bai}"
			return 0
		fi
		echo -e "${gl_huang}已存在 $conf，与推荐配置的差异如下（- 现有 / + 推荐）:${gl_bai}"
		diff -u "$conf" "$tmp" | sed -n '3,200p' | grep -E '^[-+]' | head -40
		echo "------------------------"
		read -r -e -p "备份现有配置并替换吗？(Y/N): " choice
		case "$choice" in
			[Yy]) ;;
			*) rm -f "$tmp"; echo "已取消，保留现有配置"; return 0 ;;
		esac
		bak="$conf.bak.$(date +%Y%m%d-%H%M%S)"
		cp -f "$conf" "$bak"
		echo "已备份到 $bak"
	fi
	mv -f "$tmp" "$conf"
	chmod 644 "$conf"
	echo -e "${gl_lv}已写入 $conf${gl_bai}"
}

nb_blesh_uninstall() {
	local choice
	read -r -e -p "确定卸载 ble.sh 并移除 ~/.bashrc 中的加载块吗？(Y/N): " choice
	case "$choice" in [Yy]) ;; *) echo "已取消"; return 0 ;; esac
	nb_blesh_unbashrc
	rm -rf "$NB_BLESH_DIR" "$HOME/.local/share/doc/blesh" "$HOME/.cache/blesh" "${XDG_STATE_HOME:-$HOME/.local/state}/blesh"
	grep -qs 'Nimbus ble.sh' "$HOME/.blerc" && rm -f "$HOME/.blerc"
	echo -e "${gl_lv}ble.sh 已卸载，重新登录后生效${gl_bai}"
}

blesh_setup() {
	local choice ver sh
	while true; do
		clear
		echo "ble.sh 命令行增强"
		echo "------------------------------------------------"
		echo "为 bash 提供语法高亮、灰色自动建议（类似 fish）、增强补全，并写入 Nimbus 推荐快捷键:"
		echo "  回车=执行（命令没写完时换行）  Ctrl+J=换行  Shift+Tab / →=接受建议  Ctrl+H=删前一个词"
		echo -e "${gl_hui}项目: github.com/akinomyoga/ble.sh · 配置来源: res/config/blesh/blerc · 安装位置: ~/.local/share/blesh${gl_bai}"
		echo "------------------------------------------------"
		ver=$(nb_blesh_version)
		if [ -z "$ver" ]; then
			echo -e "当前状态: ${gl_hui}未安装${gl_bai}"
		elif grep -qs 'blesh/ble\.sh' "$HOME/.bashrc"; then
			echo -e "当前状态: ${gl_lv}已启用${gl_bai} $ver"
		else
			echo -e "当前状态: ${gl_huang}已安装，未在 ~/.bashrc 启用${gl_bai} $ver"
		fi
		if [ -n "$ver" ]; then
			grep -qs 'Nimbus ble.sh' "$HOME/.blerc" && echo "快捷键  : Nimbus 推荐配置" || echo -e "快捷键  : ${gl_hui}$( [ -f "$HOME/.blerc" ] && echo '自定义 ~/.blerc' || echo '默认')${gl_bai}"
		fi
		sh=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)
		case "$sh" in */bash|"") ;; *) echo -e "${gl_huang}当前用户的登录 shell 是 $sh，ble.sh 只在 bash 中生效${gl_bai}" ;; esac
		echo "------------------------------------------------"
		echo "1. 安装 / 更新并写入推荐配置    2. 仅更新 ble.sh"
		echo "3. 卸载"
		echo "------------------------------------------------"
		echo "0. 返回"
		echo "------------------------------------------------"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				nb_blesh_install && nb_blesh_bashrc && nb_blesh_conf &&
					echo -e "${gl_huang}重新登录或执行 exec bash 后生效${gl_bai}"
				break_end ;;
			2)
				if [ -z "$(nb_blesh_version)" ]; then echo "尚未安装，请选 1"; else nb_blesh_install && echo -e "${gl_huang}新开的终端生效${gl_bai}"; fi
				break_end ;;
			3) nb_blesh_uninstall; break_end ;;
			*) break ;;
		esac
	done
}

# ---------------------------------------------------------------------------
# Komari 探针 Agent
# ---------------------------------------------------------------------------
komari_agent_menu() {
	root_use
	local choice endpoint key rotate use_mirror mirror tmp
	local -a args
	while true; do
		clear
		echo "Komari 探针 Agent"
		echo "------------------------------------------------"
		if nb_service_active komari-agent; then
			echo -e "当前状态: ${gl_lv}运行中${gl_bai}"
		elif [ -x /opt/komari/agent ]; then
			echo -e "当前状态: ${gl_huang}已安装，未运行${gl_bai}"
		else
			echo -e "当前状态: ${gl_hui}未安装${gl_bai}"
		fi
		echo -e "${gl_hui}项目地址: https://github.com/komari-monitor/komari-agent${gl_bai}"
		echo "------------------------------------------------"
		echo "1. 安装 / 重新安装             2. 卸载"
		echo "------------------------------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------------------------------"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				while true; do
					read -r -e -p "探针网址（如 https://komari.example.com）: " endpoint
					[[ "$endpoint" =~ ^https?://[^[:space:]]+$ ]] && break
					echo -e "${gl_hong}请输入以 http:// 或 https:// 开头的网址${gl_bai}"
				done
				endpoint=${endpoint%/}
				# 先确认能连上面板，否则探针装好也无法上报（例如无国际出口的国内机器连不上境外面板）
				install curl
				echo "正在检查面板连通性..."
				if ! curl -s -o /dev/null --connect-timeout 6 -m 12 "$endpoint"; then
					echo -e "${gl_huang}本机无法连接 $endpoint，探针装好后也无法上报数据${gl_bai}"
					echo "如果本机没有国际出口，可经一台能访问面板的机器中转：在中转机用 Realm 转发一个端口到面板的 443，"
					echo "本机 /etc/hosts 把面板域名指向中转机，探针网址填 https://面板域名:中转端口（Cloudflare 支持带端口的访问）"
					read -r -e -p "仍然继续安装吗？(y/N): " choice
					[[ "$choice" =~ ^[Yy]$ ]] || { echo "已取消"; break_end; continue; }
				fi
				while true; do
					read -r -e -p "自动发现密钥（面板 设置 → 自动发现）: " key
					[ -n "$key" ] && [[ "$key" != *[[:space:]]* ]] && break
					echo -e "${gl_hong}密钥不能为空或包含空格${gl_bai}"
				done
				while true; do
					read -r -e -p "月流量重置日（1-31，0 为不重置）[默认 1]: " rotate
					rotate=${rotate:-1}
					[[ "$rotate" =~ ^[0-9]+$ ]] && [ "$rotate" -le 31 ] && break
				done
				use_mirror=n
				nb_in_cn && use_mirror=y
				echo "国内机器建议通过 GitHub 加速镜像下载"
				read -r -e -p "使用加速镜像？(y/n) [默认 $use_mirror]: " choice
				use_mirror=${choice:-$use_mirror}
				mirror=""
				if [[ "$use_mirror" =~ ^[Yy]$ ]]; then
					read -r -e -p "加速镜像地址 [默认 ${gh_proxy_mirror%/}]: " mirror
					mirror=${mirror:-${gh_proxy_mirror%/}}
					mirror=${mirror%/}
				fi

				args=(-e "$endpoint" --auto-discovery "$key" --disable-web-ssh --interval 5.0 --max-retries 5
					--reconnect-interval 10 --info-report-interval 15 --month-rotate "$rotate")
				[ -n "$mirror" ] && args+=(--install-ghproxy "$mirror")

				echo "------------------------"
				echo "探针网址: $endpoint"
				echo "发现密钥: ${key:0:4}****"
				echo "参数    : --disable-web-ssh --interval 5.0 --max-retries 5 --reconnect-interval 10 --info-report-interval 15 --month-rotate $rotate"
				echo "加速镜像: ${mirror:-不使用（直连失败时安装脚本会自动尝试镜像）}"
				echo "------------------------"
				read -r -e -p "确认安装？(Y/N): " choice
				[[ "$choice" =~ ^[Yy]$ ]] || { echo "已取消"; break_end; continue; }

				install curl
				tmp=$(mktemp)
				if [ -n "$mirror" ]; then
					curl -fsSL -m 60 -o "$tmp" "${mirror}/https://raw.githubusercontent.com/komari-monitor/komari-agent/refs/heads/main/install.sh" ||
						nb_download raw.githubusercontent.com/komari-monitor/komari-agent/refs/heads/main/install.sh "$tmp"
				else
					nb_download raw.githubusercontent.com/komari-monitor/komari-agent/refs/heads/main/install.sh "$tmp"
				fi
				if [ -s "$tmp" ] && head -1 "$tmp" | grep -q '^#!'; then
					bash "$tmp" "${args[@]}"
				else
					echo -e "${gl_hong}安装脚本下载失败${gl_bai}（GitHub 和加速镜像都无法连接；无国际出口的机器需手动上传 /opt/komari/agent）"
				fi
				rm -f "$tmp"
				break_end
				;;
			2)
				read -r -e -p "确定卸载 Komari Agent 吗？(Y/N): " choice
				[[ "$choice" =~ ^[Yy]$ ]] || continue
				if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/komari-agent.service ]; then
					command systemctl disable --now komari-agent.service >/dev/null 2>&1
					rm -f /etc/systemd/system/komari-agent.service
					command systemctl daemon-reload
				fi
				if [ -f /etc/init.d/komari-agent ]; then
					rc-service komari-agent stop >/dev/null 2>&1
					rc-update del komari-agent default >/dev/null 2>&1
					rm -f /etc/init.d/komari-agent
				fi
				rm -rf /opt/komari
				echo -e "${gl_lv}Komari Agent 已卸载${gl_bai}"
				break_end
				;;
			*) break ;;
		esac
	done
}

# ---------------------------------------------------------------------------
# Realm 端口转发（zywe03/realm-xwPF，管理命令 pf）
# ---------------------------------------------------------------------------
XWPF_REPO="raw.githubusercontent.com/zywe03/realm-xwPF/main"
XWPF_DIR="/usr/local/bin"

nb_realm_version() {
	[ -x "$XWPF_DIR/realm" ] || return 1
	"$XWPF_DIR/realm" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

nb_xwpf_version() {
	sed -n 's/^SCRIPT_VERSION="\{0,1\}v\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' "$XWPF_DIR/lib/core.sh" 2>/dev/null | head -1
}

# 下载并安装 xwPF 入口脚本和模块（经 nb_download，国内机器自动走代理）；参数为临时目录
realm_xwpf_fetch_scripts() {
	local tmp="$1" f
	local -a libs
	echo "正在下载 xwPF 脚本..."
	if ! nb_download "$XWPF_REPO/xwPF.sh" "$tmp/xwPF.sh" || ! head -1 "$tmp/xwPF.sh" | grep -q '^#!'; then
		echo -e "${gl_hong}xwPF.sh 下载失败${gl_bai}"
		return 1
	fi
	# 模块列表以入口脚本中的 LIB_FILES 为准
	read -r -a libs <<< "$(sed -n 's/^LIB_FILES=(\(.*\))/\1/p' "$tmp/xwPF.sh" | tr -d '"')"
	[ "${#libs[@]}" -gt 0 ] || libs=(core.sh rules.sh server.sh realm.sh ui.sh)
	mkdir -p "$tmp/lib"
	for f in "${libs[@]}"; do
		if ! nb_download "$XWPF_REPO/lib/$f" "$tmp/lib/$f" || ! bash -n "$tmp/lib/$f" 2>/dev/null; then
			echo -e "${gl_hong}lib/$f 下载失败${gl_bai}"
			return 1
		fi
	done
	mkdir -p "$XWPF_DIR/lib"
	install -m 755 "$tmp/xwPF.sh" "$XWPF_DIR/xwPF.sh"
	for f in "${libs[@]}"; do install -m 644 "$tmp/lib/$f" "$XWPF_DIR/lib/$f"; done
	ln -sf "$XWPF_DIR/xwPF.sh" "$XWPF_DIR/pf"
}

# xwPF 适配过的 realm 版本（core.sh 中的 REALM_VERSION，不带 v）
realm_xwpf_target_version() {
	sed -n 's/^REALM_VERSION="v\{0,1\}\([0-9.]*\)"$/\1/p' "$XWPF_DIR/lib/core.sh" 2>/dev/null | head -1
}

# 下载 realm 压缩包并校验版本：realm_xwpf_fetch_realm <版本> <保存路径>
realm_xwpf_fetch_realm() {
	local ver="$1" dest="$2" arch dir
	case "$(uname -m)" in
		x86_64) arch="x86_64-unknown-linux-musl" ;;
		aarch64) arch="aarch64-unknown-linux-musl" ;;
		armv7l|arm) arch="armv7-unknown-linux-musleabihf" ;;
		*) echo -e "${gl_hong}不支持的架构 $(uname -m)${gl_bai}"; return 1 ;;
	esac
	echo "正在下载 realm v$ver..."
	dir=$(dirname "$dest")
	if nb_download "github.com/zhboner/realm/releases/download/v$ver/realm-$arch.tar.gz" "$dest" &&
		tar -xzf "$dest" -C "$dir" realm 2>/dev/null &&
		"$dir/realm" --version 2>/dev/null | grep -q "$ver"; then
		return 0
	fi
	echo -e "${gl_hong}realm 下载或校验失败${gl_bai}"
	return 1
}

# 更新 xwPF 脚本与 realm 主程序，规则与配置不动
realm_xwpf_update() {
	local tmp ver_old realm_old realm_new was_active=false
	tmp=$(mktemp -d) || return 1
	ver_old=$(nb_xwpf_version)
	realm_xwpf_fetch_scripts "$tmp" || { rm -rf "$tmp"; return 1; }
	echo -e "xwPF 脚本: ${ver_old:-未知} → ${gl_lv}$(nb_xwpf_version)${gl_bai}"

	realm_new=$(realm_xwpf_target_version)
	realm_old=$(nb_realm_version)
	if [ -z "$realm_new" ]; then
		echo -e "${gl_huang}未能读取 realm 目标版本，跳过 realm 更新${gl_bai}"
	elif [ "$realm_old" = "$realm_new" ]; then
		echo -e "realm: ${gl_lv}$realm_old 已是最新${gl_bai}"
	elif realm_xwpf_fetch_realm "$realm_new" "$tmp/realm.tar.gz"; then
		nb_service_active realm && was_active=true
		[ "$was_active" = true ] && systemctl stop realm
		[ -f "$XWPF_DIR/realm" ] && cp -p "$XWPF_DIR/realm" "$XWPF_DIR/realm.bak"
		install -m 755 "$tmp/realm" "$XWPF_DIR/realm"
		[ "$was_active" = true ] && systemctl start realm
		echo -e "realm: ${realm_old:-未安装} → ${gl_lv}$(nb_realm_version)${gl_bai}（旧版本备份为 $XWPF_DIR/realm.bak）"
		if [ "$was_active" = true ]; then
			sleep 1
			if nb_service_active realm; then
				echo -e "realm 服务: ${gl_lv}运行中${gl_bai}"
			else
				echo -e "realm 服务: ${gl_hong}启动失败${gl_bai}，可用 pf 查看日志，或把 $XWPF_DIR/realm.bak 改回 realm"
			fi
		fi
	else
		echo "realm 未做改动"
	fi
	rm -rf "$tmp"
}

# 首次安装：脚本和 realm 压缩包都由 Nimbus 下载（国内走代理），再交给 xwPF 自己的安装流程；
# xwPF 的「离线安装」选项读取本地压缩包，不再直连 GitHub，配置与服务仍由 xwPF 生成
realm_xwpf_install() {
	local tmp ver entry
	tmp=$(mktemp -d) || return 1
	realm_xwpf_fetch_scripts "$tmp" || { rm -rf "$tmp"; return 1; }
	ver=$(realm_xwpf_target_version)
	if [ -z "$ver" ] || ! realm_xwpf_fetch_realm "$ver" "$tmp/realm.tar.gz"; then
		rm -rf "$tmp"
		return 1
	fi
	# 取入口脚本中主入口 case 之前的部分（变量与 _load_libs），跳过会直连 GitHub 的 _bootstrap
	entry="$tmp/xwpf-entry.sh"
	sed '/^case "\${1:-}" in/,$d' "$XWPF_DIR/xwPF.sh" > "$entry"
	if ! grep -q '^_load_libs()' "$entry"; then
		echo -e "${gl_hong}xwPF 入口脚本结构已变化，无法离线安装${gl_bai}"
		rm -rf "$tmp"
		return 1
	fi
	echo "开始安装 realm（xwPF 会查询一次 GitHub 上的最新版本，国内机器约等待 10 秒后自动继续）"
	# 唯一的交互是「离线安装 realm 输入完整路径」，传入已下载的压缩包
	printf '%s\n' "$tmp/realm.tar.gz" |
		bash -c '. "$1" && _load_libs && _SKIP_SCRIPT_UPDATE=1 smart_install' _ "$entry"
	rm -rf "$tmp"
}

realm_xwpf() {
	root_use
	local choice
	if [ -x "$XWPF_DIR/xwPF.sh" ] && [ -f "$XWPF_DIR/lib/core.sh" ]; then
		while true; do
			clear
			echo "Realm 端口转发（xwPF）"
			echo "------------------------------------------------"
			echo -e "xwPF 脚本: ${gl_huang}$(nb_xwpf_version)${gl_bai}    realm: ${gl_huang}$(nb_realm_version || echo 未安装)${gl_bai}    服务: $(nb_service_active realm && echo -e "${gl_lv}运行中${gl_bai}" || echo -e "${gl_hui}未运行${gl_bai}")"
			echo -e "${gl_hui}项目地址: https://github.com/zywe03/realm-xwPF${gl_bai}"
			echo "------------------------------------------------"
			echo "1. 管理转发规则（pf）"
			echo "2. 更新 xwPF 脚本和 realm（国内机器自动走代理，不影响现有规则）"
			echo "------------------------------------------------"
			echo "0. 返回上一级选单"
			echo "------------------------------------------------"
			read -r -e -p "请输入你的选择: " choice
			case "$choice" in
				1) pf ;;
				2) realm_xwpf_update; break_end ;;
				*) return ;;
			esac
		done
	fi
	clear
	echo "Realm 端口转发（xwPF）"
	echo "------------------------------------------------"
	echo "安装 realm 及 xwPF 管理脚本，安装后输入 pf 管理转发规则"
	echo -e "${gl_hui}项目地址: https://github.com/zywe03/realm-xwPF${gl_bai}"
	echo "------------------------------------------------"
	read -r -e -p "确定安装吗？(Y/N): " choice
	[[ "$choice" =~ ^[Yy]$ ]] || { echo "已取消"; return; }
	install curl wget tar bc jq
	realm_xwpf_install
	if [ -x "$XWPF_DIR/realm" ] && command -v pf >/dev/null 2>&1; then
		echo -e "${gl_lv}安装完成，以后输入 ${gl_huang}pf${gl_lv} 管理转发规则${gl_bai}"
	else
		echo -e "${gl_hong}安装未完成${gl_bai}，请检查上面的输出"
	fi
}

# ---------------------------------------------------------------------------
# XBoard-node 节点（Hei-XiaoHu/Xboard-Node，cedar2025/Xboard-Node 的维护分支）
# ---------------------------------------------------------------------------
xboard_node_menu() {
	root_use
	local choice panel token node_id kernel arch bindir installer="/root/xboard-node-install.sh" repo="Hei-XiaoHu/Xboard-Node"
	local -a bin_args
	xbn_fetch() {
		if nb_download "raw.githubusercontent.com/$repo/main/install.sh" "$installer" && head -1 "$installer" | grep -q '^#!'; then
			return 0
		fi
		echo -e "${gl_hong}安装脚本下载失败${gl_bai}"
		return 1
	}
	# 安装脚本只会直连 github.com 下载二进制，国内机器会失败：先用 nb_download（走代理）下好，再用 --binary 交给它
	xbn_fetch_bins() {
		bin_args=()
		case "$(uname -m)" in
			x86_64|amd64) arch=amd64 ;;
			aarch64|arm64) arch=arm64 ;;
			*) return 0 ;;
		esac
		bindir=$(mktemp -d) || return 0
		echo "正在下载 xboard-node / xbctl 最新版（linux-$arch）..."
		if nb_download "github.com/$repo/releases/latest/download/xboard-node-linux-$arch" "$bindir/xboard-node" &&
			nb_download "github.com/$repo/releases/latest/download/xbctl-linux-$arch" "$bindir/xbctl"; then
			chmod +x "$bindir/xboard-node" "$bindir/xbctl"
			bin_args=(--binary "$bindir/xboard-node" --xbctl-binary "$bindir/xbctl")
		else
			rm -rf "$bindir"; bindir=""
			echo -e "${gl_huang}预下载失败，改由安装脚本直接下载${gl_bai}"
		fi
	}
	xbn_cleanup_bins() { [ -n "$bindir" ] && rm -rf "$bindir"; bindir=""; }
	while true; do
		clear
		echo "XBoard-node 节点"
		echo "------------------------------------------------"
		if nb_service_active xboard-node; then
			echo -e "当前状态: ${gl_lv}运行中${gl_bai}"
		elif [ -f /etc/systemd/system/xboard-node.service ]; then
			echo -e "当前状态: ${gl_huang}已安装，未运行${gl_bai}"
		else
			echo -e "当前状态: ${gl_hui}未安装${gl_bai}"
		fi
		[ -x /usr/local/bin/xboard-node ] && echo "当前版本: $(/usr/local/bin/xboard-node -v 2>/dev/null | head -n 1)"
		echo -e "${gl_hui}项目地址: https://github.com/$repo（main 分支安装脚本 + 最新 release）${gl_bai}"
		echo "------------------------------------------------"
		echo "1. 安装 / 重新配置             2. 查看状态"
		echo "3. 升级                        4. 卸载"
		echo "------------------------------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------------------------------"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1)
				while true; do
					read -r -e -p "面板网址（如 https://panel.example.com）: " panel
					[[ "$panel" =~ ^https?://[^[:space:]]+$ ]] && break
					echo -e "${gl_hong}请输入以 http:// 或 https:// 开头的网址${gl_bai}"
				done
				panel=${panel%/}
				while true; do
					read -r -s -p "通讯密钥 token（输入不显示）: " token
					echo ""
					[ -n "$token" ] && [[ "$token" != *[[:space:]]* ]] && break
					echo -e "${gl_hong}token 不能为空或包含空格${gl_bai}"
				done
				while true; do
					read -r -e -p "节点 ID: " node_id
					[[ "$node_id" =~ ^[0-9]+$ ]] && break
					echo -e "${gl_hong}节点 ID 应为数字${gl_bai}"
				done
				read -r -e -p "内核 1. xray（默认）  2. sing-box : " choice
				case "$choice" in
					2) kernel="singbox" ;;
					*) kernel="xray" ;;
				esac
				echo "------------------------"
				echo "面板: $panel    节点 ID: $node_id    内核: $kernel    token: ${token:0:4}****"
				read -r -e -p "确认安装？(Y/N): " choice
				[[ "$choice" =~ ^[Yy]$ ]] || { echo "已取消"; break_end; continue; }
				install curl
				if xbn_fetch; then
					xbn_fetch_bins
					bash "$installer" --mode node --panel "$panel" --token "$token" --node-id "$node_id" --kernel "$kernel" "${bin_args[@]}"
					xbn_cleanup_bins
				fi
				break_end
				;;
			2) [ -f "$installer" ] || xbn_fetch; [ -f "$installer" ] && bash "$installer" status; break_end ;;
			3)
				if xbn_fetch; then
					xbn_fetch_bins
					bash "$installer" upgrade "${bin_args[@]}"
					xbn_cleanup_bins
				fi
				break_end ;;
			4)
				echo "卸载 XBoard-node：输入 Y 仅卸载程序；输入 purge 同时删除配置 /etc/xboard-node"
				read -r -e -p "请输入 (Y/purge/N): " choice
				case "$choice" in
					purge) xbn_fetch && bash "$installer" uninstall --purge --yes ;;
					[Yy]) xbn_fetch && bash "$installer" uninstall --yes ;;
					*) echo "已取消" ;;
				esac
				break_end
				;;
			*) break ;;
		esac
	done
}

# ---------------------------------------------------------------------------
# 自动安装安全更新（unattended-upgrades，仅 Debian / Ubuntu）
# ---------------------------------------------------------------------------
NB_UU_CONF="/etc/apt/apt.conf.d/52nimbus-security-only"
NB_UU_PERIODIC="/etc/apt/apt.conf.d/20auto-upgrades"
NB_UU_LOG="/var/log/unattended-upgrades/unattended-upgrades.log"

nb_secupd_os() {
	local id="" like=""
	command -v apt-get >/dev/null 2>&1 || return 1
	if [ -r /etc/os-release ]; then
		id=$(. /etc/os-release && echo "$ID")
		like=$(. /etc/os-release && echo "$ID_LIKE")
	fi
	case "$id" in
		debian|ubuntu) echo "$id" ;;
		*) case " $like " in *" ubuntu "*) echo ubuntu ;; *" debian "*) echo debian ;; *) return 1 ;; esac ;;
	esac
}

nb_secupd_enabled() {
	dpkg -s unattended-upgrades >/dev/null 2>&1 &&
		apt-config dump 2>/dev/null | grep -q '^APT::Periodic::Unattended-Upgrade "1"'
}

nb_secupd_last() {
	[ -s "$NB_UU_LOG" ] && tail -1 "$NB_UU_LOG" | cut -c1-16
}

nb_secupd_next() {
	command systemctl show -p NextElapseUSecRealtime --value apt-daily-upgrade.timer 2>/dev/null | grep -v '^n/a$'
}

nb_secupd_enable() {
	local os choice
	os=$(nb_secupd_os) || { echo -e "${gl_hong}仅支持 Debian / Ubuntu${gl_bai}"; return 1; }
	if nb_is_pve; then
		echo -e "${gl_huang}当前是 Proxmox VE 宿主机${gl_bai}：只会自动安装 Debian 安全源的补丁，PVE 源（内核、qemu、pve-manager 等）不受影响"
		echo "PVE 本身的升级仍需手动执行 apt dist-upgrade"
		read -r -e -p "确定开启吗？(Y/N): " choice
		[[ "$choice" =~ ^[Yy]$ ]] || { echo "已取消"; return 1; }
	fi
	dpkg -s unattended-upgrades >/dev/null 2>&1 || install unattended-upgrades || return 1

	{
		echo '// Managed by nimbus：只自动安装安全更新，不自动重启（覆盖 50unattended-upgrades 的来源列表）'
		echo '#clear Unattended-Upgrade::Origins-Pattern;'
		echo '#clear Unattended-Upgrade::Allowed-Origins;'
		echo 'Unattended-Upgrade::Origins-Pattern {'
		if [ "$os" = "ubuntu" ]; then
			# shellcheck disable=SC2016  # ${distro_codename} 由 unattended-upgrades 展开
			printf '\t"%s";\n' 'origin=Ubuntu,archive=${distro_codename}-security' \
				'origin=UbuntuESMApps,archive=${distro_codename}-apps-security' \
				'origin=UbuntuESM,archive=${distro_codename}-infra-security'
		else
			# shellcheck disable=SC2016
			printf '\t"%s";\n' 'origin=Debian,codename=${distro_codename}-security,label=Debian-Security' \
				'origin=Debian,codename=${distro_codename},label=Debian-Security'
		fi
		echo '};'
		echo 'Unattended-Upgrade::Automatic-Reboot "false";'
		echo 'Unattended-Upgrade::MinimalSteps "true";'
	} > "$NB_UU_CONF"
	cat > "$NB_UU_PERIODIC" <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
	if [ -d /run/systemd/system ]; then
		command systemctl enable --now apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1
	fi
	echo -e "${gl_lv}已开启自动安装安全更新${gl_bai}，生效的更新来源:"
	apt-config dump 2>/dev/null | grep -A5 '^Unattended-Upgrade::Origins-Pattern' | grep -E '^Unattended-Upgrade::Origins-Pattern::' | sed 's/^[^"]*"/  /; s/";$//'
}

nb_secupd_disable() {
	[ -f "$NB_UU_PERIODIC" ] && sed -i 's/^APT::Periodic::Unattended-Upgrade .*/APT::Periodic::Unattended-Upgrade "0";/' "$NB_UU_PERIODIC"
	apt-config dump 2>/dev/null | grep -q '^APT::Periodic::Unattended-Upgrade "1"' &&
		echo 'APT::Periodic::Unattended-Upgrade "0";' >> "$NB_UU_PERIODIC"
	rm -f "$NB_UU_CONF"
	echo -e "${gl_lv}已关闭自动安装安全更新${gl_bai}（unattended-upgrades 软件包保留）"
}

nb_security_updates() {
	root_use
	local choice last next
	while true; do
		clear
		echo "自动安装安全更新"
		echo "------------------------------------------------"
		if ! nb_secupd_os >/dev/null; then
			echo -e "${gl_hui}当前系统不支持（仅支持 Debian / Ubuntu）${gl_bai}"
			return
		fi
		if nb_secupd_enabled && [ -f "$NB_UU_CONF" ]; then
			echo -e "当前状态: ${gl_lv}已开启（仅安全更新）${gl_bai}"
		elif nb_secupd_enabled; then
			echo -e "当前状态: ${gl_huang}已开启（系统默认策略，含普通稳定更新）${gl_bai}"
		else
			echo -e "当前状态: ${gl_hui}未开启${gl_bai}"
		fi
		last=$(nb_secupd_last); next=$(nb_secupd_next)
		[ -n "$last" ] && echo "上次运行: $last"
		nb_secupd_enabled && [ -n "$next" ] && echo "下次运行: $next"
		nb_reboot_pending && echo -e "${gl_huang}有已安装的更新（如新内核）需要重启才能生效${gl_bai}"
		echo -e "${gl_hui}每天自动安装 Debian/Ubuntu 安全源补丁；不自动重启，不动第三方源（XanMod、Docker、PVE 等）${gl_bai}"
		echo "------------------------------------------------"
		echo "1. 开启（仅安全更新）          2. 关闭"
		echo "3. 模拟运行（只检查不安装）    4. 立即执行一次"
		echo "5. 查看运行日志"
		echo "------------------------------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------------------------------"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1) nb_secupd_enable; break_end ;;
			2) nb_secupd_disable; break_end ;;
			3|4)
				if ! command -v unattended-upgrade >/dev/null 2>&1; then
					echo "请先开启（会安装 unattended-upgrades）"
				else
					apt-get update -qq
					if [ "$choice" = 3 ]; then unattended-upgrade --dry-run -v; else unattended-upgrade -v; fi
				fi
				break_end
				;;
			5)
				if [ -s "$NB_UU_LOG" ]; then tail -n 30 "$NB_UU_LOG"; else echo "暂无运行日志"; fi
				break_end
				;;
			*) break ;;
		esac
	done
}

# ---------------------------------------------------------------------------
# 新机开荒：把新机常用操作按推荐顺序集中到一个菜单，逐项执行
# ---------------------------------------------------------------------------
NB_WZ_STATE="/etc/nimbus/wizard.state"

nb_wz_mark() {
	mkdir -p /etc/nimbus 2>/dev/null || return 0
	{ grep -v "^$1=" "$NB_WZ_STATE" 2>/dev/null; echo "$1=$(date +%s)"; } > "$NB_WZ_STATE.tmp" && mv -f "$NB_WZ_STATE.tmp" "$NB_WZ_STATE"
}

nb_wz_marked() {
	local ts
	ts=$(grep "^$1=" "$NB_WZ_STATE" 2>/dev/null | tail -1 | cut -d= -f2)
	[ -n "$ts" ] && date -d "@$ts" '+%m-%d %H:%M' 2>/dev/null
}

nb_reboot_pending() {
	[ -f /var/run/reboot-required ] && return 0
	local latest
	latest=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sed 's#.*/vmlinuz-##' | sort -V | tail -1)
	[ -n "$latest" ] && [ "$latest" != "$(uname -r)" ]
}

nb_sshd_opt() {
	sshd -T 2>/dev/null | awk -v k="$1" '$1==k{print $2}' | paste -sd, -
}

# 设置 WZ_DONE / WZ_ICON / WZ_TEXT
nb_wz_status() {
	local key="$1" m v cc q
	m=$(nb_wz_marked "$key")
	WZ_DONE=false
	WZ_TEXT=""
	case "$key" in
		dd)      WZ_TEXT="可自定义版本/密码/端口/RAID${m:+，上次 $m}" ;;
		passwd)  [ -n "$m" ] && { WZ_DONE=true; WZ_TEXT="已修改 $m"; } || WZ_TEXT="DD 用了临时密码时请先改" ;;
		update)  [ -n "$m" ] && { WZ_DONE=true; WZ_TEXT="已执行 $m"; } || WZ_TEXT="未执行" ;;
		bbr)
			cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null); q=$(sysctl -n net.core.default_qdisc 2>/dev/null)
			if [ "$cc" = "bbr" ] && [ "$q" = "fq" ]; then
				WZ_DONE=true; WZ_TEXT="bbr + fq"
				uname -r | grep -qi xanmod && WZ_TEXT="$WZ_TEXT · XanMod"
			elif uname -r | grep -qi xanmod || grep -qs 'bbr' /etc/sysctl.d/99-nimbus-bbr.conf; then
				WZ_TEXT="已配置，重启后生效（当前 ${cc:-?} / ${q:-?}）"
			else
				WZ_TEXT="当前 ${cc:-?} / ${q:-?}"
				nb_is_pve && WZ_TEXT="$WZ_TEXT（PVE: 仅开 BBR，不换内核）"
			fi ;;
		reboot)
			if nb_reboot_pending; then WZ_ICON_WARN=true; WZ_TEXT="需要重启以启用新内核"
			else [ -n "$m" ] && WZ_DONE=true; WZ_TEXT="内核 $(uname -r)"; fi ;;
		tz)
			v=$(timedatectl show -p Timezone --value 2>/dev/null)
			[ -n "$v" ] || v=$(cat /etc/timezone 2>/dev/null)
			[ -n "$v" ] || v=$(readlink /etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##')
			[ -n "$m" ] && WZ_DONE=true; WZ_TEXT="${v:-未知}" ;;
		hostname)
			[ -n "$m" ] && WZ_DONE=true; WZ_TEXT="$(uname -n)"
			nb_is_pve && WZ_TEXT="$WZ_TEXT（PVE 不建议修改）" ;;
		hosts)
			if getent hosts "$(uname -n)" >/dev/null 2>&1; then WZ_DONE=true; WZ_TEXT="主机名可解析"; else WZ_TEXT="主机名无法解析"; fi ;;
		swap)
			v=$(awk '/^SwapTotal/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
			[ -n "$m" ] && WZ_DONE=true
			[ "${v:-0}" -gt 0 ] && WZ_TEXT="swap ${v}M" || WZ_TEXT="未设置 swap" ;;
		dns)
			v=$(awk '/^nameserver/{print $2}' /etc/resolv.conf 2>/dev/null | head -2 | paste -sd' ' -)
			[ -n "$m" ] && WZ_DONE=true; WZ_TEXT="${v:-未知}" ;;
		autosec)
			if ! nb_secupd_os >/dev/null; then WZ_NA=true; WZ_TEXT="不适用（仅支持 Debian / Ubuntu）"
			elif nb_secupd_enabled && [ -f "$NB_UU_CONF" ]; then WZ_DONE=true; WZ_TEXT="已开启（仅安全更新）"
			elif nb_secupd_enabled; then WZ_DONE=true; WZ_TEXT="已开启（系统默认策略）"
			else WZ_TEXT="未开启"; fi
			v=$(nb_secupd_last); [ -n "$v" ] && WZ_TEXT="$WZ_TEXT · 上次 $v" ;;
		sshkey)
			v=$(nb_sshd_opt passwordauthentication)
			if [ "$v" = "no" ]; then WZ_DONE=true; WZ_TEXT="已禁用密码登录"; else WZ_TEXT="允许密码登录"; fi ;;
		sshport)
			v=$(nb_sshd_opt port)
			[ -n "$v" ] || v=$(grep -E '^[[:space:]]*Port[[:space:]]+[0-9]+' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | paste -sd, -)
			v=${v:-22}
			if [ "$v" != "22" ] || [ -n "$m" ]; then WZ_DONE=true; fi; WZ_TEXT="端口 $v" ;;
		sudo)
			v=$(nb_sshd_opt permitrootlogin)
			if [ "$v" = "no" ]; then WZ_DONE=true; WZ_TEXT="root 已禁止登录"; else WZ_TEXT="生产机建议，普通机可跳过"; fi ;;
		f2b)
			if nb_service_active fail2ban; then WZ_DONE=true; WZ_TEXT="运行中"
			elif command -v fail2ban-client >/dev/null 2>&1; then WZ_TEXT="已安装，未运行"
			else WZ_TEXT="未安装"; fi ;;
		tmux)
			if command -v tmux >/dev/null 2>&1 && grep -qs 'Nimbus tmux' "$HOME/.tmux.conf"; then WZ_DONE=true; WZ_TEXT="已配置"
			elif command -v tmux >/dev/null 2>&1; then WZ_TEXT="已安装，未写入推荐配置"
			else WZ_TEXT="未安装"; fi ;;
		blesh)
			v=$(nb_blesh_version)
			if [ -n "$v" ] && grep -qs 'blesh/ble\.sh' "$HOME/.bashrc"; then
				WZ_DONE=true; WZ_TEXT="已启用 $v"
				grep -qs 'Nimbus ble.sh' "$HOME/.blerc" || WZ_TEXT="$WZ_TEXT · 未写入推荐快捷键"
			elif [ -n "$v" ]; then WZ_TEXT="已安装 $v，未在 .bashrc 启用"
			else WZ_TEXT="未安装"; fi ;;
		tg)
			if [ -f "$TG_NOTIFY_CONF" ] && { nb_service_active tg-check-notify || pgrep -f '^/bin/bash /root/TG-check-notify.sh' >/dev/null 2>&1; }; then WZ_DONE=true; WZ_TEXT="运行中"
			elif [ -f "$TG_NOTIFY_CONF" ]; then WZ_TEXT="已配置，监控未运行"
			else WZ_TEXT="未配置"; fi ;;
		lang)
			v=$(sed -n 's/^LANG=["'\'']\{0,1\}\([^"'\'']*\).*/\1/p' /etc/default/locale /etc/locale.conf 2>/dev/null | head -n 1)
			case "$v" in
				""|C|C.UTF-8|C.utf8|POSIX) WZ_TEXT="${v:-未设置}" ; [ -n "$m" ] && WZ_DONE=true ;;
				*) WZ_DONE=true; WZ_TEXT="$v" ;;
			esac ;;
		ps1)
			if grep -qs '^# >>> nimbus PS1 >>>' "$HOME/.profile" "$HOME/.bashrc"; then WZ_DONE=true; WZ_TEXT="已设置"
			elif grep -qs '^PS1=' "$HOME/.profile"; then WZ_TEXT="旧版设置，重新选择一次即可修复"
			else WZ_TEXT="默认"; fi ;;
		komari)
			if nb_service_active komari-agent; then WZ_DONE=true; WZ_TEXT="运行中"; else WZ_TEXT="未安装"; fi ;;
		realm)
			if command -v pf >/dev/null 2>&1; then WZ_DONE=true; WZ_TEXT="已安装（命令 pf）"; else WZ_TEXT="未安装"; fi ;;
		xboard)
			if nb_service_active xboard-node; then WZ_DONE=true; WZ_TEXT="运行中"; else WZ_TEXT="未安装"; fi ;;
	esac
}

nb_wz_passwd() {
	root_use
	echo "修改 root 密码"
	echo "------------------------"
	passwd root
}

nb_wz_reboot_check() {
	local choice latest
	while true; do
		clear
		echo "重启并检查内核"
		echo "------------------------------------------------"
		echo -e "当前内核  : ${gl_huang}$(uname -r)${gl_bai}"
		echo -e "拥塞控制  : ${gl_huang}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null) / $(sysctl -n net.core.default_qdisc 2>/dev/null)${gl_bai}"
		if nb_reboot_pending; then
			latest=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sed 's#.*/vmlinuz-##' | sort -V | tail -1)
			echo -e "${gl_huang}检测到新内核 ${latest} 尚未启用，需要重启${gl_bai}"
		else
			echo -e "${gl_lv}当前已运行最新安装的内核${gl_bai}"
		fi
		echo -e "${gl_hui}重启后重新登录，输入 nb init 回到新机开荒继续${gl_bai}"
		echo "------------------------------------------------"
		echo "1. 立即重启                    2. 查看完整系统信息"
		echo "------------------------------------------------"
		echo "0. 返回"
		echo "------------------------------------------------"
		read -r -e -p "请输入你的选择: " choice
		case "$choice" in
			1) server_reboot ;;
			2) linux_info; break_end ;;
			*) break ;;
		esac
	done
}

# 手动标记：done 标记完成 / undone 标记未完成 / skip 跳过；空值表示自动检测
nb_wz_manual_get() {
	grep "^$1\.m=" "$NB_WZ_STATE" 2>/dev/null | tail -1 | cut -d= -f2
}

nb_wz_manual_set() {
	mkdir -p /etc/nimbus 2>/dev/null || return 0
	{
		grep -v "^$1\.m=" "$NB_WZ_STATE" 2>/dev/null
		if [ -n "$2" ]; then echo "$1.m=$2"; fi
	} > "$NB_WZ_STATE.tmp" || return 0
	mv -f "$NB_WZ_STATE.tmp" "$NB_WZ_STATE"
}

# 自动检测结果叠加手动标记，设置 WZ_DONE / WZ_ICON_WARN / WZ_SKIP / WZ_NA / WZ_TEXT
nb_wz_effective() {
	local key="$1"
	WZ_ICON_WARN=false; WZ_NA=false; WZ_SKIP=false
	nb_wz_status "$key"
	case "$(nb_wz_manual_get "$key")" in
		done)   WZ_DONE=true; WZ_ICON_WARN=false; WZ_SKIP=false; WZ_TEXT="$WZ_TEXT（手动标记完成）" ;;
		undone) WZ_DONE=false; WZ_ICON_WARN=false; WZ_TEXT="$WZ_TEXT（手动标记未完成）" ;;
		skip)   WZ_SKIP=true; WZ_TEXT="已跳过 · $WZ_TEXT" ;;
	esac
}

nb_wizard() {
	root_use
	local choice next next_title i key n cmd nums
	local -a keys=("dd" "passwd" "update" "bbr" "reboot" "tz" "hostname" "hosts" "swap" "dns" "autosec" "sshkey" "sshport" "sudo" "f2b" "tmux" "blesh" "tg" "lang" "ps1" "komari" "realm" "xboard")
	local -a titles=("重装系统 DD（可选）                " "修改 root 密码                     " "更新系统软件包                     " "内核与 BBR 加速                    " "重启并检查内核                     " "系统时区                           " "主机名                             " "本机 hosts 解析                    " "虚拟内存                           " "优化 DNS                           " "自动安装安全更新                   " "SSH 密钥登录（禁用密码）           " "修改 SSH 端口                      " "新建 sudo 用户并禁用 root（可选）  " "fail2ban SSH 防御                  " "tmux 及推荐配置                    " "ble.sh 命令行增强                  " "TG-bot 监控预警（可选）            " "切换系统语言                       " "命令行美化                         " "Komari 探针（可选）                " "Realm 端口转发（可选）             " "XBoard-node 节点（可选）           ")
	local -a funcs=("dd_xitong" "nb_wz_passwd" "linux_update" "bbrv3" "nb_wz_reboot_check" "nb_timezone_menu" "nb_hostname_menu" "nb_hosts_menu" "nb_swap_menu" "set_dns_ui" "nb_security_updates" "sshkey_panel" "nb_ssh_port_menu" "nb_create_sudo_user" "fail2ban_panel" "tmux_setup" "blesh_setup" "tg_notify_menu" "linux_language" "shell_bianse" "komari_agent_menu" "realm_xwpf" "xboard_node_menu")
	local -a opts=("1" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "1" "0" "0" "0" "1" "0" "0" "1" "1" "1")
	while true; do
		clear
		echo -e "${gl_cyan}新机开荒${gl_bai} · 按推荐顺序逐项完成，可随时退出，回来后继续（nb init）"
		echo -e "${gl_hui}✔ 已完成  ○ 待处理  ⚠ 需注意  – 跳过/不适用；「可选」步骤不参与推荐${gl_bai}"
		next=""
		for i in "${!keys[@]}"; do
			case $((i + 1)) in
				1) echo -e "${gl_cyan}【一 · 系统安装】${gl_bai}" ;;
				2) echo -e "${gl_cyan}【二 · 基础与内核（装完新内核重启一次）】${gl_bai}" ;;
				6) echo -e "${gl_cyan}【三 · 系统设置】${gl_bai}" ;;
				12) echo -e "${gl_cyan}【四 · SSH 与账号安全】${gl_bai}" ;;
				16) echo -e "${gl_cyan}【五 · 环境与监控】${gl_bai}" ;;
				21) echo -e "${gl_cyan}【六 · 应用部署（按需）】${gl_bai}" ;;
			esac
			key="${keys[$i]}"
			nb_wz_effective "$key"
			if [ "$WZ_SKIP" = true ] || [ "$WZ_NA" = true ]; then
				printf ' %b–%b ' "$gl_hui" "$gl_bai"
			elif [ "$WZ_ICON_WARN" = true ]; then
				printf ' %b⚠%b ' "$gl_huang" "$gl_bai"
			elif [ "$WZ_DONE" = true ]; then
				printf ' %b✔%b ' "$gl_lv" "$gl_bai"
			else
				printf ' %b○%b ' "$gl_hui" "$gl_bai"
			fi
			printf '%b%-4s%b%s %b%s%b\n' "$gl_cyan" "$((i + 1))." "$gl_bai" "${titles[$i]}" "$gl_hui" "$WZ_TEXT" "$gl_bai"
			if [ -z "$next" ] && [ "${opts[$i]}" != 1 ] && [ "$WZ_SKIP" != true ] && [ "$WZ_NA" != true ] &&
				{ [ "$WZ_DONE" != true ] || [ "$WZ_ICON_WARN" = true ]; }; then
				next=$((i + 1))
			fi
		done
		echo "------------------------------------------------"
		if [ -n "$next" ]; then
			next_title=$(printf '%s' "${titles[$((next - 1))]}" | sed 's/[[:space:]]*$//')
			echo -e "推荐下一步: ${gl_huang}${next}. ${next_title}${gl_bai}"
		else
			echo -e "${gl_lv}必做步骤已全部完成${gl_bai}，可选步骤按需执行"
		fi
		echo "------------------------------------------------"
		echo "编号. 执行该步骤          n. 执行推荐的下一步       s. 跳过推荐的这一步"
		echo "m 编号. 切换完成/未完成   a 编号. 恢复自动检测      r. 清除全部记录"
		echo -e "${gl_hui}m、a 可带多个编号，如 m 3 6 9${gl_bai}"
		echo "0. 返回主菜单"
		echo "------------------------------------------------"
		read -r -e -p "请输入步骤编号或命令: " choice
		cmd=$(printf '%s' "$choice" | sed -E 's/^[[:space:]]*([a-zA-Z]?).*/\1/' | tr '[:upper:]' '[:lower:]')
		nums=$(printf '%s' "$choice" | sed -E 's/^[[:space:]]*[a-zA-Z]?//')
		case "$cmd" in
			n) [ -n "$next" ] || continue; choice="$next" ;;
			s) [ -n "$next" ] && nb_wz_manual_set "${keys[$((next - 1))]}" skip; continue ;;
			r) rm -f "$NB_WZ_STATE"; continue ;;
			m|a)
				for n in $nums; do
					[[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#keys[@]}" ] || continue
					key="${keys[$((n - 1))]}"
					if [ "$cmd" = a ]; then
						nb_wz_manual_set "$key" ""
					else
						nb_wz_effective "$key"
						if [ "$WZ_DONE" = true ] && [ "$WZ_ICON_WARN" != true ] && [ "$WZ_SKIP" != true ]; then
							nb_wz_manual_set "$key" undone
						else
							nb_wz_manual_set "$key" "done"
						fi
					fi
				done
				continue
				;;
		esac
		case "$choice" in 0|"") break ;; esac
		if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#keys[@]}" ]; then
			clear
			key="${keys[$((choice - 1))]}"
			"${funcs[$((choice - 1))]}"
			nb_wz_mark "$key"
			nb_wz_manual_set "$key" ""
			break_end
		fi
	done
}

# ---- 系统工具：可被新机开荒复用的功能 ----
nb_ssh_port_menu() {
	root_use

	while true; do
		clear
		sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

		# 读取当前的 SSH 端口号
		local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

		# 打印当前的 SSH 端口号
		echo -e "当前的 SSH 端口号是:  ${gl_huang}$current_port ${gl_bai}"

		echo "------------------------"
		echo "端口号范围1到65535之间的数字。（输入0退出）"

		# 提示用户输入新的 SSH 端口号
		read -e -p "请输入新的 SSH 端口号: " new_port

		# 判断端口号是否在有效范围内
		if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
			if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
				if new_ssh_port "$new_port"; then
					echo -e "${gl_huang}请保持当前会话，新开终端用端口 $new_port 测试登录成功后再断开${gl_bai}"
					break
				fi
				break_end
			elif [[ $new_port -eq 0 ]]; then
				break
			else
				echo "端口号无效，请输入1到65535之间的数字。"
				break_end
			fi
		else
			echo "输入无效，请输入数字。"
			break_end
		fi
	done
}

nb_create_sudo_user() {
	root_use
	echo "新建 sudo 用户并禁用 root"
	echo "------------------------"
	echo "1. 创建新用户（需导入该用户的 SSH 公钥），加入 sudo 且免密码"
	echo "2. 公钥导入成功后：锁定 root 密码、禁止 root 通过 SSH 登录，并重启 sshd"
	echo -e "${gl_huang}完成后请先新开一个终端，用新用户登录并执行 sudo -i 验证，确认无误再关闭当前会话${gl_bai}"
	echo "------------------------"
	read -e -p "请输入新用户名（输入0退出）: " new_username
	if [ -z "$new_username" ] || [ "$new_username" == "0" ]; then
		return
	fi

	create_user_with_sshkey "$new_username" true || return 1

	if ssh-keygen -l -f "/home/$new_username/.ssh/authorized_keys" &>/dev/null; then
		passwd -l root &>/dev/null
		sed -i 's/^[[:space:]]*#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
		grep -q '^PermitRootLogin' /etc/ssh/sshd_config || echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
		restart_ssh
		echo -e "${gl_lv}已禁用 root 登录，请使用 ${new_username} 登录后通过 sudo 管理${gl_bai}"
	else
		echo -e "${gl_huang}未检测到有效公钥，root 保持可用${gl_bai}"
	fi
}

nb_swap_menu() {
	root_use
	while true; do
		clear
		echo "设置虚拟内存"
		local swap_used=$(free -m | awk 'NR==3{print $3}')
		local swap_total=$(free -m | awk 'NR==3{print $2}')
		local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

		echo -e "当前虚拟内存: ${gl_huang}$swap_info${gl_bai}"
		echo "------------------------"
		echo "1. 分配1024M         2. 分配2048M         3. 分配4096M         4. 自定义大小"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice

		case "$choice" in
		  1)
			add_swap 1024

			;;
		  2)
			add_swap 2048

			;;
		  3)
			add_swap 4096

			;;

		  4)
			read -e -p "请输入虚拟内存大小（单位M）: " new_swap
			add_swap "$new_swap"
			;;

		  *)
			break
			;;
		esac
	done
}

nb_timezone_menu() {
	root_use
	while true; do
		clear
		echo "系统时间信息"

		# 获取当前系统时区
		local timezone=$(current_timezone)

		# 获取当前系统时间
		local current_time=$(date +"%Y-%m-%d %H:%M:%S")

		# 显示时区和时间
		echo "当前系统时区：$timezone"
		echo "当前系统时间：$current_time"

		echo ""
		echo "时区切换"
		echo "------------------------"
		echo "亚洲"
		echo "1.  中国上海时间             2.  中国香港时间"
		echo "3.  日本东京时间             4.  韩国首尔时间"
		echo "5.  新加坡时间               6.  印度加尔各答时间"
		echo "7.  阿联酋迪拜时间           8.  澳大利亚悉尼时间"
		echo "9.  泰国曼谷时间"
		echo "------------------------"
		echo "欧洲"
		echo "11. 英国伦敦时间             12. 法国巴黎时间"
		echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
		echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
		echo "------------------------"
		echo "美洲"
		echo "21. 美国西部时间             22. 美国东部时间"
		echo "23. 加拿大时间               24. 墨西哥时间"
		echo "25. 巴西时间                 26. 阿根廷时间"
		echo "------------------------"
		echo "31. UTC全球标准时间"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "请输入你的选择: " sub_choice


		case $sub_choice in
			1) set_timedate Asia/Shanghai ;;
			2) set_timedate Asia/Hong_Kong ;;
			3) set_timedate Asia/Tokyo ;;
			4) set_timedate Asia/Seoul ;;
			5) set_timedate Asia/Singapore ;;
			6) set_timedate Asia/Kolkata ;;
			7) set_timedate Asia/Dubai ;;
			8) set_timedate Australia/Sydney ;;
			9) set_timedate Asia/Bangkok ;;
			11) set_timedate Europe/London ;;
			12) set_timedate Europe/Paris ;;
			13) set_timedate Europe/Berlin ;;
			14) set_timedate Europe/Moscow ;;
			15) set_timedate Europe/Amsterdam ;;
			16) set_timedate Europe/Madrid ;;
			21) set_timedate America/Los_Angeles ;;
			22) set_timedate America/New_York ;;
			23) set_timedate America/Vancouver ;;
			24) set_timedate America/Mexico_City ;;
			25) set_timedate America/Sao_Paulo ;;
			26) set_timedate America/Argentina/Buenos_Aires ;;
			31) set_timedate UTC ;;
			*) break ;;
		esac
	done
}

# /etc/hosts 中把旧主机名替换为新主机名（整词匹配），并保证新主机名可解析
nb_hosts_set_hostname() {
	local old="$1" new="$2" old_re new_re tmp
	[ -f /etc/hosts ] || touch /etc/hosts
	cp -f /etc/hosts /etc/hosts.nbbak 2>/dev/null
	tmp=$(mktemp) || return 1
	cp -f /etc/hosts "$tmp"
	if [ -n "$old" ] && [ "$old" != "localhost" ] && [ "$old" != "$new" ]; then
		old_re=$(printf '%s' "$old" | sed 's/[.]/\\./g')
		# 整词替换旧主机名，以及以旧主机名开头的 FQDN（oldhost.example.com -> newhost.example.com）
		sed -i -E ":a; s/(^|[[:space:]])${old_re}(\.[^[:space:]]+)?([[:space:]]|$)/\1${new}\2\3/; ta" "$tmp"
	fi
	new_re=$(printf '%s' "$new" | sed 's/[.]/\\./g')
	if ! grep -Eq "(^|[[:space:]])${new_re}([[:space:]]|$)" "$tmp"; then
		if grep -q '^127\.0\.1\.1[[:space:]]' "$tmp"; then
			sed -i "/^127\.0\.1\.1[[:space:]]/ s/\$/ ${new}/" "$tmp"
		else
			printf '127.0.1.1\t%s\n' "$new" >> "$tmp"
		fi
	fi
	# 写回而不是替换文件：/etc/hosts 在容器中常为挂载点，不能被 rename
	cat "$tmp" > /etc/hosts
	rm -f "$tmp"
}

nb_hostname_menu() {
	root_use
	local current_hostname new_hostname choice
	if nb_is_pve; then
		echo -e "${gl_hong}警告: 当前是 Proxmox VE 宿主机${gl_bai}"
		echo "PVE 的节点名与主机名绑定（/etc/pve/nodes/<主机名>），修改后 Web 界面、虚拟机配置可能异常，集群节点绝不能改"
		echo "如确需修改，请先参考 PVE 官方文档迁移节点配置"
		read -r -e -p "仍要继续修改吗？(y/N): " choice
		[[ "$choice" =~ ^[Yy]$ ]] || return
	fi

	while true; do
		clear
		current_hostname=$(uname -n)
		echo -e "当前主机名: ${gl_huang}$current_hostname${gl_bai}"
		echo "------------------------"
		read -r -e -p "请输入新的主机名（输入0退出）: " new_hostname
		if [ -z "$new_hostname" ] || [ "$new_hostname" = "0" ]; then
			echo "已退出，未更改主机名。"
			break
		fi
		if ! [[ "$new_hostname" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]{0,61}[A-Za-z0-9])?$ ]]; then
			echo -e "${gl_hong}主机名只能包含字母、数字、点和连字符，且不能以符号开头或结尾${gl_bai}"
			break_end
			continue
		fi
		if [ -f /etc/alpine-release ] || ! command -v hostnamectl >/dev/null 2>&1; then
			echo "$new_hostname" > /etc/hostname
			hostname "$new_hostname"
		else
			hostnamectl set-hostname "$new_hostname"
		fi
		nb_hosts_set_hostname "$current_hostname" "$new_hostname"
		echo -e "${gl_lv}主机名已更改为: $new_hostname${gl_bai}（/etc/hosts 已同步，原文件备份为 /etc/hosts.nbbak）"
		break
	done
}

nb_hosts_menu() {
	  root_use
	  while true; do
		  clear
		  echo "本机host解析列表"
		  echo "如果你在这里添加解析匹配，将不再使用动态解析了"
		  cat /etc/hosts
		  echo ""
		  echo "操作"
		  echo "------------------------"
		  echo "1. 添加新的解析              2. 删除解析地址"
		  echo "------------------------"
		  echo "0. 返回上一级选单"
		  echo "------------------------"
		  read -e -p "请输入你的选择: " host_dns

		  case $host_dns in
			  1)
				  read -e -p "请输入新的解析记录 格式: 110.25.5.33 example.com : " addhost
				  echo "$addhost" >> /etc/hosts

				  ;;
			  2)
				  read -e -p "请输入需要删除的解析内容关键字: " delhost
				  sed -i "/$delhost/d" /etc/hosts
				  ;;
			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
	  done
}

linux_Settings() {

	while true; do
	  clear
	  echo -e "系统工具"
	  echo -e "${gl_cyan}------------- 账号与登录 -------------"
	  echo -e "${gl_cyan}1.   ${gl_bai}修改登录密码                       ${gl_cyan}2.   ${gl_bai}用户密码登录模式"
	  echo -e "${gl_cyan}3.   ${gl_bai}用户密钥登录模式                   ${gl_cyan}4.   ${gl_bai}禁用ROOT账户创建新账户"
	  echo -e "${gl_cyan}5.   ${gl_bai}用户管理                           ${gl_cyan}6.   ${gl_bai}用户/密码生成器"
	  echo -e "${gl_cyan}------------- 网络 -------------"
	  echo -e "${gl_cyan}7.   ${gl_bai}开放所有端口                       ${gl_cyan}8.   ${gl_bai}修改SSH连接端口"
	  echo -e "${gl_cyan}9.   ${gl_bai}优化DNS地址                        ${gl_cyan}10.  ${gl_bai}切换优先ipv4/ipv6"
	  echo -e "${gl_cyan}11.  ${gl_bai}查看端口占用状态                   ${gl_cyan}12.  ${gl_bai}防火墙高级管理器"
	  echo -e "${gl_cyan}13.  ${gl_bai}本机host解析                       ${gl_cyan}14.  ${gl_bai}网卡管理工具"
	  echo -e "${gl_cyan}------------- 系统 -------------"
	  echo -e "${gl_cyan}15.  ${gl_bai}一键重装系统 ${gl_huang}★${gl_bai}                     ${gl_cyan}16.  ${gl_bai}修改虚拟内存大小"
	  echo -e "${gl_cyan}17.  ${gl_bai}系统时区调整                       ${gl_cyan}18.  ${gl_bai}设置BBR3加速"
	  echo -e "${gl_cyan}19.  ${gl_bai}修改主机名                         ${gl_cyan}20.  ${gl_bai}切换系统更新源"
	  echo -e "${gl_cyan}21.  ${gl_bai}定时任务管理                       ${gl_cyan}22.  ${gl_bai}切换系统语言"
	  echo -e "${gl_cyan}23.  ${gl_bai}系统变量管理工具"
	  echo -e "${gl_cyan}------------- 安全与运维 -------------"
	  echo -e "${gl_cyan}24.  ${gl_bai}SSH防御程序                        ${gl_cyan}25.  ${gl_bai}限流自动关机"
	  echo -e "${gl_cyan}26.  ${gl_bai}TG-bot系统监控预警                 ${gl_cyan}27.  ${gl_bai}命令行美化工具 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}28.  ${gl_bai}系统备份与恢复                     ${gl_cyan}29.  ${gl_bai}硬盘分区管理工具"
	  echo -e "${gl_cyan}30.  ${gl_bai}命令行历史记录                     ${gl_cyan}31.  ${gl_bai}系统日志管理工具 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}32.  ${gl_bai}自动安装安全更新                   ${gl_cyan}33.  ${gl_bai}ble.sh 命令行增强"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}99.  ${gl_bai}重启服务器                         ${gl_cyan}101. ${gl_bai}命令行用法 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_cyan}102. ${gl_bai}卸载 Nimbus"
	  echo -e "${gl_cyan}------------------------"
	  echo -e "${gl_cyan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_cyan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "设置你的登录密码"
			  passwd
			  ;;
		  2)
			  clear
			  add_sshpasswd
			  ;;

		  7)
			  root_use
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "端口已全部开放"

			  ;;
		  8)
			  nb_ssh_port_menu
			  ;;

		  9)
			set_dns_ui
			  ;;

		  15)

			dd_xitong
			  ;;
		  4)
			  nb_create_sudo_user
			  ;;

		  10)
			root_use
			while true; do
				clear
				echo "设置v4/v6优先级"
				echo "------------------------"


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "当前网络优先级设置: ${gl_huang}IPv4${gl_bai} 优先"
				else
					echo -e "当前网络优先级设置: ${gl_huang}IPv6${gl_bai} 优先"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 优先          2. IPv6 优先          3. IPv6 修复工具"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "选择优先的网络: " choice

				case $choice in
					1)
						prefer_ipv4
						;;
					2)
						rm -f /etc/gai.conf
						echo "已切换为 IPv6 优先"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "该功能由jhb大神提供，感谢他！"
						;;

					*)
						break
						;;

				esac
			done
			;;

		  11)
			clear
			ss -tulnape
			;;

		  16)
			  nb_swap_menu
			  ;;

		  5)
			  while true; do
				root_use
				echo "用户列表"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status
					if sudo -n -lU "$username" 2>/dev/null | grep -q "(ALL) \(NOPASSWD: \)\?ALL"; then
						sudo_status="Yes"
					else
						sudo_status="No"
					fi
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "账户操作"
				  echo "------------------------"
				  echo "1. 创建普通用户             2. 创建高级用户"
				  echo "------------------------"
				  echo "3. 赋予最高权限             4. 取消最高权限"
				  echo "------------------------"
				  echo "5. 删除账号"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
					   # 提示用户输入新用户名
					   read -e -p "请输入新用户名: " new_username
					   create_user_with_sshkey $new_username false

						  ;;

					  2)
					   # 提示用户输入新用户名
					   read -e -p "请输入新用户名: " new_username
					   create_user_with_sshkey $new_username true

						  ;;
					  3)
					   read -e -p "请输入用户名: " username
					   install sudo
					   cat >"/etc/sudoers.d/$username" <<EOF
$username ALL=(ALL) NOPASSWD:ALL
EOF
					  chmod 440 "/etc/sudoers.d/$username"

						  ;;
					  4)
					   read -e -p "请输入用户名: " username
				  	   if [[ -f "/etc/sudoers.d/$username" ]]; then
						   grep -lR "^$username" /etc/sudoers.d/ 2>/dev/null | xargs rm -f
					   fi
					   sed -i "/^$username\s*ALL=(ALL)/d" /etc/sudoers
						  ;;
					  5)
					   read -e -p "请输入要删除的用户名: " username
					   userdel -r "$username"
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac

			  done
			  ;;

		  6)
			clear
			echo "随机用户名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "随机用户名 $i: $username"
			done

			echo ""
			echo "随机姓名"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "随机用户姓名 $i: $user_name"
			done

			echo ""
			echo "随机UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "随机UUID $i: $uuid"
			done

			echo ""
			echo "16位随机密码"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "随机密码 $i: $password"
			done

			echo ""
			echo "32位随机密码"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "随机密码 $i: $password"
			done
			echo ""

			  ;;

		  17)
			  nb_timezone_menu
			  ;;

		  18)

			bbrv3
			  ;;

		  12)
			  iptables_panel

			  ;;

		  19)
			  nb_hostname_menu
			  ;;

		  20)
		  root_use
		  clear
		  echo "选择更新源区域"
		  echo "接入LinuxMirrors切换系统更新源"
		  echo "------------------------"
		  echo "1. 中国大陆【默认】          2. 中国大陆【教育网】          3. 海外地区          4. 智能切换更新源"
		  echo "------------------------"
		  echo "0. 返回上一级选单"
		  echo "------------------------"
		  read -e -p "输入你的选择: " choice

		  case $choice in
			  1)
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  4)
				  switch_mirror false false
				  ;;

			  *)
				  echo "已取消"
				  ;;

		  esac

			  ;;

		  21)
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "定时任务列表"
				  crontab -l
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1. 添加定时任务              2. 删除定时任务              3. 编辑定时任务"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "请输入新任务的执行命令: " newquest
						  echo "------------------------"
						  echo "1. 每月任务                 2. 每周任务"
						  echo "3. 每天任务                 4. 每小时任务"
						  echo "------------------------"
						  read -e -p "请输入你的选择: " dingshi

						  case $dingshi in
							  1)
								  read -e -p "选择每月的几号执行任务？ (1-30): " day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "选择每天几点执行任务？（小时，0-23）: " hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "输入每小时的第几分钟执行任务？（分钟，0-60）: " minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  ;;
					  2)
						  read -e -p "请输入需要删除任务的关键字: " kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  ;;
					  3)
						  crontab -e
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  13)
			  nb_hosts_menu
			  ;;

		  24)
			fail2ban_panel
			  ;;


		  25)
			root_use
			while true; do
				clear
				echo "限流关机功能"
				echo "------------------------------------------------"
				echo "当前流量使用情况，重启服务器流量计算会清零！"
				output_status
				echo -e "${gl_cyan}总接收: ${gl_bai}$rx"
				echo -e "${gl_cyan}总发送: ${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}当前设置的进站限流阈值为: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}当前设置的出站限流阈值为: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}当前未启用限流关机功能${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！"
				echo "------------------------"
				echo "1. 开启限流关机功能          2. 停用限流关机功能"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "请输入你的选择: " Limiting

				case "$Limiting" in
				  1)
					# 输入新的虚拟内存大小
					echo "如果实际服务器就100G流量，可设置阈值为95G，提前关机，以免出现流量误差或溢出。"
					read -e -p "请输入进站流量阈值（单位为G，默认100G）: " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "请输入出站流量阈值（单位为G，默认100G）: " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "请输入流量重置日期（默认每月1日重置）: " cz_day
					cz_day=${cz_day:-1}

					cd ~
					if ! nb_download raw.githubusercontent.com/zidou-kiyn/nimbus/main/Limiting_Shut_down1.sh ~/Limiting_Shut_down.sh; then
						echo "限流关机脚本下载失败"
						continue
					fi
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(crontab -l ; echo "0 1 $cz_day * * reboot") | crontab - > /dev/null 2>&1
					echo "限流关机已设置"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm -f ~/Limiting_Shut_down.sh
					echo "已关闭限流关机功能"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  3)
			sshkey_panel
			  ;;

		  26)
			  root_use
			  tg_notify_menu
			  ;;

		  22)
			  linux_language
			  ;;

		  27)
			  shell_bianse
			  ;;
		  28)
			  linux_backup
			  ;;
		  29)
			  disk_manager
			  ;;
		  30)
			  clear
			  get_history_file() {
				  for file in "$HOME"/.bash_history "$HOME"/.ash_history "$HOME"/.zsh_history "$HOME"/.local/share/fish/fish_history; do
					  [ -f "$file" ] && { echo "$file"; return; }
				  done
				  return 1
			  }

			  history_file=$(get_history_file) && cat -n "$history_file"
			  ;;

		  14)
			  clear
			  net_menu
			  ;;

		  31)
			  clear
			  log_menu
			  ;;

		  32)
			  nb_security_updates
			  ;;

		  33)
			  blesh_setup
			  ;;

		  23)
			  clear
			  env_menu
			  ;;


		  99)
			  clear
			  server_reboot
			  ;;
		  101)
			  clear
			  nb_help
			  ;;

		  102)
			  clear
			  echo "卸载 Nimbus"
			  echo "------------------------------------------------"
			  echo "将删除 nb 命令、脚本文件及自动更新任务，不影响已安装的软件和配置"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "nimbus.sh") | crontab -
				  rm -f /usr/local/bin/nb /usr/bin/nb
				  rm -f ~/nimbus.sh ~/nimbus.sh.bak
				  echo "脚本已卸载，再见！"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  0)
			  nimbus_home

			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done



}



# 下载最新脚本替换 ~/nimbus.sh，保留本机线路模式（canshu）。成功后 NB_SELF_UPDATE_INFO 为“版本 模式”
nb_self_update() {
	local mode="$canshu" base="raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh" tmp url urls
	# 尚未设置模式时检测一次：国内 IP → CN；只有 IPv6 出口（无 IPv4 默认路由）→ V6；双栈/纯 IPv4 保持直连
	if [ "$mode" = "default" ]; then
		if [ "$(nb_country)" = "CN" ]; then
			mode="CN"
		elif [ -z "$(ip -4 route show default 2>/dev/null)" ] && [ -n "$(ip -6 route show default 2>/dev/null)" ]; then
			mode="V6"
		fi
	fi
	if [ "$mode" = "default" ]; then
		urls="https://$base ${gh_proxy_mirror}https://$base ${nb_cnb_raw}nimbus.sh"
	else
		urls="${gh_proxy_mirror}https://$base https://$base ${nb_cnb_raw}nimbus.sh"
	fi

	tmp=$(mktemp ~/nimbus_tmp.XXXXXX) || return 1
	for url in $urls; do
		if curl -fsSL --connect-timeout 8 -m 60 -o "$tmp" "$url" 2>/dev/null && head -1 "$tmp" | grep -q '^#!/bin/bash' && grep -q '^sh_v=' "$tmp" && grep -q '^canshu="default"' "$tmp"; then
			# 直连失败、靠镜像才下载成功：切换为 CN 模式
			[ "$mode" = "default" ] && [ "$url" != "https://$base" ] && mode="CN"
			sed -i "s/^canshu=\"default\"/canshu=\"$mode\"/" "$tmp"
			chmod 755 "$tmp"
			cp -f ~/nimbus.sh ~/nimbus.sh.bak 2>/dev/null
			mv -f "$tmp" ~/nimbus.sh || break
			if nb_atomic_copy ~/nimbus.sh /usr/local/bin/nb; then
				[ "$(readlink -f /usr/bin/nb 2>/dev/null)" = /usr/local/bin/nb ] || ln -sf /usr/local/bin/nb /usr/bin/nb 2>/dev/null
			fi
			NB_SELF_UPDATE_INFO="$(grep -m1 '^sh_v=' ~/nimbus.sh | cut -d '"' -f 2) $mode"
			return 0
		fi
	done
	rm -f "$tmp"
	return 1
}

nimbus_update() {

cd ~
while true; do
	clear
	echo "更新日志"
	echo "------------------------"
	echo "全部日志: ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/CHANGELOG.md"
	echo "------------------------"

	# GitHub（国内走代理）取不到时用国内镜像 cnb.cool
	{ curl -fs --connect-timeout 8 --max-time 15 ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/CHANGELOG.md ||
		curl -fs --connect-timeout 8 --max-time 15 "${nb_cnb_raw}CHANGELOG.md"; } | tail -n 30
	# 只下载开头 1KB 获取版本号，避免下载整个脚本
	local sh_v_new=$({ curl -fs --connect-timeout 8 --max-time 15 -r 0-1023 ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh ||
		curl -fs --connect-timeout 8 --max-time 15 -r 0-1023 "${nb_cnb_raw}nimbus.sh"; } | grep -o 'sh_v="[0-9.]*"' | head -1 | cut -d '"' -f 2)

	if [ -z "$sh_v_new" ]; then
		echo -e "${gl_hong}无法获取最新版本信息，请检查网络连接${gl_bai}"
	elif [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}你已经是最新版本！${gl_huang}v$sh_v${gl_bai}"
	else
		echo "发现新版本！"
		echo -e "当前版本 v$sh_v        最新版本 ${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="nimbus.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}自动更新已开启，每天凌晨2点脚本会自动更新！${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 现在更新            2. 开启自动更新            3. 关闭自动更新"
	echo "------------------------"
	echo "0. 返回主菜单"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
	case "$choice" in
		1)
			clear
			if nb_self_update; then
				echo -e "${gl_lv}脚本已更新到最新版本！${gl_huang}v${NB_SELF_UPDATE_INFO% *}${gl_bai}（线路模式: ${NB_SELF_UPDATE_INFO#* }）"
			else
				echo -e "${gl_hong}更新失败！下载出错或文件校验不通过，未做修改${gl_bai}"
			fi
			break_end
			~/nimbus.sh
			exit
			;;
		2)
			clear
			# 定时执行 nb self-update：与“现在更新”同一逻辑，保留本机线路模式
			check_crontab_installed
			(crontab -l 2>/dev/null | grep -v "nimbus.sh"; nb_update_cron_line "$(shuf -i 0-59 -n 1)") | crontab -
			echo -e "${gl_lv}自动更新已开启，每天凌晨2点脚本会自动更新！${gl_bai}"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "nimbus.sh") | crontab -
			echo -e "${gl_lv}自动更新已关闭${gl_bai}"
			break_end
			;;
		*)
			nimbus_main
			;;
	esac
done

}



nimbus_main() {
while true; do
clear
echo -e "${gl_cyan}"
echo "╔╗╔╦╔╦╗╔╗ ╦ ╦╔═╗"
echo "║║║║║║║╠╩╗║ ║╚═╗"
echo "╝╚╝╩╩ ╩╚═╝╚═╝╚═╝"
echo -e "Nimbus · 云服务器工具箱 v$sh_v"
echo -e "命令行输入${gl_huang}nb${gl_cyan}可快速启动${gl_bai}"
if [ "$NB_FIRST_INSTALL" = true ]; then
	echo -e "${gl_lv}已安装快捷命令 nb，脚本位于 ~/nimbus.sh${gl_bai}"
	NB_FIRST_INSTALL=false
elif [ "$EUID" -ne 0 ] && [ ! -x /usr/local/bin/nb ]; then
	echo -e "${gl_huang}提示: 以 root 身份运行才会安装快捷命令 nb${gl_bai}"
fi
echo -e "${gl_cyan}------------------------${gl_bai}"
echo -e "${gl_cyan}1.   ${gl_bai}系统信息查询"
echo -e "${gl_cyan}2.   ${gl_bai}系统更新"
echo -e "${gl_cyan}3.   ${gl_bai}系统清理"
echo -e "${gl_cyan}4.   ${gl_bai}基础工具"
echo -e "${gl_cyan}5.   ${gl_bai}BBRv3加速"
echo -e "${gl_cyan}6.   ${gl_bai}Docker管理"
echo -e "${gl_cyan}7.   ${gl_bai}测试脚本合集"
echo -e "${gl_cyan}8.   ${gl_bai}系统工具"
echo -e "${gl_cyan}9.   ${gl_bai}新机开荒 ${gl_huang}★${gl_bai}"
echo -e "${gl_cyan}------------------------${gl_bai}"
echo -e "${gl_cyan}00.  ${gl_bai}脚本更新"
echo -e "${gl_cyan}------------------------${gl_bai}"
echo -e "${gl_cyan}0.   ${gl_bai}退出脚本"
echo -e "${gl_cyan}------------------------${gl_bai}"
read -e -p "请输入你的选择: " choice

case $choice in
  1) linux_info ;;
  2) clear ; linux_update ;;
  3) clear ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) linux_test ;;
  8) linux_Settings ;;
  9) nb_wizard ;;
  00) nimbus_update ;;
  0) clear ; exit ;;
  *) echo "无效的输入!" ;;
esac
	break_end
done
}


nb_help() {
echo "-------------------"
echo "以下是 nb 命令参考用例："
echo "启动脚本            nb"
echo "新机开荒            nb init | nb 开荒"
echo "自动安装安全更新    nb secupdate | nb 安全更新"
echo "ble.sh 命令行增强   nb blesh"
echo "更新 Nimbus 脚本    nb self-update"
echo "安装软件包          nb install nano wget | nb add nano wget | nb 安装 nano wget"
echo "卸载软件包          nb remove nano wget | nb del nano wget | nb uninstall nano wget | nb 卸载 nano wget"
echo "更新系统            nb update | nb 更新"
echo "清理系统垃圾        nb clean | nb 清理"
echo "重装系统面板        nb dd | nb 重装"
echo "bbr3控制面板        nb bbr3 | nb bbrv3"
echo "设置虚拟内存        nb swap 2048"
echo "设置虚拟时区        nb time Asia/Shanghai | nb 时区 Asia/Shanghai"
echo "系统备份功能        nb backup | nb bf | nb 备份"
echo "硬盘管理工具        nb disk | nb 硬盘管理"
echo "软件启动            nb start sshd | nb 启动 sshd "
echo "软件停止            nb stop sshd | nb 停止 sshd "
echo "软件重启            nb restart sshd | nb 重启 sshd "
echo "软件状态查看        nb status sshd | nb 状态 sshd "
echo "软件开机启动        nb enable docker | nb autostart docker | nb 开机启动 docker "
echo "docker管理平面      nb docker"
echo "docker环境安装      nb docker install |nb docker 安装"
echo "docker容器管理      nb docker ps |nb docker 容器"
echo "docker镜像管理      nb docker img |nb docker 镜像"
echo "防火墙面板          nb fhq |nb 防火墙"
echo "开放端口            nb dkdk 8080 |nb 打开端口 8080"
echo "关闭端口            nb gbdk 7800 |nb 关闭端口 7800"
echo "放行IP              nb fxip 127.0.0.0/8 |nb 放行IP 127.0.0.0/8"
echo "阻止IP              nb zzip 177.5.25.36 |nb 阻止IP 177.5.25.36"
echo "fail2ban管理        nb fail2ban | nb f2b"
echo "显示系统信息        nb info"
echo "ROOT密钥管理        nb sshkey"
echo "SSH公钥导入(URL)    nb sshkey <url>"
echo "SSH公钥导入(GitHub) nb sshkey github <user> "

}



if [ "$#" -eq 0 ]; then
	# 如果没有参数，运行交互式逻辑
	nimbus_main
else
	# 如果有参数，执行相应函数
	case $1 in
		install|add|安装)
			shift
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			remove "$@"
			;;
		update|更新)
			linux_update
			;;
		clean|清理)
			linux_clean
			;;
		dd|重装)
			dd_xitong
			;;
		init|开荒|新机)
			nb_wizard
			;;
		secupdate|安全更新)
			nb_security_updates
			;;
		blesh|ble)
			blesh_setup
			;;
		self-update|selfupdate)
			if nb_self_update; then
				echo "Nimbus 已更新到 v${NB_SELF_UPDATE_INFO% *}（线路模式: ${NB_SELF_UPDATE_INFO#* }）"
			else
				echo "Nimbus 更新失败：下载出错或文件校验不通过，未做修改" >&2
				exit 1
			fi
			;;
		bbr3|bbrv3)
			bbrv3
			;;
		backup|bf|备份)
			linux_backup
			;;
		disk|硬盘管理)
			disk_manager
			;;

		swap)
			shift
			add_swap "$@"
			;;

		time|时区)
			shift
			set_timedate "$@"
			;;

		test|check|体检|测试)
			linux_test
			;;


		iptables_open)
			iptables_open
			;;

		打开端口|dkdk)
			shift
			open_port "$@"
			;;

		关闭端口|gbdk)
			shift
			close_port "$@"
			;;

		放行IP|fxip)
			shift
			allow_ip "$@"
			;;

		阻止IP|zzip)
			shift
			block_ip "$@"
			;;

		防火墙|fhq)
			iptables_panel
			;;

		status|状态)
			shift
			status "$@"
			;;
		start|启动)
			shift
			start "$@"
			;;
		stop|停止)
			shift
			stop "$@"
			;;
		restart|重启)
			shift
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			enable "$@"
			;;

		docker)
			shift
			case $1 in
				install|安装)
					install_docker
					;;
				ps|容器)
					docker_ps
					;;
				img|镜像)
					docker_image
					;;
				*)
					linux_docker
					;;
			esac
			;;

		info)
			linux_info
			;;

		fail2ban|f2b)
			fail2ban_panel
			;;


		sshkey)

			shift
			case "$1" in
				"" )
					# sshkey → 交互菜单
					sshkey_panel
					;;
				github )
					shift
					fetch_github_ssh_keys "$1"
					;;
				http://*|https://* )
					fetch_remote_ssh_keys "$1"
					;;
				ssh-rsa*|ssh-ed25519*|ssh-ecdsa* )
					import_sshkey "$1"
					;;
				* )
					echo "错误：未知参数 '$1'"
					echo "用法："
					echo "  nb sshkey                 进入交互菜单"
					echo "  nb sshkey \"<pubkey>\"    直接导入 SSH 公钥"
					echo "  nb sshkey <url>           从 URL 导入 SSH 公钥"
					echo "  nb sshkey github <user>   从 GitHub 导入 SSH 公钥"
					;;
			esac

			;;
		*)
			nb_help
			;;
	esac
fi
