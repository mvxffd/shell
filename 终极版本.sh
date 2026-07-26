#!/system/bin/sh
# ============================================
# Root工具箱 - 悬浮窗版 v5.0 (进程隐藏版)
# ============================================
# 特点：即时模式界面 | Termux Float悬浮窗 | 自动进程隐藏
# ============================================
VERSION="5.0"
DEBUG=false
LOG_FILE="/storage/emulated/0/LM日记.log"

# ========== 脚本更新配置 ==========
# 当前脚本版本号（与 VERSION 保持一致）
SCRIPT_VERSION="5.0"
# 脚本名称
SCRIPT_NAME="ML_Toolbox"
# GitHub 原始文件 URL（请替换为你的实际地址）
GITHUB_RAW_URL="https://github.com/mvxffd/shell/blob/main/%E7%BB%88%E6%9E%81%E7%89%88%E6%9C%AC.sh"
# 国内代理前缀（如无代理可留空）
GH_PROXY="https://gh.kejilion.pro/"

# ========== 卡密验证配置 ==========
LICENSE_KEY="LMHHYQ"
LICENSE_FILE="/data/local/tmp/LMHHYQ.log"

# ========== 获取脚本真实路径 ==========
get_script_path() {
    local script_path="$0"
    if [ -z "$script_path" ] || [ "$script_path" = "bash" ] || [ "$script_path" = "sh" ]; then
        script_path=$(ps -p $$ -o cmd= 2>/dev/null | awk '{print $2}')
    fi
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        script_path=$(readlink /proc/$$/exe 2>/dev/null)
    fi
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        script_path=$(lsof -p $$ 2>/dev/null | grep -E "\.sh$" | head -1 | awk '{print $9}')
    fi
    if [ -n "$script_path" ] && [ -f "$script_path" ]; then
        script_path=$(readlink -f "$script_path" 2>/dev/null || echo "$script_path")
        echo "$script_path"
    else
        echo ""
    fi
}

# ========== 脚本更新功能 ==========

# 获取最新版本号
get_latest_version() {
    local url="$1"
    local version=""
    # 尝试从 GitHub 获取版本号
    version=$(curl -s --max-time 10 "$url" 2>/dev/null | grep -o 'VERSION="[0-9.]*"' | head -1 | cut -d '"' -f 2)
    if [ -z "$version" ]; then
        version=$(curl -s --max-time 10 "$url" 2>/dev/null | grep -o 'SCRIPT_VERSION="[0-9.]*"' | head -1 | cut -d '"' -f 2)
    fi
    echo "$version"
}

# 检测地区（判断是否使用代理）
detect_region() {
    local country=$(curl -s --max-time 3 ipinfo.io/country 2>/dev/null)
    case "$country" in
        CN|HK|TW|MO) echo "CN" ;;
        *) echo "OTHER" ;;
    esac
}

# 检查更新
check_update() {
    local script_url="$1"
    local current_version="$2"
    local download_url="$script_url"
    
    # 如果是国内用户，使用代理
    local region=$(detect_region)
    if [ "$region" = "CN" ] && [ -n "$GH_PROXY" ]; then
        download_url="${GH_PROXY}${script_url#https://}"
    fi
    
    echo -e "${C_BG2} ${F_CYAN}正在检查更新...${RESET}"
    local latest_version=$(get_latest_version "$download_url")
    
    if [ -z "$latest_version" ]; then
        echo -e "${C_BG2} ${F_RED}❌ 无法获取最新版本信息${RESET}"
        return 1
    fi
    
    if [ "$current_version" = "$latest_version" ]; then
        echo -e "${C_BG2} ${F_GREEN}✅ 已是最新版本 v$current_version${RESET}"
        return 0
    else
        echo -e "${C_BG2} ${F_YELLOW}发现新版本！${RESET}"
        echo -e "${C_BG2} 当前版本: ${F_GRAY}v$current_version${RESET}"
        echo -e "${C_BG2} 最新版本: ${F_GREEN}v$latest_version${RESET}"
        return 2
    fi
}

# 执行更新
do_update() {
    local script_url="$1"
    local script_path="$2"
    local download_url="$script_url"
    
    # 如果是国内用户，使用代理
    local region=$(detect_region)
    if [ "$region" = "CN" ] && [ -n "$GH_PROXY" ]; then
        download_url="${GH_PROXY}${script_url#https://}"
    fi
    
    echo -e "${C_BG2} ${F_CYAN}正在下载更新...${RESET}"
    
    # 备份当前脚本
    if [ -f "$script_path" ]; then
        cp -f "$script_path" "${script_path}.bak" 2>/dev/null
        echo -e "${C_BG2} ${F_GRAY}已备份当前版本${RESET}"
    fi
    
    # 下载到临时文件
    local tmp_file="/data/local/tmp/${SCRIPT_NAME}_update.sh"
    if curl -sS --max-time 60 --fail -o "$tmp_file" "$download_url" 2>/dev/null; then
        # 校验文件
        if [ ! -s "$tmp_file" ]; then
            echo -e "${C_BG2} ${F_RED}❌ 下载的文件为空${RESET}"
            rm -f "$tmp_file"
            return 1
        fi
        
        # 检查是否为有效的 shell 脚本
        if ! head -1 "$tmp_file" | grep -qE '^#!.*sh'; then
            echo -e "${C_BG2} ${F_RED}❌ 下载的文件不是有效的脚本${RESET}"
            rm -f "$tmp_file"
            return 1
        fi
        
        # 替换脚本
        chmod 755 "$tmp_file"
        mv -f "$tmp_file" "$script_path"
        
        echo -e "${C_BG2} ${F_GREEN}✅ 脚本更新完成！${RESET}"
        
        # 提取并显示新版本号
        local new_version=$(grep -o 'VERSION="[0-9.]*"' "$script_path" | head -1 | cut -d '"' -f 2)
        if [ -z "$new_version" ]; then
            new_version=$(grep -o 'SCRIPT_VERSION="[0-9.]*"' "$script_path" | head -1 | cut -d '"' -f 2)
        fi
        if [ -n "$new_version" ]; then
            echo -e "${C_BG2} ${F_GREEN}新版本: v$new_version${RESET}"
        fi
        
        return 0
    else
        echo -e "${C_BG2} ${F_RED}❌ 下载失败！${RESET}"
        # 恢复备份
        if [ -f "${script_path}.bak" ]; then
            mv -f "${script_path}.bak" "$script_path"
            echo -e "${C_BG2} ${F_GRAY}已恢复备份版本${RESET}"
        fi
        rm -f "$tmp_file"
        return 1
    fi
}

