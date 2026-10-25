#!/bin/bash
# Nimbus · 云服务器工具箱  https://github.com/zidou-kiyn/nimbus
# Copyright 2026 zidou-kiyn. Licensed under Apache-2.0; derived from kejilion/sh, see NOTICE.
sh_v="1.0.0"


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

cp -f ./nimbus.sh ~/nimbus.sh > /dev/null 2>&1
cp -f ~/nimbus.sh /usr/local/bin/nb > /dev/null 2>&1
ln -sf /usr/local/bin/nb /usr/bin/nb > /dev/null 2>&1



ip_address() {

get_public_ip() {
	curl -s https://ipinfo.io/ip && echo
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

local country=$(curl -s ipinfo.io/country)
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

local country=$(curl -s ipinfo.io/country)
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

save_iptables_rules() {
	mkdir -p /etc/iptables
	local rules_temp rules6_temp
	rules_temp=$(mktemp /etc/iptables/.rules.v4.XXXXXX) || return 1
	ip6tables_available && rules6_temp=$(mktemp /etc/iptables/.rules.v6.XXXXXX)
	if ! iptables-save > "$rules_temp" || ! mv -f -- "$rules_temp" /etc/iptables/rules.v4; then
		rm -f -- "$rules_temp" "$rules6_temp"
		return 1
	fi
	if [ -n "${rules6_temp:-}" ]; then
		if ! ip6tables-save > "$rules6_temp" || ! mv -f -- "$rules6_temp" /etc/iptables/rules.v6; then
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
				  iptables-save > /etc/iptables/rules.v4
				  ;;
			  11)
				  # 允许 PING
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  ;;
			  12)
				  # 禁用 PING
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
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

f2b_install_sshd() {

	docker rm -f fail2ban >/dev/null 2>&1
	install fail2ban || return 1

	if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
		install rsyslog || return 1
		/bin/systemctl enable --now rsyslog.service || return 1
		cd /etc/fail2ban/jail.d/
		curl --fail --silent --show-error --location \
			--output centos-ssh.conf \
			"${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/res/config/fail2ban/centos-ssh.conf" || return 1
		if [ ! -e /var/log/secure ]; then
			touch /var/log/secure || return 1
			chmod 0600 /var/log/secure || return 1
			command -v restorecon >/dev/null 2>&1 && restorecon /var/log/secure || true
		fi
	fi

	if command -v apt &>/dev/null; then
		install rsyslog || return 1
		/bin/systemctl enable --now rsyslog.service || return 1
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

}



f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	else
		xxx=sshd
		f2b_status_xxx
	fi
}

# 基础参数配置：封禁时长(bantime)、时间窗口(findtime)、重试次数(maxretry)
# 说明：
# - 优先写入 /etc/fail2ban/jail.d/sshd.local（覆盖默认 jail 配置，升级不易丢）
# - 若是 Alpine 且 jail 名称不同，依然写 sshd.local；Fail2Ban 会按 jail 名称匹配
f2b_basic_config() {
	root_use
	install nano

	if ! command -v fail2ban-client >/dev/null 2>&1; then
		echo -e "${gl_hui}未检测到 fail2ban-client，请先安装 fail2ban。${gl_bai}"
		return
	fi

	local jail_name="sshd"
	if grep -qi 'Alpine' /etc/issue 2>/dev/null; then
		# Alpine 默认 jail 通常为 sshd；仅当检测到自定义 alpine-sshd 规则时才切换
		if [ -f /etc/fail2ban/filter.d/alpine-sshd.conf ] || [ -f /etc/fail2ban/jail.d/alpine-ssh.conf ] || [ -f /etc/fail2ban/jail.d/alpine-sshd.local ]; then
			jail_name="alpine-sshd"
		fi
	fi

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
	if [ "$jail_name" = "sshd" ]; then
		if [ -f /etc/fail2ban/jail.d/sshd.local ]; then
			grep -qE '^\s*logpath\s*=' /etc/fail2ban/jail.d/sshd.local || echo 'logpath = /var/log/auth.log' >> /etc/fail2ban/jail.d/sshd.local
		fi
	fi

	echo -e "${gl_lv}已写入配置${gl_bai}: /etc/fail2ban/jail.d/sshd.local"
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
	[ -f "$cfg" ] || printf "[sshd]\n# bantime/findtime/maxretry\n" > "$cfg"

	nano "$cfg"
	echo -e "${gl_lv}已保存${gl_bai}，正在 reload fail2ban..."
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
		DEBIAN_FRONTEND=noninteractive apt update -y
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


set_dns() {

ip_address

chattr -i /etc/resolv.conf
> /etc/resolv.conf

if [ -n "$ipv4_address" ]; then
	echo "nameserver $dns1_ipv4" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf
fi

if [ -n "$ipv6_address" ]; then
	echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
fi

if [ ! -s /etc/resolv.conf ]; then
	echo "nameserver 223.5.5.5" >> /etc/resolv.conf
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

chattr +i /etc/resolv.conf

}



set_dns_ui() {
root_use
while true; do
	clear
	echo "优化DNS地址"
	echo "------------------------"
	echo "当前DNS地址"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 国外DNS优化: "
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 国内DNS优化: "
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. 手动编辑DNS配置"
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
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		;;
	  3)
		install nano
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
		;;
	  *)
		break
		;;
	esac
