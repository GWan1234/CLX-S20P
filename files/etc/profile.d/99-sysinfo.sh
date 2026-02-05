#!/bin/sh

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
SHOW_IP_PATTERN='^[ewr].*|^br.*|^lt.*|^umts.*'
TAB="	"  # 一个真实 tab

display() {
	name="$1"; val="$2"; red="$3"; min="$4"; unit="$5"; after="$6"
	printf "%s:  " "$name"

	# CPU Freq / ROOTFS 不做数值比较，固定绿色
	case "$name" in
	"CPU Freq"|"ROOTFS")
		printf "\033[0;92m%s\033[0m" "$val"
		printf "%s%s" "$unit" "$after"
		return 0
		;;
	esac

	if [ -n "$val" ] && awk "BEGIN{exit !($val >= $min)}" 2>/dev/null; then
		if awk "BEGIN{exit !($val > $red)}" 2>/dev/null; then
			printf "\033[0;91m%s\033[0m" "$val"
		else
			printf "\033[0;92m%s\033[0m" "$val"
		fi
	else
		printf "\033[0;92m%s\033[0m" "$val"
	fi
	printf "%s%s" "$unit" "$after"
}

get_ip_addresses() {
	for p in /sys/class/net/*; do
		intf="$(basename "$p")"
		echo "$intf" | grep -Eq "$SHOW_IP_PATTERN" || continue
		ip -4 addr show dev "$intf" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1
	done | xargs
}

# ---------- load / uptime ----------
Uptime="$(uptime | tr -d ',')"
load="$(echo "$Uptime" | awk -F'average: ' '{print $2}')"
load1="$(echo "$load" | awk '{print $1}')"
load_rest="$(echo "$load" | awk '{$1=""; sub(/^ /,""); print}')"
time="$(uptime | sed -n 's/.*up \([^,]*\),.*/\1/p')"

# ---------- memory ----------
mem_info="$(LC_ALL=C free -w 2>/dev/null | grep '^Mem' || LC_ALL=C free | grep '^Mem')"
memory_usage="$(printf '%s\n' "$mem_info" | awk '{printf("%.0f",(($2-($4+$6))/$2)*100)}')"
memory_total="$(printf '%s\n' "$mem_info" | awk '{printf("%d",$2/1024)}')"

# ---------- swap ----------
swap_info="$(LC_ALL=C free -k 2>/dev/null | grep '^Swap')"
swap_total="$(printf '%s\n' "$swap_info" | awk '{printf("%d",$2/1024)}')"
swap_usage="$(printf '%s\n' "$swap_info" | awk '{if($2>0) printf("%d",$3*100/$2); else printf("0")}')"

# ---------- Temp ----------
if [ -x /sbin/tempinfo ]; then
	# 优先使用 tempinfo（CPU + WiFi）
	temp_str="$(/sbin/tempinfo 2>/dev/null | tr -d '\r\n')"
else
	# 回退：直接从 sysfs 取 CPU 温度
	if [ -r /sys/class/hwmon/hwmon0/temp1_input ]; then
		temp_str="CPU: $(awk '{printf("%.1f°C",$0/1000)}' /sys/class/hwmon/hwmon0/temp1_input)"
	elif [ -r /sys/class/thermal/thermal_zone0/temp ]; then
		temp_str="CPU: $(awk '{printf("%.1f°C",$0/1000)}' /sys/class/thermal/thermal_zone0/temp)"
	else
		temp_str="CPU: N/A"
	fi
fi

# ---------- cpu freq ----------
cpu_freq="2.0 GHz"
for f in \
	/sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq \
	/sys/devices/system/cpu/cpufreq/policy0/cpuinfo_cur_freq \
	/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq \
	/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
do
	[ -r "$f" ] || continue
	khz="$(cat "$f" 2>/dev/null | tr -cd '0-9')"
	[ -n "$khz" ] && cpu_freq="$(awk -v k="$khz" 'BEGIN{printf("%.1f GHz", k/1000000)}')" && break
done

# ---------- model / arch ----------
model="$(tr -d '\000' </proc/device-tree/model 2>/dev/null)"
[ -z "$model" ] && model="$(uname -n)"
arch="$(grep -m1 -E 'model name|Processor|cpu model' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')"
[ -z "$arch" ] && arch="$(uname -m)"

# ---------- ROOTFS ----------
R="$(df -k / | tail -n1)"
root_used_mb="$(echo "$R" | awk '{printf("%.1f",$3/1024)}')"
root_total_mb="$(echo "$R" | awk '{printf("%.1f",$2/1024)}')"

# ---------- output ----------
printf " Device Model: \033[93m%s\033[0m\n" "$model"
printf " Architecture: \033[93m%s\033[0m\n" "$arch"

printf " "
display "Load Average" "$load1" "0" "0" "" " $load_rest"
printf "%sUptime: \033[92m%s\033[0m\n" "$TAB" "$time"

printf " "
display "Memory" "$memory_usage" "70" "0" "%" " of ${memory_total}MB"
printf "%s%s" "$TAB" "$TAB"
display "Swap" "$swap_usage" "80" "0" "%" " of ${swap_total}MB"
echo ""

printf " "
display "ROOTFS" "$root_used_mb" "0" "0" "MB" " / ${root_total_mb}MB"
printf "%s" "$TAB"
display "CPU Freq" "$cpu_freq" "0" "0" "" ""
echo ""

printf " "
display "Temp" "  ""$temp_str" "0" "0" "" ""
echo ""

printf " IP Addr: \033[92m%s\033[0m\n" "$(get_ip_addresses)"
echo " -----------------------------------------------------"