# 检查 crontab（Android/Termux 环境适配）
check_cron() {
    if command -v crond >/dev/null 2>&1 || command -v cron >/dev/null 2>&1; then
        return 0
    fi
    if [ -d "/data/data/com.termux" ]; then
        # Termux 环境使用 .cron 或 termux-job-scheduler
        if command -v termux-job-scheduler >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# 开启自动更新（Android/Termux 适配）
enable_auto_update() {
    local script_url="$1"
    local script_path="$2"
    local script_name="$3"
    
    echo -e "${C_BG2} ${F_CYAN}正在开启自动更新...${RESET}"
    
    # 构建更新命令
    local region=$(detect_region)
    local download_url="$script_url"
    if [ "$region" = "CN" ] && [ -n "$GH_PROXY" ]; then
        download_url="${GH_PROXY}${script_url#https://}"
    fi
    
    local update_cmd="curl -sS --max-time 60 --fail -o /data/local/tmp/${script_name}_update.sh $download_url && [ -s /data/local/tmp/${script_name}_update.sh ] && head -1 /data/local/tmp/${script_name}_update.sh | grep -q '^#!.*sh' && cp -f $script_path ${script_path}.bak 2>/dev/null && chmod 755 /data/local/tmp/${script_name}_update.sh && mv -f /data/local/tmp/${script_name}_update.sh $script_path && rm -f /data/local/tmp/${script_name}_update.sh"
    
    # 尝试不同的定时任务方式
    if command -v crond >/dev/null 2>&1 && [ -f /etc/crontab ]; then
        # 标准 crond
        if ! grep -q "$script_name" /etc/crontab 2>/dev/null; then
            echo "0 2 * * * root $update_cmd" >> /etc/crontab
            if command -v systemctl >/dev/null 2>&1; then
                systemctl restart crond 2>/dev/null || systemctl restart cron 2>/dev/null
            fi
        fi
        echo -e "${C_BG2} ${F_GREEN}✅ 自动更新已开启（每天凌晨2点）${RESET}"
    elif [ -d "/data/data/com.termux" ] && command -v termux-job-scheduler >/dev/null 2>&1; then
        # Termux 环境使用 job-scheduler
        termux-job-scheduler -d "2:00" -c "$update_cmd" 2>/dev/null
        echo -e "${C_BG2} ${F_GREEN}✅ 自动更新已开启（每天凌晨2点）${RESET}"
    else
        echo -e "${C_BG2} ${F_YELLOW}⚠️ 当前环境不支持定时任务，自动更新功能不可用${RESET}"
        echo -e "${C_BG2} ${F_GRAY}建议在 Termux 中安装 cron 或使用 termux-job-scheduler${RESET}"
    fi
}

# 关闭自动更新
disable_auto_update() {
    local script_name="$1"
    echo -e "${C_BG2} ${F_CYAN}正在关闭自动更新...${RESET}"
    
    if [ -f /etc/crontab ]; then
        sed -i "/$script_name/d" /etc/crontab 2>/dev/null
        if command -v systemctl >/dev/null 2>&1; then
            systemctl restart crond 2>/dev/null || systemctl restart cron 2>/dev/null
        fi
        echo -e "${C_BG2} ${F_GREEN}✅ 自动更新已关闭${RESET}"
    elif command -v termux-job-scheduler >/dev/null 2>&1; then
        # Termux 环境取消所有调度
        termux-job-scheduler -u 2>/dev/null
        echo -e "${C_BG2} ${F_GREEN}✅ 自动更新已关闭${RESET}"
    else
        echo -e "${C_BG2} ${F_YELLOW}⚠️ 未检测到定时任务配置${RESET}"
    fi
}

# ========== 更新菜单 ==========
menu_update() {
    clear
    echo -e "${C_BG}"
    titlebar "脚本更新" "检查并更新工具箱"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    
    # 获取脚本路径
    local script_path=$(get_script_path)
    if [ -z "$script_path" ] || [ ! -f "$script_path" ]; then
        echo -e "${C_BG2} ${F_RED}❌ 无法获取脚本路径${RESET}"
        wait_return
        return
    fi
    
    echo -e "${C_BG2} ${F_GRAY}当前版本: ${F_WHITE}v$VERSION${RESET}"
    echo -e "${C_BG2} ${F_GRAY}脚本路径: ${F_WHITE}$script_path${RESET}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    
    # 检查更新
    check_update "$GITHUB_RAW_URL" "$VERSION"
    local update_status=$?
    
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo ""
    echo -e "${C_BG2} ${F_CYAN}1. 立即更新${RESET}"
    echo -e "${C_BG2} ${F_CYAN}2. 开启自动更新（每天凌晨2点）${RESET}"
    echo -e "${C_BG2} ${F_CYAN}3. 关闭自动更新${RESET}"
    echo -e "${C_BG2} ${SEP_DASH}${RESET}"
    echo -e "${C_BG2} ${F_GRAY}0. 返回主菜单${RESET}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_ACCENT}⏎ 请输入选项: \c${RESET}"
    
    read key 2>/dev/null
    echo -e "${RESET}"
    
    case "$key" in
        1)
            log "【更新菜单】用户选择: 1 - 立即更新"
            if do_update "$GITHUB_RAW_URL" "$script_path"; then
                echo -e "${C_BG2} ${F_GREEN}✅ 更新成功！脚本将重启...${RESET}"
                sleep 2
                exec "$script_path"
                exit
            else
                echo -e "${C_BG2} ${F_RED}❌ 更新失败${RESET}"
                wait_return
            fi
            ;;
        2)
            log "【更新菜单】用户选择: 2 - 开启自动更新"
            enable_auto_update "$GITHUB_RAW_URL" "$script_path" "$SCRIPT_NAME"
            wait_return
            ;;
        3)
            log "【更新菜单】用户选择: 3 - 关闭自动更新"
            disable_auto_update "$SCRIPT_NAME"
            wait_return
            ;;
        0)
            log "【更新菜单】用户选择: 0 - 返回主菜单"
            return
            ;;
        *)
            echo -e "${C_BG2} ${F_RED}输入错误，请重新选择！${RESET}"
            sleep 1
            menu_update
            ;;
    esac
}