done

}



restart_ssh() {
	restart sshd ssh > /dev/null 2>&1

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

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
}


new_ssh_port() {

  local new_port=$1

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i '/^\s*#\?\s*Port\s\+/d' /etc/ssh/sshd_config
  sed -i "1i Port $new_port" /etc/ssh/sshd_config

  correct_ssh_config

  restart_ssh || return 1
  open_port "$new_port" || return 1
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH 端口已修改为: $new_port"

  sleep 1

}



sshkey_on() {

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
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
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

	restart_ssh

	echo -e "${gl_lv}密码设置完毕，已更改为密码登录模式！${gl_bai}"
}



root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示: ${gl_bai}该功能需要root用户才能运行！" && break_end && nimbus_home
}



dd_xitong() {
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "重装后初始用户名: ${gl_huang}root${gl_bai}  初始密码: ${gl_huang}LeitboGi0ro${gl_bai}  初始端口: ${gl_huang}22${gl_bai}"
		  echo -e "${gl_huang}重装后请及时修改初始密码，防止暴力入侵。命令行输入passwd修改密码${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "重装后初始用户名: ${gl_huang}Administrator${gl_bai}  初始密码: ${gl_huang}Teddysun.com${gl_bai}  初始端口: ${gl_huang}3389${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "重装后初始用户名: ${gl_huang}root${gl_bai}  初始密码: ${gl_huang}123@@@${gl_bai}  初始端口: ${gl_huang}22${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "重装后初始用户名: ${gl_huang}Administrator${gl_bai}  初始密码: ${gl_huang}123@@@${gl_bai}  初始端口: ${gl_huang}3389${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "重装系统"
			echo "--------------------------------"
			echo -e "${gl_hong}注意: ${gl_bai}重装有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
			echo -e "${gl_hui}感谢bin456789大佬和leitbogioro大佬的脚本支持！${gl_bai} "
			echo -e "${gl_hui}bin456789项目地址: ${gh_https_url}github.com/bin456789/reinstall${gl_bai}"
			echo -e "${gl_hui}leitbogioro项目地址: ${gh_https_url}github.com/leitbogioro/Tools${gl_bai}"
			echo "------------------------"
			echo "1. Debian 13                  2. Debian 12"
			echo "3. Debian 11                  4. Debian 10"
			echo "------------------------"
			echo "11. Ubuntu 26.04              12. Ubuntu 24.04"
			echo "13. Ubuntu 22.04              14. Ubuntu 20.04"
			echo "------------------------"
			echo "21. Rocky Linux 10            22. Rocky Linux 9"
			echo "23. Alma Linux 10             24. Alma Linux 9"
			echo "25. oracle Linux 10           26. oracle Linux 9"
			echo "27. Fedora Linux 44           28. Fedora Linux 43"
			echo "29. CentOS 10                 30. CentOS 9"
			echo "------------------------"
			echo "31. Alpine Linux              32. Arch Linux"
			echo "33. Kali Linux                34. openEuler"
			echo "35. openSUSE Tumbleweed       36. fnos飞牛公测版"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 返回上一级选单"
			echo "------------------------"
			read -e -p "请选择要重装的系统: " sys_choice
			case "$sys_choice" in


			  1)
				dd_xitong_3
				bash reinstall.sh debian 13
				reboot
				exit
				;;

			  2)
				dd_xitong_3
				bash reinstall.sh debian 12
				reboot
				exit
				;;
			  3)
				dd_xitong_3
				bash reinstall.sh debian 11
				reboot
				exit
				;;
			  4)
				dd_xitong_3
				bash reinstall.sh debian 10
				reboot
				exit
				;;
			  11)
				dd_xitong_3
				bash reinstall.sh ubuntu 26.04
				reboot
				exit
				;;
			  12)
				dd_xitong_3
				bash reinstall.sh ubuntu 24.04
				reboot
				exit
				;;
			  13)
				dd_xitong_3
				bash reinstall.sh ubuntu 22.04
				reboot
				exit
				;;
			  14)
				dd_xitong_3
				bash reinstall.sh ubuntu 20.04
				reboot
				exit
				;;

			  21)
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				dd_xitong_3
				bash reinstall.sh fedora 44
				reboot
				exit
				;;

			  28)
				dd_xitong_3
				bash reinstall.sh fedora 43
				reboot
				exit
				;;

			  29)
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;

			  41)
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;

			  42)
				dd_xitong_2
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;

			  43)
				dd_xitong_4
				bash reinstall.sh windows --iso="https://archive.org/download/en_windows_7_professional_with_sp1_x64_dvd_u_676939_201906/en_windows_7_professional_with_sp1_x64_dvd_u_676939.iso" --image-name='windows 7 professional'
				reboot
				exit
				;;

			  44)
				dd_xitong_2
				bash InstallNET.sh -windows 2025 -lang "cn"
				reboot
				exit
				;;

			  45)
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;

			  46)
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;

			  47)
				dd_xitong_4
				bash reinstall.sh dd --img https://r2.hotdog.eu.org/win11-arm-with-pagefile-15g.xz
				reboot
				exit
				;;

			  *)
				break
				;;
			esac
		  done
}



