#!/usr/bin/env bash
# ClaudeNotifier - Linux 桌面通知工具
# 当 Claude Code 完成任务时发送桌面通知 + 音效提醒 + ntfy 远程推送
# 支持点击通知跳转到指定窗口

set -euo pipefail

# 确保 DISPLAY 环境变量存在 (用于 X11 窗口操作)
if [[ -z "${DISPLAY:-}" ]]; then
    export DISPLAY=:0
fi

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# 默认值
TITLE="Claude Code"
MESSAGE="Task completed"
SOUND_FILE=""
NO_SOUND=false
ICON="${HOME}/.claude/icons/claude-notifier.png"
FOCUS_WINDOW=""  # 点击通知后要聚焦的窗口标识
NOTIFICATION_ID_FILE="${HOME}/.claude/.notification_id"  # 保存上一次通知 ID

# ntfy 配置 (从环境变量读取)
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_SERVER="${NTFY_SERVER:-https://ntfy.sh}"

# 显示帮助信息
show_help() {
    cat << 'EOF'
ClaudeNotifier - Linux 桌面通知工具

用法: claude-notifier [选项]

选项:
  -t, --title <text>       通知标题 (默认: "Claude Code")
  -m, --message <text>     通知消息 (默认: "Task completed")
  -f, --sound-file <path>  自定义音效文件 (.wav, .ogg, .mp3)
  --no-sound               禁用通知声音
  -w, --focus-window <id>  点击通知后聚焦的窗口 (窗口ID，如 0x08053c6b)
  --get-active-window      输出当前活动窗口ID后退出 (用于 Hook 配置)
  -h, --help               显示此帮助信息

环境变量:
  NTFY_TOPIC               ntfy 主题名 (设置后启用远程推送)
  NTFY_SERVER              ntfy 服务器地址 (默认: https://ntfy.sh)

示例:
  claude-notifier -t "完成" -m "构建成功"
  claude-notifier -f ~/.claude/sounds/done.wav
  claude-notifier --no-sound -m "静默通知"

  # 获取当前窗口ID (用于配置 Hook)
  claude-notifier --get-active-window

  # 点击通知后聚焦到指定窗口 (推荐使用窗口ID)
  claude-notifier -m "任务完成" -w "0x08053c6b"

  # 查看所有窗口ID
  wmctrl -l

  # 启用 ntfy 推送
  NTFY_TOPIC=my-claude claude-notifier -m "任务完成"

音效播放优先级: paplay > aplay > mpv > ffplay
窗口聚焦依赖: wmctrl (sudo apt install wmctrl)
EOF
    exit 0
}

# 获取当前活动窗口ID
get_active_window() {
    if command -v xdotool &>/dev/null; then
        local win_id
        win_id=$(xdotool getactivewindow 2>/dev/null)
        if [[ -n "$win_id" ]]; then
            # 转换为十六进制格式
            printf "0x%08x\n" "$win_id"
            exit 0
        fi
    fi
    log_error "无法获取活动窗口ID，请安装 xdotool: sudo apt install xdotool"
    exit 1
}

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 聚焦窗口
focus_window() {
    local window_id="$1"

    if [[ -z "$window_id" ]]; then
        return 0
    fi

    # 检查 wmctrl 是否可用
    if ! command -v wmctrl &>/dev/null; then
        log_warn "未找到 wmctrl，无法聚焦窗口。请安装: sudo apt install wmctrl"
        return 0
    fi

    # 如果是十六进制窗口 ID (如 0x08053c6b)
    if [[ "$window_id" =~ ^0x[0-9a-fA-F]+$ ]]; then
        wmctrl -i -a "$window_id" 2>/dev/null && log_info "已聚焦窗口: $window_id" || log_warn "无法聚焦窗口: $window_id"
    else
        # 按窗口名称匹配
        wmctrl -a "$window_id" 2>/dev/null && log_info "已聚焦窗口: $window_id" || log_warn "无法找到匹配的窗口: $window_id"
    fi
}

# 获取上一次通知的 ID (用于替换累积通知)
get_last_notification_id() {
    if [[ -f "$NOTIFICATION_ID_FILE" ]]; then
        cat "$NOTIFICATION_ID_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 保存通知 ID
save_notification_id() {
    local id="$1"
    echo "$id" > "$NOTIFICATION_ID_FILE" 2>/dev/null
}

# 使用 gdbus 发送通知并监听点击事件
send_notification_with_action() {
    local title="$1"
    local message="$2"
    local icon="$3"
    local focus_window="$4"

    # 检查 gdbus 是否可用
    if ! command -v gdbus &>/dev/null; then
        log_warn "未找到 gdbus，回退到 notify-send"
        send_notification "$title" "$message" "$icon"
        return
    fi

    # 检查 wmctrl 是否可用
    if ! command -v wmctrl &>/dev/null; then
        log_warn "未找到 wmctrl，无法聚焦窗口。请安装: sudo apt install wmctrl"
        send_notification "$title" "$message" "$icon"
        return
    fi

    # 构建图标路径
    local icon_path=""
    if [[ -f "$icon" ]]; then
        icon_path="$icon"
    fi

    # 获取上一次通知 ID，用于替换累积通知（避免通知堆积）
    local replaces_id
    replaces_id=$(get_last_notification_id)

    # 使用 gdbus 发送通知
    # - replaces_id: 使用上次通知 ID，新通知会替换旧通知
    # - resident: true 让通知持久显示
    # - urgency: 2 (critical) 确保通知不会自动消失
    # - timeout: 0 表示不自动消失
    local result
    result=$(gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "Claude Code" \
        "$replaces_id" \
        "$icon_path" \
        "$title" \
        "$message" \
        '["default", "查看"]' \
        '{"resident": <true>, "urgency": <byte 2>}' \
        0 2>&1)

    # 提取通知 ID
    local notification_id
    notification_id=$(echo "$result" | grep -oP 'uint32 \K\d+')

    if [[ -z "$notification_id" ]]; then
        log_warn "gdbus 发送通知失败，回退到 notify-send"
        send_notification "$title" "$message" "$icon"
        return
    fi

    # 保存通知 ID，下次发送时会替换此通知（避免通知堆积）
    save_notification_id "$notification_id"

    log_info "通知已发送 (ID: $notification_id, 替换: $replaces_id)"

    # 启动后台监听进程
    (
        # 监听 ActionInvoked 信号 (用户点击通知)
        timeout 60 gdbus monitor --session \
            --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications 2>/dev/null | \
        while IFS= read -r line; do
            # 检查是否是我们的通知被点击
            if [[ "$line" == *"ActionInvoked"* && "$line" == *"uint32 $notification_id"* ]]; then
                # 使用窗口ID精确聚焦
                wmctrl -i -a "$focus_window" 2>/dev/null
                # 关闭通知
                gdbus call --session \
                    --dest org.freedesktop.Notifications \
                    --object-path /org/freedesktop/Notifications \
                    --method org.freedesktop.Notifications.CloseNotification \
                    "$notification_id" &>/dev/null
                break
            fi
        done
    ) &>/dev/null &
    disown
}

# 播放音效
play_sound() {
    local sound_file="$1"

    # 如果没有指定音效文件，使用默认音效
    if [[ -z "$sound_file" ]]; then
        sound_file="${HOME}/.claude/sounds/done.wav"
    fi

    # 检查文件是否存在
    if [[ ! -f "$sound_file" ]]; then
        log_warn "音效文件不存在: $sound_file"
        return 0
    fi

    # 按优先级尝试播放
    if command -v paplay &>/dev/null; then
        paplay "$sound_file" 2>/dev/null &
    elif command -v aplay &>/dev/null; then
        aplay -q "$sound_file" 2>/dev/null &
    elif command -v mpv &>/dev/null; then
        mpv --no-video --really-quiet "$sound_file" 2>/dev/null &
    elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet "$sound_file" 2>/dev/null &
    else
        log_warn "未找到音频播放器 (paplay/aplay/mpv/ffplay)"
    fi
}

# 发送通知
send_notification() {
    local title="$1"
    local message="$2"
    local icon="$3"

    # 优先使用 gdbus（支持替换通知，避免堆积）
    if command -v gdbus &>/dev/null; then
        local icon_path=""
        if [[ -f "$icon" ]]; then
            icon_path="$icon"
        fi

        # 获取上一次通知 ID，用于替换累积通知
        local replaces_id
        replaces_id=$(get_last_notification_id)

        local result
        result=$(gdbus call --session \
            --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.Notify \
            "Claude Code" \
            "$replaces_id" \
            "$icon_path" \
            "$title" \
            "$message" \
            '[]' \
            '{}' \
            5000 2>&1)

        # 提取并保存通知 ID
        local notification_id
        notification_id=$(echo "$result" | grep -oP 'uint32 \K\d+')
        if [[ -n "$notification_id" ]]; then
            save_notification_id "$notification_id"
            return
        fi
    fi

    # 回退到 notify-send
    if ! command -v notify-send &>/dev/null; then
        log_error "未找到 notify-send，请安装 libnotify-bin"
        log_error "  Ubuntu/Debian: sudo apt install libnotify-bin"
        log_error "  Fedora: sudo dnf install libnotify"
        log_error "  Arch: sudo pacman -S libnotify"
        exit 1
    fi

    # 构建通知命令参数
    local notify_args=()
    notify_args+=(-a "Claude Code")

    # 如果图标存在则使用
    if [[ -f "$icon" ]]; then
        notify_args+=(-i "$icon")
    fi

    # 发送通知
    notify-send "${notify_args[@]}" "$title" "$message"
}

# 发送 ntfy 远程推送
send_ntfy() {
    local title="$1"
    local message="$2"

    # 如果没有配置 NTFY_TOPIC，跳过
    if [[ -z "$NTFY_TOPIC" ]]; then
        return 0
    fi

    # 检查 curl 是否可用
    if ! command -v curl &>/dev/null; then
        log_warn "未找到 curl，无法发送 ntfy 推送"
        return 0
    fi

    # 发送 ntfy 推送 (后台执行，不阻塞)
    curl -s \
        -H "Title: $title" \
        -H "Priority: default" \
        -H "Tags: white_check_mark" \
        -d "$message" \
        "${NTFY_SERVER}/${NTFY_TOPIC}" &>/dev/null &

    log_info "已发送 ntfy 推送到 ${NTFY_TOPIC}"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--title)
                TITLE="$2"
                shift 2
                ;;
            -m|--message)
                MESSAGE="$2"
                shift 2
                ;;
            -f|--sound-file)
                SOUND_FILE="$2"
                shift 2
                ;;
            --no-sound)
                NO_SOUND=true
                shift
                ;;
            -w|--focus-window)
                FOCUS_WINDOW="$2"
                shift 2
                ;;
            --get-active-window)
                get_active_window
                ;;
            -h|--help)
                show_help
                ;;
            *)
                log_warn "未知参数: $1"
                shift
                ;;
        esac
    done
}

# 主函数
main() {
    parse_args "$@"

    # 发送桌面通知
    if [[ -n "$FOCUS_WINDOW" ]]; then
        # 使用 gdbus 发送通知，支持点击聚焦
        send_notification_with_action "$TITLE" "$MESSAGE" "$ICON" "$FOCUS_WINDOW"
    else
        # 使用普通 notify-send
        send_notification "$TITLE" "$MESSAGE" "$ICON"
    fi

    # 发送 ntfy 远程推送
    send_ntfy "$TITLE" "$MESSAGE"

    # 播放音效
    if [[ "$NO_SOUND" != true ]]; then
        play_sound "$SOUND_FILE"
    fi
}

main "$@"