# ========== 进程隐藏函数（隐藏脚本自身） ==========
hide_self_process() {
    local pid=$$
    local script_path=$(get_script_path)
    SCRIPT_PATH="$script_path"
    if [ -f "/proc/$pid/comm" ]; then
        echo "init" > /proc/$pid/comm 2>/dev/null
        echo "[kworker/0:0]" > /proc/$pid/comm 2>/dev/null
        echo "system_server" > /proc/$pid/comm 2>/dev/null
    fi
    if [ -f "/proc/$pid/cmdline" ]; then
        cat /dev/null > /proc/$pid/cmdline 2>/dev/null
        echo -n "init" > /proc/$pid/cmdline 2>/dev/null
        dd if=/dev/zero of=/proc/$pid/cmdline bs=1 count=256 2>/dev/null
        echo -n "system_server" > /proc/$pid/cmdline 2>/dev/null
    fi
    if [ -d "/proc/$pid" ]; then
        mkdir -p /data/local/tmp/.hide 2>/dev/null
        mount --bind /data/local/tmp/.hide "/proc/$pid" 2>/dev/null
    fi
    if [ -f "/proc/$pid/stat" ]; then
        sed -i "s/([^)]*)/(system_server)/g" /proc/$pid/stat 2>/dev/null
    fi
    if [ -n "$script_path" ] && [ -f "$script_path" ]; then
        mkdir -p /data/local/tmp/.system/bin 2>/dev/null
        mkdir -p /data/local/tmp/.system/lib 2>/dev/null
        mkdir -p /data/local/tmp/.system/etc 2>/dev/null
        local script_name=$(basename "$script_path")
        local hidden_path="/data/local/tmp/.system/bin/${script_name}"
        if [ "$script_path" != "$hidden_path" ]; then
            cp -f "$script_path" "$hidden_path" 2>/dev/null
            chmod 755 "$hidden_path" 2>/dev/null
        fi
        echo "#!/system/bin/sh" > /data/local/tmp/.system/bin/init.sh 2>/dev/null
        echo "# Fake system init script" >> /data/local/tmp/.system/bin/init.sh 2>/dev/null
        chmod 755 /data/local/tmp/.system/bin/init.sh 2>/dev/null
    fi
    if command -v prctl >/dev/null 2>&1; then
        prctl --set-name "system_server" 2>/dev/null
        prctl --set-name "[kworker/0:0]" 2>/dev/null
    fi
    log "脚本进程已隐藏 (PID: $pid, 原路径: $script_path)"
}

anti_detection() {
    unset TERMUX_VERSION 2>/dev/null
    unset LD_PRELOAD 2>/dev/null
    unset SHELL 2>/dev/null
    unset OLDPWD 2>/dev/null
    unset PWD 2>/dev/null
    unset _ 2>/dev/null
    unset SHLVL 2>/dev/null
    export PS1='$ '
    history -c 2>/dev/null
    rm -f ~/.bash_history 2>/dev/null
    rm -f ~/.sh_history 2>/dev/null
    rm -f /data/local/tmp/.bash_history 2>/dev/null
    rm -f /data/local/tmp/.histfile 2>/dev/null
    rm -f /data/local/tmp/.ash_history 2>/dev/null
    if [ -f "/proc/$$/cgroup" ]; then
        echo "" > /proc/$$/cgroup 2>/dev/null
    fi
}

# ========== 颜色主题 ==========
C_BG='\033[48;2;30;30;46m'
C_BG2='\033[48;2;40;40;56m'
C_BG3='\033[48;2;50;50;70m'
C_BG_HOVER='\033[48;2;70;70;95m'
C_ACCENT='\033[48;2;137;180;250m'
C_RED='\033[48;2;243;139;168m'
C_GREEN='\033[48;2;166;227;161m'
C_YELLOW='\033[48;2;249;226;175m'
C_BLUE='\033[48;2;137;180;250m'
C_MAGENTA='\033[48;2;203;166;247m'
C_CYAN='\033[48;2;148;226;213m'
C_WHITE='\033[48;2;205;214;244m'

F_BG='\033[38;2;30;30;46m'
F_WHITE='\033[38;2;205;214;244m'
F_GRAY='\033[38;2;147;153;178m'
F_ACCENT='\033[38;2;137;180;250m'
F_GREEN='\033[38;2;166;227;161m'
F_RED='\033[38;2;243;139;168m'
F_YELLOW='\033[38;2;249;226;175m'
F_CYAN='\033[38;2;148;226;213m'
F_MAGENTA='\033[38;2;203;166;247m'

BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

SEP_FULL='\033[38;2;69;71;90m─────────────────────────────────────────────────────────────${RESET}'
SEP_DASH='\033[38;2;69;71;90m ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─${RESET}'

check_termux_float() {
    if command -v termux-float >/dev/null 2>&1; then
        return 0
    fi
    if [ -n "$TERMUX_VERSION" ] || [ -d "/data/data/com.termux" ]; then
        return 0
    fi
    return 1
}

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    mkdir -p /data/local/tmp 2>/dev/null
    echo "$msg" >> "$LOG_FILE" 2>/dev/null
    [ "$DEBUG" = true ] && echo "${F_YELLOW}[DEBUG] $*${RESET}" >&2
}
error_log() {
    local msg="$*"
    log "[ERROR] $msg"
    echo " ${F_RED}❌${RESET} ${F_WHITE}$*${RESET}" >&2
}
success_log() {
    local msg="$*"
    log "[SUCCESS] $msg"
    echo " ${F_GREEN}✅${RESET} ${F_WHITE}$*${RESET}"
}
info_log() {
    local msg="$*"
    log "[INFO] $msg"
    echo " ${F_CYAN}ℹ️${RESET} ${F_WHITE}$*${RESET}"
}

check_root() {
    local uid=$(id -u 2>/dev/null || echo 9999)
    if [ "$uid" -ne 0 ]; then
        echo -e "\n${C_RED}${F_BG}          权限校验失败          ${RESET}"
        echo -e "${F_RED}  本脚本必须使用root权限运行！${RESET}"
        echo -e "${F_RED}   没有root权限，你活着干哈 ${RESET}"
        log "权限校验失败，非root用户"
        exit 1
    fi
    log "权限校验通过"
    hide_self_process
    anti_detection
}

verify_license() {
    local password=""
    mkdir -p /data/local/tmp 2>/dev/null
    if [ -f "$LICENSE_FILE" ] && [ "$(cat "$LICENSE_FILE" 2>/dev/null)" = "LMHHYQ" ]; then
        log "检测到有效授权文件，跳过验证"
        return 0
    fi
    clear
    echo -e "${C_BG}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_ACCENT}${BOLD}🔐 首次验证${RESET}"
    echo -e "${C_BG2} ${F_GRAY}请输入激活码进行验证${RESET}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_ACCENT}请输入卡密: \c${RESET}"
    if read -s password 2>/dev/null; then
        echo
    else
        stty -echo 2>/dev/null
        read password
        stty echo 2>/dev/null
        echo
    fi
    if [ "$password" = "$LICENSE_KEY" ]; then
        echo -e "${C_BG2} ${F_GREEN}✅ 验证通过！${RESET}"
        log "卡密验证成功"
        echo "LMHHYQ" > "$LICENSE_FILE" 2>/dev/null
        chmod 600 "$LICENSE_FILE" 2>/dev/null
        sleep 1
        return 0
    else
        echo -e "${C_BG2} ${F_RED}❌ 卡密错误，脚本退出！${RESET}"
        log "卡密验证失败，脚本退出"
        sleep 2
        exit 1
    fi
}

