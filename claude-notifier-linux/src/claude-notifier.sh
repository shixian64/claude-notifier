#!/usr/bin/env bash
# ClaudeNotifier - Linux 桌面通知工具
# 当 Claude Code 完成任务时发送桌面通知 + 音效提醒 + ntfy 远程推送

set -euo pipefail

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
  -h, --help               显示此帮助信息

环境变量:
  NTFY_TOPIC               ntfy 主题名 (设置后启用远程推送)
  NTFY_SERVER              ntfy 服务器地址 (默认: https://ntfy.sh)

示例:
  claude-notifier -t "完成" -m "构建成功"
  claude-notifier -f ~/.claude/sounds/done.wav
  claude-notifier --no-sound -m "静默通知"

  # 启用 ntfy 推送
  NTFY_TOPIC=my-claude claude-notifier -m "任务完成"

音效播放优先级: paplay > aplay > mpv > ffplay
EOF
    exit 0
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

    # 检查 notify-send 是否可用
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
    send_notification "$TITLE" "$MESSAGE" "$ICON"

    # 发送 ntfy 远程推送
    send_ntfy "$TITLE" "$MESSAGE"

    # 播放音效
    if [[ "$NO_SOUND" != true ]]; then
        play_sound "$SOUND_FILE"
    fi
}

main "$@"