bbrv3() {
			  root_use

		  xanmod_add_repo() {
				local keyring="/usr/share/keyrings/xanmod-archive-keyring.gpg"
				local list_file="/etc/apt/sources.list.d/xanmod-release.list"
				local key_url="https://dl.xanmod.org/archive.key"
				local fallback_key_url="${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/archive.key"
				local os_codename=""

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
				if ! wget -qO - "$key_url" | gpg --dearmor -o "$keyring" --yes; then
					echo "官方密钥下载失败，尝试备用下载源..."
					wget -qO - "$fallback_key_url" | gpg --dearmor -o "$keyring" --yes || return 1
				fi
				chmod 644 "$keyring"
				echo "deb [signed-by=$keyring] http://deb.xanmod.org $os_codename main" > "$list_file"
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
				apt-cache policy "$package" 2>/dev/null | grep -q 'Candidate: [^ ]'
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


		  local cpu_arch=$(uname -m)
		  if [ "$cpu_arch" != "x86_64" ]; then
			echo "XanMod 内核仅支持 x86_64 架构，当前架构: $cpu_arch"
			break_end
			return
		  fi

		  if [ -r /etc/os-release ]; then
			. /etc/os-release
			if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
				echo "当前环境不支持，仅支持Debian和Ubuntu系统"
				break_end
				return
			fi
		  else
			echo "无法确定操作系统类型"
			break_end
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



shell_bianse_profile() {

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	sed -i '/^PS1=/d' ~/.bashrc
	echo "${bianse}" >> ~/.bashrc
	# source ~/.bashrc
else
	sed -i '/^PS1=/d' ~/.profile
	echo "${bianse}" >> ~/.profile
	# source ~/.profile
fi
echo -e "${gl_lv}变更完成。重新连接SSH后可查看变化！${gl_bai}"

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
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
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

	local ipinfo=$(curl -s ipinfo.io)
	local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
	local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
	local isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')

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
		vim nano git
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
	  echo -e "${gl_cyan}17.  ${gl_bai}git 版本控制系统"
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
	country=$(curl -s ipinfo.io/country)

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
						new_ssh_port $new_port
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


			  ;;


		  9)
			set_dns_ui
			  ;;

		  15)

			dd_xitong
			  ;;
		  4)
			root_use
			read -e -p "请输入新用户名（输入0退出）: " new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			create_user_with_sshkey $new_username true

			ssh-keygen -l -f /home/$new_username/.ssh/authorized_keys &>/dev/null && {
				passwd -l root &>/dev/null
				sed -i 's/^[[:space:]]*#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
			}

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
			  ;;

		  18)

			bbrv3
			  ;;

		  12)
			  iptables_panel

			  ;;

		  19)
		  root_use

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "当前主机名: ${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "请输入新的主机名（输入0退出）: " new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # 其他系统，如 Debian, Ubuntu, CentOS 等
					  hostnamectl set-hostname "$new_hostname"
					  sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
					  systemctl restart systemd-hostnamed
				  fi

				  if grep -q "127.0.0.1" /etc/hosts; then
					  sed -i "s/127.0.0.1 .*/127.0.0.1       $new_hostname localhost localhost.localdomain/g" /etc/hosts
				  else
					  echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >> /etc/hosts
				  fi

				  if grep -q "^::1" /etc/hosts; then
					  sed -i "s/^::1 .*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
				  else
					  echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >> /etc/hosts
				  fi

				  echo "主机名已更改为: $new_hostname"
				  sleep 1
			  else
				  echo "已退出，未更改主机名。"
				  break
			  fi
		  done
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
					if ! curl -fsS -o ~/Limiting_Shut_down.sh ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/Limiting_Shut_down1.sh; then
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
			  echo "TG-bot监控预警功能"
			  echo "视频介绍: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "您需要配置tg机器人API和接收预警的用户ID，即可实现本机CPU，内存，硬盘，流量，SSH登录的实时监控预警"
			  echo "到达阈值后会向用户发预警消息"
			  echo -e "${gl_hui}-关于流量，重启服务器将重新计算-${gl_bai}"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  cd ~
				  install nano tmux bc jq
				  check_crontab_installed
				  if [ -f ~/TG-check-notify.sh ]; then
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  else
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/TG-check-notify.sh
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  fi
				  tmux kill-session -t TG-check-notify > /dev/null 2>&1
				  tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				  crontab -l | grep -v '~/TG-check-notify.sh' | crontab - > /dev/null 2>&1
				  (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab - > /dev/null 2>&1

				  curl -sS -O ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
				  chmod +x ~/TG-SSH-check-notify.sh

				  # 添加到 ~/.profile 文件中
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-bot预警系统已启动"
				  echo -e "${gl_hui}你还可以将root目录中的TG-check-notify.sh预警文件放到其他机器上直接使用！${gl_bai}"
				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac
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



nimbus_update() {

cd ~
while true; do
	clear
	echo "更新日志"
	echo "------------------------"
	echo "全部日志: ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/CHANGELOG.md"
	echo "------------------------"

	curl -s --max-time 15 ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/CHANGELOG.md | tail -n 30
	# 只下载开头 1KB 获取版本号，避免下载整个脚本
	local sh_v_new=$(curl -s --max-time 15 -r 0-1023 ${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh | grep -o 'sh_v="[0-9.]*"' | head -1 | cut -d '"' -f 2)

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
			local country=$(curl -s --max-time 5 ipinfo.io/country)
			local download_url
			download_url="${gh_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh"

			# 备份当前脚本
			cp -f ~/nimbus.sh ~/nimbus.sh.bak 2>/dev/null

			# 下载到临时文件，校验后再替换
			local tmp_file=$(mktemp ~/nimbus_tmp.XXXXXX)
			if curl -sS --max-time 60 --fail -o "$tmp_file" "$download_url" && \
			   [ -s "$tmp_file" ] && \
			   head -1 "$tmp_file" | grep -q '^#!/bin/bash'; then
				chmod +x "$tmp_file"
				mv -f "$tmp_file" ~/nimbus.sh
				[ "$country" = "CN" ] && sed -i 's/^canshu="default"/canshu="CN"/' ~/nimbus.sh
				canshu_v6
				cp -f ~/nimbus.sh /usr/local/bin/nb > /dev/null 2>&1
				ln -sf /usr/local/bin/nb /usr/bin/nb > /dev/null 2>&1
				echo -e "${gl_lv}脚本已更新到最新版本！${gl_huang}v$sh_v_new${gl_bai}"
			else
				rm -f "$tmp_file"
				# 恢复备份
				if [ -f ~/nimbus.sh.bak ]; then
					mv -f ~/nimbus.sh.bak ~/nimbus.sh
				fi
				echo -e "${gl_hong}更新失败！下载出错或文件校验不通过，已恢复原版本${gl_bai}"
			fi
			break_end
			~/nimbus.sh
			exit
			;;
		2)
			clear
			local country=$(curl -s --max-time 5 ipinfo.io/country)
			local ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
			local cron_proxy cron_sed_cmd
			if [ "$country" = "CN" ]; then
				cron_proxy="$gh_proxy_mirror"
				cron_sed_cmd="sed -i 's/canshu=\"default\"/canshu=\"CN\"/g' ~/nimbus.sh"
			elif [ -n "$ipv6_address" ]; then
				cron_proxy="$gh_proxy_mirror"
				cron_sed_cmd="sed -i 's/canshu=\"default\"/canshu=\"V6\"/g' ~/nimbus.sh"
			else
				cron_proxy="https://"
				cron_sed_cmd=""
			fi

			# 构建健壮的自动更新命令：下载到临时文件 → 校验 → 备份 → 替换 → 恢复本地设置 → 部署
			SH_Update_task="cd ~ && tmp=\$(mktemp ~/nimbus_tmp.XXXXXX) && curl -sS --max-time 60 --fail -o \"\$tmp\" ${cron_proxy}raw.githubusercontent.com/zidou-kiyn/nimbus/main/nimbus.sh && [ -s \"\$tmp\" ] && head -1 \"\$tmp\" | grep -q '^#!/bin/bash' && cp -f ~/nimbus.sh ~/nimbus.sh.bak 2>/dev/null && chmod +x \"\$tmp\" && mv -f \"\$tmp\" ~/nimbus.sh"
			# 追加设置恢复
			if [ -n "$cron_sed_cmd" ]; then
				SH_Update_task="$SH_Update_task && $cron_sed_cmd"
			fi
			# 部署到 /usr/local/bin/nb 和 /usr/bin/nb
			SH_Update_task="$SH_Update_task; cp -f ~/nimbus.sh /usr/local/bin/nb 2>/dev/null; ln -sf /usr/local/bin/nb /usr/bin/nb 2>/dev/null"
			# 下载失败时清理临时文件
			SH_Update_task="$SH_Update_task || rm -f \"\$tmp\" 2>/dev/null"

			check_crontab_installed
			(crontab -l | grep -v "nimbus.sh") | crontab -
			(crontab -l 2>/dev/null; echo "$(shuf -i 0-59 -n 1) 2 * * * bash -c '$SH_Update_task'") | crontab -
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
echo -e "${gl_cyan}------------------------${gl_bai}"
echo -e "${gl_cyan}1.   ${gl_bai}系统信息查询"
echo -e "${gl_cyan}2.   ${gl_bai}系统更新"
echo -e "${gl_cyan}3.   ${gl_bai}系统清理"
echo -e "${gl_cyan}4.   ${gl_bai}基础工具"
echo -e "${gl_cyan}5.   ${gl_bai}BBRv3加速"
echo -e "${gl_cyan}6.   ${gl_bai}Docker管理"
echo -e "${gl_cyan}7.   ${gl_bai}测试脚本合集"
echo -e "${gl_cyan}8.   ${gl_bai}系统工具"
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
					echo "  k sshkey                  进入交互菜单"
					echo "  k sshkey \"<pubkey>\"     直接导入 SSH 公钥"
					echo "  k sshkey <url>            从 URL 导入 SSH 公钥"
					echo "  k sshkey github <user>    从 GitHub 导入 SSH 公钥"
					;;
			esac

			;;
		*)
			nb_help
			;;
	esac
fi