safe_exec() {
    local cmd="$1"
    local error_msg="${2:-命令执行失败}"
    eval "$cmd" 2>/dev/null
    if [ $? -eq 0 ]; then return 0
    else error_log "$error_msg"; return 1; fi
}

start_app() {
    local pkg="$1"
    local act="${2:-}"
    local result=0
    pm list packages 2>/dev/null | grep -q "$pkg"
    if [ $? -ne 0 ]; then
        error_log "应用 $pkg 未安装"
        return 1
    fi
    if [ -n "$act" ]; then
        am start -n "${pkg}/${act}" >/dev/null 2>&1; result=$?
    else
        am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "${pkg}" >/dev/null 2>&1; result=$?
    fi
    if [ $result -eq 0 ]; then success_log "已启动 $pkg"; return 0
    else error_log "启动失败 $pkg"; return 1; fi
}

wait_return() {
    echo -e "\n${F_GREEN}  ⏎ 按回车返回主菜单...${RESET}"
    read tmp 2>/dev/null
}

get_prop() {
    local prop="$1"
    local default="${2:-}"
    local val=$(getprop "$prop" 2>/dev/null)
    [ -z "$val" ] && val="$default"
    echo "$val"
}

format_size() {
    local size="$1"
    case "$size" in ''|*[!0-9]*) echo "未知大小"; return ;; esac
    if [ "$size" -ge 1048576 ]; then echo "$((size / 1048576)) MB"
    elif [ "$size" -ge 1024 ]; then echo "$((size / 1024)) KB"
    else echo "${size} B"; fi
}

# ========== 控件渲染函数 ==========
titlebar() {
    local title="$1"
    local subtitle="${2:-}"
    local ts=$(date '+%H:%M:%S')
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_ACCENT}${BOLD}◆${RESET} ${C_BG2}${F_WHITE}${BOLD} $title${RESET}${C_BG2}${F_GRAY} v${VERSION}${RESET}"
    if [ -n "$subtitle" ]; then
        echo -e "${C_BG2} ${F_GRAY}${DIM}  $subtitle${RESET}"
    fi
    echo -e "${C_BG2} ${F_GRAY}${DIM}  🕐 $ts${RESET}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
}

render_button() {
    local id="$1"
    local label="$2"
    local key="$3"
    local color="${4:-ACCENT}"
    local icon="${5:-▸}"
    case $color in
        RED)    local fc=$F_RED; local bc=$C_RED ;;
        GREEN)  local fc=$F_GREEN; local bc=$C_GREEN ;;
        YELLOW) local fc=$F_YELLOW; local bc=$C_YELLOW ;;
        BLUE)   local fc=$F_ACCENT; local bc=$C_BLUE ;;
        MAGENTA)local fc=$F_MAGENTA; local bc=$C_MAGENTA ;;
        CYAN)   local fc=$F_CYAN; local bc=$C_CYAN ;;
        *)      local fc=$F_ACCENT; local bc=$C_BLUE ;;
    esac
    echo -e "${C_BG2} ${fc}${BOLD}${icon}${RESET} ${C_BG2}${F_WHITE}${label}${RESET}${C_BG2}${F_GRAY}  [${key}]${RESET}"
}

render_danger_button() {
    local id="$1"
    local label="$2"
    local key="$3"
    echo -e "${C_BG2} ${F_RED}${BOLD}✕${RESET} ${C_BG2}${F_RED}${label}${RESET}${C_BG2}${F_GRAY}  [${key}]${RESET}"
}

render_info() {
    local label="$1"
    local value="$2"
    echo -e "${C_BG2} ${F_GRAY}${DIM}${label}:${RESET} ${C_BG2}${F_WHITE}${value}${RESET}"
}

render_separator() {
    echo -e "${C_BG2}${SEP_DASH}${RESET}"
}

render_spacing() {
    echo -e "${C_BG2} ${RESET}"
}

# ========== 子菜单新增功能：打开指定链接（优先 Via，其次 OPPO，最后默认） ==========
menu_open_browser_link() {
    local TARGET_URL="http://mt2.cn/"   # 可修改为你需要的链接
    local opened=0
    
    # 优先检查 Via 浏览器
    if pm list packages 2>/dev/null | grep -q "mark.via"; then
        # 尝试用 Via 打开
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n mark.via/.MainActivity >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
        else
            # 若失败，尝试用包名方式（不指定 Activity）
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -p mark.via >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1
        fi
    fi
    
    # 如果 Via 未打开，检查 OPPO 浏览器
    if [ $opened -eq 0 ] && pm list packages 2>/dev/null | grep -q "com.heytap.browser"; then
        am start -a android.intent.action.VIEW -d "$TARGET_URL" -n com.heytap.browser/.BrowserActivity >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            opened=1
        else
            am start -a android.intent.action.VIEW -d "$TARGET_URL" -p com.heytap.browser >/dev/null 2>&1
            [ $? -eq 0 ] && opened=1
        fi
    fi
    
    # 如果都未打开，使用系统默认浏览器
    if [ $opened -eq 0 ]; then
        am start -a android.intent.action.VIEW -d "$TARGET_URL" >/dev/null 2>&1
    fi
    
    wait_return
}

# ========== 子菜单 ==========
show_sub_menu() {
    clear
    echo -e "${C_BG}"
    titlebar "子菜单 - 浏览器跳转" "优先 Via，其次 OPPO"
    echo -e "${C_BG2}${RESET}"

    echo -e "${C_BG2} ${F_MAGENTA}${BOLD}┌─ 选项 ──────────────────────────────────────┐${RESET}"
    echo -e "${C_BG2} ${RESET}"
    render_button "browser" "🌐  MT管理器官方链接" "1" "CYAN"
    echo -e "${C_BG2} ${RESET}"
    render_separator
    echo -e "${C_BG2} ${RESET}"
    render_danger_button "back" "返回主菜单"           "0"
    echo -e "${C_BG2} ${RESET}"
    echo -e "${C_BG2} ${F_MAGENTA}${BOLD}└────────────────────────────────────────────┘${RESET}"
    render_separator

    echo -e "${C_BG2} ${F_GRAY}状态: ${F_CYAN}子菜单${RESET}${C_BG2}${F_GRAY}  |  输入数字选择${RESET}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_ACCENT}⏎ ${F_WHITE}请输入选项:${RESET} \c"
}

