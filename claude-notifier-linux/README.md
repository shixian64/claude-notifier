# Claude Notifier (Linux)

Linux 原生桌面通知工具，当 Claude Code 完成任务时发送桌面通知 + 音效提醒。

## 系统要求

- Linux (Ubuntu 18.04+, Debian 10+, Fedora 30+, Arch)
- libnotify (`notify-send`)
- ImageMagick (`convert`) - 用于安装时转换图标
- 音频播放器 (任选其一): PulseAudio (`paplay`), ALSA (`aplay`), mpv, ffplay

## 快速开始

### 1. 安装依赖

**Ubuntu/Debian:**
```bash
sudo apt install libnotify-bin imagemagick pulseaudio-utils
```

**Fedora:**
```bash
sudo dnf install libnotify ImageMagick pulseaudio-utils
```

**Arch:**
```bash
sudo pacman -S libnotify imagemagick pulseaudio
```

### 2. 安装

```bash
cd claude-notifier-linux

# 默认安装到 ~/.claude/
make install

# 或安装到自定义路径
make install PREFIX=/opt/claude
```

### 3. 测试通知

```bash
~/.claude/bin/claude-notifier -t "测试" -m "通知配置成功"
```

## 使用方法

```bash
# 基本用法（默认标题和消息）
claude-notifier

# 自定义标题和消息
claude-notifier -t "标题" -m "消息内容"

# 使用自定义音效文件
claude-notifier -t "完成" -m "搞定！" -f ~/.claude/sounds/done.wav

# 静音模式
claude-notifier -t "静默通知" -m "无声音" --no-sound
```

## 参数说明

| 参数               | 说明               | 默认值           |
| ------------------ | ------------------ | ---------------- |
| `-t, --title`      | 通知标题           | "Claude Code"    |
| `-m, --message`    | 通知消息           | "Task completed" |
| `-f, --sound-file` | 自定义音效文件路径 | -                |
| `--no-sound`       | 禁用通知声音       | -                |
| `-h, --help`       | 显示帮助信息       | -                |

## 自定义语音音效

### 方法一：使用 espeak + ffmpeg

```bash
# 安装依赖
sudo apt install espeak ffmpeg

# 生成中文语音
espeak -v zh '搞定咯' --stdout | ffmpeg -i - -ar 44100 ~/.claude/sounds/done.wav
```

### 方法二：使用 pico2wave (更自然)

```bash
# 安装依赖
sudo apt install libttspico-utils

# 生成语音（仅支持英语等）
pico2wave -w ~/.claude/sounds/done.wav "Task completed"
```

### 方法三：使用在线 TTS 服务

推荐网站：
- [MiniMax](https://www.minimax.io/audio/text-to-speech/chinese) - 国产，声音真实
- [ElevenLabs](https://elevenlabs.io/text-to-speech/chinese) - 最自然

下载后确保格式为 `.wav` 或 `.ogg`。

## Claude Code Hooks 配置

编辑 `~/.claude/settings.json`：

### 基础配置（仅完成时通知）

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/bin/claude-notifier -t 'Claude Code' -m 'Claude 已完成回答'"
          }
        ]
      }
    ]
  }
}
```

### 完整配置（完成 + 需要输入时通知）

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/bin/claude-notifier -t 'Claude Code' -m '✅ 任务已完成'"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/bin/claude-notifier -t 'Claude Code' -m '⏳ 需要你的输入'"
          }
        ]
      }
    ]
  }
}
```

### 支持的 Hook 类型

| Hook 名称 | 触发时机 |
|-----------|----------|
| `Stop` | Claude 完成当前回合的回答 |
| `Notification` | 需要用户输入或确认时 |
| `PreToolUse` | 工具执行前（可用于审批） |
| `PostToolUse` | 工具执行后（可用于日志） |

### 带自定义音效

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/bin/claude-notifier -t 'Claude Code' -m 'Claude 已完成回答' -f '$HOME/.claude/sounds/done.wav'"
          }
        ]
      }
    ]
  }
}
```

## 技术细节

- **通知 API**: libnotify (`notify-send`)
- **图标**: Claude 星芒图标 (SVG → PNG 128x128)
- **音频播放**: 按优先级尝试 paplay → aplay → mpv → ffplay
- **安装目录**: `~/.claude/bin/claude-notifier`
- **图标目录**: `~/.claude/icons/claude-notifier.png`

## 与其他平台差异

| 特性     | macOS                    | Windows                  | Linux              |
| -------- | ------------------------ | ------------------------ | ------------------ |
| 语言     | Swift                    | Rust                     | Bash               |
| 通知 API | UNUserNotificationCenter | ToastNotificationManager | libnotify          |
| 图标格式 | .icns                    | .ico/.lnk                | .png               |
| 音频格式 | .aiff, .wav, .caf        | 仅 .wav                  | .wav, .ogg, .mp3   |
| 首次运行 | 自动授权弹窗             | 需手动 `--init`          | 无需               |

## 卸载

```bash
make uninstall
```

## 常见问题

| 问题             | 解决方案                                          |
| ---------------- | ------------------------------------------------- |
| 通知不显示       | 确认已安装 libnotify-bin，检查桌面环境通知设置    |
| 图标不显示       | 确认 ~/.claude/icons/claude-notifier.png 存在     |
| 音效不播放       | 确认已安装 paplay/aplay/mpv，检查 PulseAudio 状态 |
| 权限被拒绝       | 运行 `chmod +x ~/.claude/bin/claude-notifier`     |

## License

MIT License