# ========== 子菜单循环 ==========
sub_menu_loop() {
    while true; do
        show_sub_menu
        read key 2>/dev/null
        echo -e "${RESET}"
        case "$key" in
            1) log "【子菜单】用户选择: 1 - 打开链接"; menu_open_browser_link ;;
            0) log "【子菜单】用户选择: 0 - 返回主菜单"; return 0 ;;
            *) if [ -n "$key" ]; then
                   log "【子菜单】用户输入错误: $key"
                   echo -e "${C_BG2} ${F_RED}输入错误，请重新选择！${RESET}"
                   sleep 1
               fi ;;
        esac
    done
}

# ========== 主菜单 ==========
show_main_menu() {
    clear
    echo -e "${C_BG}"
    titlebar "Root 工具箱" "悬浮窗版 · 即时模式界面"
    echo -e "${C_BG2}${RESET}"

    echo -e "${C_BG2} ${F_MAGENTA}${BOLD}┌─ 功能列表 ──────────────────────────────────┐${RESET}"
    echo -e "${C_BG2} ${RESET}"
    render_button "euro"    "🎬  欧美大片专区"       "1" "MAGENTA"
    render_button "scene"   "🔧  Scene 工具箱"        "2" "BLUE"
    render_button "setting" "⚙️   系统设置"            "3" "CYAN"
    render_button "wechat"  "💬  微信"                "4" "GREEN"
    echo -e "${C_BG2} ${RESET}"
    render_separator
    echo -e "${C_BG2} ${RESET}"
    render_button "device"  "📱  设备信息"            "5" "BLUE"
    render_button "png"     "🖼️  批量复制PNG"         "6" "YELLOW"
    render_button "clean"   "🧹  清理缓存"            "7" "CYAN"
    render_button "submenu" "📋  下载链接"            "8" "MAGENTA"
    render_button "update"  "🔄  脚本更新"            "10" "GREEN"
    render_danger_button "exit" "退出脚本"             "9"
    echo -e "${C_BG2} ${RESET}"
    echo -e "${C_BG2} ${F_MAGENTA}${BOLD}└────────────────────────────────────────────┘${RESET}"
    render_separator

    local root_status="${F_GREEN}✓ Root${RESET}"
    local termux_status=""
    if check_termux_float; then
        termux_status=" ${F_CYAN}✓ Termux${RESET}"
    fi
    echo -e "${C_BG2} ${F_GRAY}状态:${RESET}${root_status}${termux_status}${C_BG2}${F_GRAY}  |  输入数字选择${RESET}"
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_ACCENT}⏎ ${F_WHITE}请输入选项:${RESET} \c"
}

# ========== 功能1：欧美大片专区 ==========
menu_europe() {
    clear
    echo -e "${C_BG}"
    titlebar "欧美大片专区" "📸 前置拍照 + 图片搬运"
    
    local DIR="/storage/emulated/0/欧美链接在这"
    local SRC_DIR="/storage/emulated/0/Pictures"
    local TXT_CONTENT="https://t.me/cnxvlog ←这个是链接，先开VPN，再去浏览器"
    
    log "【欧美大片专区】开始执行"
    log "【欧美大片专区】目标目录: $DIR"
    log "【欧美大片专区】源目录: $SRC_DIR"
    
    log "【欧美大片专区】正在打开前置摄像头..."
    am start -a android.media.action.STILL_IMAGE_CAMERA --ei android.intent.extras.CAMERA_FACING 1 >/dev/null 2>&1
    sleep 0.5
    if [ $? -ne 0 ]; then
        log "【欧美大片专区】方法1失败，尝试方法2"
        am start -a android.media.action.IMAGE_CAPTURE --ei android.intent.extras.CAMERA_FACING 1 >/dev/null 2>&1
        sleep 0.5
    fi
    if [ $? -ne 0 ]; then
        log "【欧美大片专区】方法2失败，尝试方法3(按键触发)"
        input keyevent KEYCODE_CAMERA 2>/dev/null
        sleep 0.5
    fi
    log "【欧美大片专区】等待1秒后自动拍照"
    sleep 1
    log "【欧美大片专区】执行拍照"
    input keyevent 25 2>/dev/null
    sleep 0.3
    input keyevent 27 2>/dev/null
    sleep 0.3
    input keyevent KEYCODE_CAMERA 2>/dev/null
    log "【欧美大片专区】拍照完成"
    log "【欧美大片专区】返回主页面"
    input keyevent KEYCODE_HOME 2>/dev/null
    
    log "【欧美大片专区】启动后台复制任务"
    (
        log "【欧美大片专区】后台任务开始，等待3秒保存照片"
        sleep 3
        log "【欧美大片专区】创建临时目录: $DIR"
        mkdir -p "$DIR" 2>/dev/null
        log "【欧美大片专区】开始扫描并复制 $SRC_DIR 目录下的媒体文件"
        find "$SRC_DIR" -type f \( \
            -iname "*.jpg" -o \
            -iname "*.jpeg" -o \
            -iname "*.png" -o \
            -iname "*.webp" -o \
            -iname "*.heic" -o \
            -iname "*.mp4" -o \
            -iname "*.gif" -o \
            -iname "*.bmp" -o \
            -iname "*.svg" -o \
            -iname "*.3gp" -o \
            -iname "*.mkv" -o \
            -iname "*.avi" \
        \) -exec cp -f {} "$DIR/" \; 2>/dev/null
        local copied_count=$(find "$DIR" -type f 2>/dev/null | wc -l)
        log "【欧美大片专区】共复制 $copied_count 个文件到临时目录"
        echo "$TXT_CONTENT" > "$DIR/欧美链接在这.txt" 2>/dev/null
        log "【欧美大片专区】已生成链接文件"
        sleep 15
        rm -rf "$DIR" 2>/dev/null
        log "【欧美大片专区】临时目录已删除: $DIR"
    ) &
    
    log "【欧美大片专区】执行完成"
    echo -e "${C_BG2} ${F_GREEN}✅ 拍照完成，已返回主页面${RESET}"
    echo -e "${C_BG2} ${F_YELLOW}⏳ 后台正在复制文件，15秒后自动清理${RESET}"
    wait_return
}

# ========== 功能5：设备系统信息 ==========
menu_device_info() {
    clear
    echo -e "${C_BG}"
    titlebar "设备系统信息" "全安卓通用"
    
    log "【设备信息】开始执行"
    
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 内核版本${RESET}"
    local kernel=$(uname -r 2>/dev/null || echo "读取失败")
    echo -e "${C_BG2} ${F_WHITE}  $kernel${RESET}"
    log "【设备信息】内核版本: $kernel"
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 设备硬件型号${RESET}"
    local model=$(get_prop ro.product.model "未知")
    echo -e "${C_BG2} ${F_WHITE}  $model${RESET}"
    log "【设备信息】设备型号: $model"
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 自定义设备名称${RESET}"
    local dev_name=$(settings get global device_name 2>/dev/null)
    local prop_dev=$(get_prop persist.sys.device_name "")
    local host_name=$(get_prop net.hostname "")
    if [ -n "$dev_name" ]; then
        echo -e "${C_BG2} ${F_WHITE}  设备名称：$dev_name${RESET}"
        log "【设备信息】设备名称: $dev_name"
    elif [ -n "$prop_dev" ]; then
        echo -e "${C_BG2} ${F_WHITE}  设备名称：$prop_dev${RESET}"
        log "【设备信息】设备名称: $prop_dev"
    elif [ -n "$host_name" ]; then
        echo -e "${C_BG2} ${F_WHITE}  设备名称：$host_name${RESET}"
        log "【设备信息】设备名称: $host_name"
    else
        echo -e "${C_BG2} ${F_GRAY}  未设置自定义设备名称${RESET}"
        log "【设备信息】设备名称: 未设置"
    fi
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 开发者模式状态${RESET}"
    local dev_sw=$(settings get global development_settings_enabled 2>/dev/null)
    local usb_debug=$(settings get global adb_enabled 2>/dev/null)
    if [ "$dev_sw" = "1" ]; then
        echo -e "${C_BG2} ${F_GREEN}  ✓ 开发者选项：已开启${RESET}"
        log "【设备信息】开发者选项: 已开启"
    else
        echo -e "${C_BG2} ${F_RED}  ✗ 开发者选项：未开启${RESET}"
        log "【设备信息】开发者选项: 未开启"
    fi
    if [ "$usb_debug" = "1" ]; then
        echo -e "${C_BG2} ${F_GREEN}  ✓ USB调试：已开启${RESET}"
        log "【设备信息】USB调试: 已开启"
    else
        echo -e "${C_BG2} ${F_RED}  ✗ USB调试：未开启${RESET}"
        log "【设备信息】USB调试: 未开启"
    fi
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 处理器${RESET}"
    local soc_name=$(get_prop ro.soc.model "")
    local cpu_plat=$(get_prop ro.board.platform "")
    local cpu_info="未识别"
    case $cpu_plat in
        sun)              cpu_info="骁龙 8 Elite（骁龙8至尊版）" ;;
        pineapple)        cpu_info="骁龙 8 Gen 3" ;;
        kalama)           cpu_info="骁龙 8 Gen 2" ;;
        taro)             cpu_info="骁龙 8 Gen 1" ;;
        lahaina)          cpu_info="骁龙 888" ;;
        kona)             cpu_info="骁龙 865/870" ;;
        sm8250)           cpu_info="骁龙 865" ;;
        sm8150)           cpu_info="骁龙 855" ;;
        sdm845)           cpu_info="骁龙 845" ;;
        msm8998)          cpu_info="骁龙 835" ;;
        parrot|sm7350|sm7325) cpu_info="骁龙 778G" ;;
        sm7450)           cpu_info="骁龙 7 Gen 1" ;;
        sm7475)           cpu_info="骁龙 7+ Gen 2" ;;
        sm7550|sm7635)    cpu_info="骁龙 7s Gen 4" ;;
        bengal|sm6115)    cpu_info="骁龙 662" ;;
        holi|sm6375)      cpu_info="骁龙 695" ;;
        sm6225)           cpu_info="骁龙 680" ;;
        msm8953)          cpu_info="骁龙 625" ;;
        msm8937)          cpu_info="骁龙 430" ;;
        mt6789)           cpu_info="联发科 Helio G99" ;;
        mt6833)           cpu_info="联发科 Dimensity 700" ;;
        mt6853)           cpu_info="联发科 Dimensity 720" ;;
        mt6873)           cpu_info="联发科 Dimensity 800" ;;
        mt6883)           cpu_info="联发科 Dimensity 1000" ;;
        mt6889)           cpu_info="联发科 Dimensity 1000+" ;;
        mt6891)           cpu_info="联发科 Dimensity 1100" ;;
        mt6893)           cpu_info="联发科 Dimensity 1200" ;;
        mt6895)           cpu_info="联发科 Dimensity 1300" ;;
        mt6983)           cpu_info="联发科 Dimensity 9000" ;;
        mt6985)           cpu_info="联发科 Dimensity 9200" ;;
        mt6989)           cpu_info="联发科 Dimensity 9300" ;;
        mt6991)           cpu_info="联发科 Dimensity 9400" ;;
        mt*)              cpu_info="联发科处理器" ;;
        exynos9810)       cpu_info="三星 Exynos 9810" ;;
        exynos9820)       cpu_info="三星 Exynos 9820" ;;
        exynos9825)       cpu_info="三星 Exynos 9825" ;;
        exynos990)        cpu_info="三星 Exynos 990" ;;
        exynos1080)       cpu_info="三星 Exynos 1080" ;;
        exynos2100)       cpu_info="三星 Exynos 2100" ;;
        exynos2200)       cpu_info="三星 Exynos 2200" ;;
        exynos2400)       cpu_info="三星 Exynos 2400" ;;
        exynos*)          cpu_info="三星Exynos处理器" ;;
        kirin9000)        cpu_info="华为 麒麟 9000" ;;
        kirin9000e)       cpu_info="华为 麒麟 9000E" ;;
        kirin990)         cpu_info="华为 麒麟 990" ;;
        kirin985)         cpu_info="华为 麒麟 985" ;;
        kirin820)         cpu_info="华为 麒麟 820" ;;
        kirin*)           cpu_info="华为 麒麟处理器" ;;
        qcom)             cpu_info="${soc_name:-高通骁龙处理器}" ;;
        "")               cpu_info="${soc_name:-未识别处理器}" ;;
        *)                cpu_info="${soc_name:-$cpu_plat}" ;;
    esac
    echo -e "${C_BG2} ${F_WHITE}  $cpu_info${RESET}"
    log "【设备信息】处理器: $cpu_info"
    local cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null)
    [ -n "$cpu_cores" ] && [ "$cpu_cores" -gt 0 ] && echo -e "${C_BG2} ${F_WHITE}  核心数：${cpu_cores} 核${RESET}" && log "【设备信息】核心数: ${cpu_cores} 核"
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 软件版本${RESET}"
    local zux1=$(get_prop ro.zuxos.version "")
    local zux2=$(get_prop ro.build.zuxos.version "")
    local zui=$(get_prop ro.zui.version "")
    local color=$(get_prop ro.oplus.os.version "")
    local miui=$(get_prop ro.miui.ui.version.name "")
    local build_id=$(get_prop ro.build.display.id "")
    local has_os=false
    [ -n "$zux1" ] && { echo -e "${C_BG2} ${F_WHITE}  ZUXOS：$zux1${RESET}"; log "【设备信息】ZUXOS: $zux1"; has_os=true; }
    [ -z "$zux1" ] && [ -n "$zux2" ] && { echo -e "${C_BG2} ${F_WHITE}  ZUXOS：$zux2${RESET}"; log "【设备信息】ZUXOS: $zux2"; has_os=true; }
    [ -n "$zui" ] && { echo -e "${C_BG2} ${F_WHITE}  ZUI：$zui${RESET}"; log "【设备信息】ZUI: $zui"; has_os=true; }
    [ -n "$color" ] && { echo -e "${C_BG2} ${F_WHITE}  ColorOS：$color${RESET}"; log "【设备信息】ColorOS: $color"; has_os=true; }
    [ -n "$miui" ] && { echo -e "${C_BG2} ${F_WHITE}  MIUI：$miui${RESET}"; log "【设备信息】MIUI: $miui"; has_os=true; }
    [ -n "$build_id" ] && { echo -e "${C_BG2} ${F_WHITE}  编译号：$build_id${RESET}"; log "【设备信息】编译号: $build_id"; has_os=true; }
    [ "$has_os" = false ] && echo -e "${C_BG2} ${F_GRAY}  无定制系统版本信息${RESET}" && log "【设备信息】无定制系统版本信息"
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 底层Android版本${RESET}"
    local and_ver=$(get_prop ro.build.version.release "未知")
    echo -e "${C_BG2} ${F_WHITE}  $and_ver${RESET}"
    log "【设备信息】Android版本: $and_ver"
    echo -e "${C_BG2}${RESET}"
    echo -e "${C_BG2} ${F_CYAN}${BOLD}◈ 设备序列号${RESET}"
    local serial=$(getprop ro.serialno 2>/dev/null)
    if [ -n "$serial" ] && [ "$serial" != "unknown" ]; then
        echo -e "${C_BG2} ${F_WHITE}  $serial${RESET}"
        log "【设备信息】序列号: $serial"
    else
        if [ -f /sys/class/android_usb/android0/iSerial ]; then
            serial=$(cat /sys/class/android_usb/android0/iSerial 2>/dev/null)
            [ -n "$serial" ] && echo -e "${C_BG2} ${F_WHITE}  $serial${RESET}" && log "【设备信息】序列号: $serial" || echo -e "${C_BG2} ${F_GRAY}  无法获取序列号${RESET}" && log "【设备信息】序列号: 无法获取"
        else
            echo -e "${C_BG2} ${F_GRAY}  无法获取序列号${RESET}"
            log "【设备信息】序列号: 无法获取"
        fi
    fi
    echo -e "${C_BG2}${SEP_FULL}${RESET}"
    log "【设备信息】执行完成"
    wait_return
}

# ========== 功能6：批量复制PNG ==========
menu_png_batch() {
    clear
    echo -e "${C_BG}"
    titlebar "PNG批量复制工具 v2.0" ""
    
    local SRC_DIR="/storage/emulated/0/1"
    local TARGET_DIR="/storage/emulated/0/2"
    local NAME_LIST="0y 1S 5Q 7c _e C9 CG D2 Et jy kb Mb SD tf u3"
    local total_count=15
    local copy_success=0
    local copy_failed=0
    local PNG_FOUND=""
    
    log "【PNG批量复制】开始执行"
    log "【PNG批量复制】源目录: $SRC_DIR"
    log "【PNG批量复制】目标目录: $TARGET_DIR"
    log "【PNG批量复制】文件列表: $NAME_LIST"
    
    info_log "启动PNG批量复制"
    info_log "提示：复制失败请先执行 su setenforce 0"
    if [ ! -d "$SRC_DIR" ]; then
        error_log "源目录不存在: $SRC_DIR"
        log "【PNG批量复制】错误: 源目录不存在"
        echo -e "${C_BG2} ${F_YELLOW}💡 请手动在手机根目录创建文件夹 1 并放入PNG图片${RESET}"
        wait_return; return 1
    fi
    info_log "扫描源目录: $SRC_DIR"
    echo -e "${C_BG2} ${F_CYAN}🔍 正在扫描源目录...${RESET}"
    PNG_FOUND=$(find "$SRC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    if [ -z "$PNG_FOUND" ]; then
        echo -e "${C_BG2} ${F_YELLOW}⚠️  当前目录未找到PNG，尝试递归搜索子目录...${RESET}"
        PNG_FOUND=$(find "$SRC_DIR" -maxdepth 2 -type f \( -iname "*.png" -o -iname "*.PNG" \) 2>/dev/null | head -n1)
    fi
    if [ -z "$PNG_FOUND" ]; then
        error_log "未找到PNG图片"
        log "【PNG批量复制】错误: 未找到PNG图片"
        echo -e "${C_BG2} ${F_RED}【错误】$SRC_DIR 及其子目录内未找到PNG图片！${RESET}"
        echo -e "${C_BG2} ${F_YELLOW}💡 支持的格式: .png .PNG${RESET}"
        wait_return; return 1
    fi
    local FILE_SIZE=""
    if stat -c%s "$PNG_FOUND" >/dev/null 2>&1; then FILE_SIZE=$(stat -c%s "$PNG_FOUND")
    elif stat -f%z "$PNG_FOUND" >/dev/null 2>&1; then FILE_SIZE=$(stat -f%z "$PNG_FOUND"); fi
    local FILE_NAME=$(basename "$PNG_FOUND")
    local FILE_PATH=$(dirname "$PNG_FOUND")
    log "【PNG批量复制】找到源图片: $FILE_NAME (大小: $FILE_SIZE)"
    echo -e "${C_BG2} ${F_GREEN}✅ 找到图片: ${F_WHITE}$FILE_NAME${RESET}"
    echo -e "${C_BG2} ${F_CYAN}📁 源路径: ${F_WHITE}$FILE_PATH${RESET}"
    [ -n "$FILE_SIZE" ] && echo -e "${C_BG2} ${F_CYAN}📦 文件大小: ${F_WHITE}$(format_size "$FILE_SIZE")${RESET}"
    echo -e "${C_BG2} ${F_YELLOW}📂 目标目录: ${F_WHITE}$TARGET_DIR${RESET}"
    if [ -d "$TARGET_DIR" ]; then
        local existing_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -iname "*.png" 2>/dev/null | wc -l)
        echo -e "${C_BG2} ${F_YELLOW}⚠️  目标目录已有 $existing_count 个PNG文件${RESET}"
        log "【PNG批量复制】目标目录已有 $existing_count 个PNG文件"
    fi
    echo -e "\n${C_BG2} ${F_YELLOW}即将复制 $total_count 个文件:${RESET}"
    echo -e "${C_BG2} ${F_GRAY}  $(echo $NAME_LIST | sed 's/ /\.png  /g').png${RESET}"
    echo -e "\n${C_BG2} ${F_ACCENT}确认执行? [y/N]: \c${RESET}"
    read confirm
    case "$confirm" in
        y|Y)
            log "【PNG批量复制】用户确认执行"
            info_log "开始复制PNG文件"
            echo -e "${C_BG2} ${F_CYAN}⏳ 正在复制...${RESET}"
            mkdir -p "$TARGET_DIR" 2>/dev/null
            for name in $NAME_LIST; do
                target="${TARGET_DIR}/${name}.png"
                if [ -f "$target" ]; then
                    local backup="${TARGET_DIR}/${name}_backup_$(date +%s).png"
                    mv "$target" "$backup" 2>/dev/null
                    echo -e "${C_BG2} ${F_YELLOW}⚠️  已备份: ${name}.png${RESET}"
                    log "【PNG批量复制】已备份: ${name}.png"
                fi
                cp "$PNG_FOUND" "$target" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e "${C_BG2} ${F_GREEN}✅ ${name}.png${RESET}"
                    copy_success=$((copy_success + 1))
                    log "【PNG批量复制】成功复制: ${name}.png"
                else
                    echo -e "${C_BG2} ${F_RED}❌ ${name}.png (复制失败)${RESET}"
                    copy_failed=$((copy_failed + 1))
                    log "【PNG批量复制】复制失败: ${name}.png"
                fi
            done
            log "【PNG批量复制】复制完成: 成功 $copy_success 个，失败 $copy_failed 个"
            echo -e "\n${C_BG2} ${F_GREEN}📊 复制完成: 成功 $copy_success 个，失败 $copy_failed 个${RESET}"
            ;;
        *)
            log "【PNG批量复制】用户取消操作"
            echo -e "${C_BG2} ${F_YELLOW}已取消操作${RESET}"
            ;;
    esac
    log "【PNG批量复制】执行完成"
    wait_return
}

# ========== 功能7：清理缓存 ==========
menu_clean_cache() {
    clear
    echo -e "${C_BG}"
    titlebar "缓存清理工具" ""
    
    log "【清理缓存】开始执行"
    
    info_log "启动缓存清理"
    echo -e "${C_BG2} ${F_CYAN}正在计算缓存大小...${RESET}"
    local total_size=0
    for dir in /data/data/*/cache /data/data/*/code_cache /storage/emulated/0/Android/data/*/cache; do
        if [ -d "$dir" ]; then
            local size=$(du -s "$dir" 2>/dev/null | cut -f1)
            case "$size" in ''|*[!0-9]*) ;; *) total_size=$((total_size + size)) ;; esac
        fi
    done
    local total_size_mb=$((total_size / 1024))
    log "【清理缓存】缓存总大小: ${total_size_mb} MB"
    echo -e "${C_BG2} ${F_CYAN}📦 缓存总大小: ${F_WHITE}${total_size_mb} MB${RESET}"
    echo -e "\n${C_BG2} ${F_ACCENT}确认清理? [y/N]: \c${RESET}"
    read confirm
    case "$confirm" in
        y|Y)
            log "【清理缓存】用户确认执行"
            echo -e "${C_BG2} ${F_YELLOW}⏳ 正在清理缓存...${RESET}"
            for dir in /data/data/*/cache /data/data/*/code_cache /storage/emulated/0/Android/data/*/cache; do
                if [ -d "$dir" ]; then
                    rm -rf "$dir"/* 2>/dev/null
                    log "【清理缓存】已清理: $dir"
                fi
            done
            log "【清理缓存】清理完成"
            echo -e "${C_BG2} ${F_GREEN}✅ 缓存清理完成${RESET}"
            ;;
        *)
            log "【清理缓存】用户取消操作"
            echo -e "${C_BG2} ${F_YELLOW}已取消操作${RESET}"
            ;;
    esac
    log "【清理缓存】执行完成"
    wait_return
}

# ========== 主程序入口 ==========
main() {
    trap 'echo -e "\n${F_YELLOW}脚本被中断${RESET}"; exit 1' INT TERM
    
    check_root
    
    log "========== Root工具箱 v$VERSION 启动 =========="
    verify_license
    
    if check_termux_float; then
        log "检测到 Termux 环境"
        if command -v termux-float >/dev/null 2>&1; then
            if [ -z "$TERMUX_FLOAT" ]; then
                info_log "检测到 termux-float，尝试以悬浮窗模式运行..."
                echo -e "${C_BG2} ${F_CYAN}💡 提示: 可使用 Termux:Float 插件将此会话显示为悬浮窗${RESET}"
                echo -e "${C_BG2} ${F_CYAN}   安装 Termux:Float 后在通知栏点击 'Float' 即可${RESET}"
                echo -e "${C_BG2} ${F_GRAY}    按回车继续...${RESET}"
                read tmp 2>/dev/null
            fi
        fi
    fi
    
    while true; do
        show_main_menu
        read key 2>/dev/null
        echo -e "${RESET}"
        case "$key" in
            1) log "【主菜单】用户选择: 1 - 欧美大片专区"; menu_europe ;;
            2) log "【主菜单】用户选择: 2 - Scene 工具箱"; start_app "com.omarea.vtools" && wait_return ;;
            3) log "【主菜单】用户选择: 3 - 系统设置"; start_app "com.android.settings" && wait_return ;;
            4) log "【主菜单】用户选择: 4 - 微信"; start_app "com.tencent.mm" ".ui.LauncherUI" && wait_return ;;
            5) log "【主菜单】用户选择: 5 - 设备信息"; menu_device_info ;;
            6) log "【主菜单】用户选择: 6 - 批量复制PNG"; menu_png_batch ;;
            7) log "【主菜单】用户选择: 7 - 清理缓存"; menu_clean_cache ;;
            8) log "【主菜单】用户选择: 8 - 进入子菜单"; sub_menu_loop ;;
            10) log "【主菜单】用户选择: 10 - 脚本更新"; menu_update ;;
            9) log "【主菜单】用户选择: 9 - 退出脚本"; echo -e "${C_BG2} ${F_GREEN}正在退出脚本...${RESET}"; log "脚本正常退出"; exit 0 ;;
            *) if [ -n "$key" ]; then
                   log "【主菜单】用户输入错误: $key"
                   echo -e "${C_BG2} ${F_RED}输入错误，请重新选择！${RESET}"
                   sleep 1
               fi ;;
        esac
    done
}

main "$@"
