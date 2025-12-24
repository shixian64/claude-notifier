<p align="center">
  <img src="images/banner-2k.png" alt="ClaudeNotifier Banner" width="800"/>
</p>

<p align="center">
  <a href="#快速开始"><img src="https://img.shields.io/badge/macOS-12.0+-blue?style=flat-square&logo=apple" alt="macOS 12.0+"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License"/></a>
  <a href="#使用方法"><img src="https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square&logo=swift" alt="Swift 5.0+"/></a>
</p>

<p align="center">
  <b>macOS 原生通知工具，当 Claude Code 完成任务时发送桌面通知 + 语音提醒</b>
</p>

---

## 解决什么问题？

**场景**：你同时开了多个 Claude Code 终端窗口，让 AI 并行处理不同任务。

**痛点**：任务完成后你不知道，继续等待或去做别的事，等回来发现 AI 早就完成了——白白浪费了宝贵的 AI 使用时间。

**方案**：通过 Claude Code Hooks，在任务完成时自动发送桌面通知 + 语音提醒（如「搞定咯~」），即使你在其他窗口工作也能立刻知道。

<p align="center">
  <img src="images/notification-mockup.png" alt="通知效果演示" width="600"/>
  <br/>
  <i>macOS 原生通知效果（带 Claude 图标 + 语音提醒）</i>
</p>

## 为什么不用 osascript？

`osascript -e 'display notification'` 可以发通知，但：

- **没有自定义图标**：macOS 通知图标必须来自 App Bundle，无法通过参数指定
- **`terminal-notifier -appIcon` 已失效**：现代 macOS 不再支持

本工具创建轻量级 App Bundle，使用 Claude 星芒图标，通过 `UNUserNotificationCenter` 发送原生通知。

## 快速开始

```bash
git clone https://github.com/zengwenliang416/claude-notifier.git
cd claude-notifier
make install
```

## 使用方法

```bash
# 基本用法（默认标题和消息）
~/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier

# 自定义标题和消息
ClaudeNotifier -t "标题" -m "消息内容"

# 使用系统声音
ClaudeNotifier -t "完成" -m "任务已完成" -s "Hero"

# 使用自定义音效文件
ClaudeNotifier -t "完成" -m "搞定！" -f ~/Music/done.aiff

# 静音模式
ClaudeNotifier -t "静默通知" -m "无声音" --no-sound
```

## 参数说明

| 参数               | 说明               | 默认值           |
| ------------------ | ------------------ | ---------------- |
| `-t, --title`      | 通知标题           | "Claude Code"    |
| `-m, --message`    | 通知消息           | "Task completed" |
| `-s, --sound`      | 系统声音名称       | "Glass"          |
| `-f, --sound-file` | 自定义音效文件路径 | -                |
| `--no-sound`       | 禁用通知声音       | -                |
| `-h, --help`       | 显示帮助信息       | -                |

## 系统声音

可用的 macOS 系统声音：

```
Basso, Blow, Bottle, Frog, Funk, Glass, Hero,
Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink
```

## 自定义语音音效

### 方法一：使用 macOS TTS 生成

```bash
# 使用中文语音生成音效
say -v Tingting "搞定咯~" -o done.aiff

# 可用的中文语音
say -v '?' | grep zh

# 常用语音：Tingting（女声）、Meijia（女声）
```

### 方法二：使用在线 TTS 服务

推荐网站（语音更自然）：

| 网站                                                           | 特点                 |
| -------------------------------------------------------------- | -------------------- |
| [MiniMax](https://www.minimax.io/audio/text-to-speech/chinese) | 国产，声音真实       |
| [ElevenLabs](https://elevenlabs.io/text-to-speech/chinese)     | 最自然，支持情感调节 |
| [Crikk](https://crikk.com/text-to-speech/chinese/)             | 免费无限制           |

下载后转换格式：

```bash
# MP3 转 AIFF（macOS 通知需要 AIFF 格式）
ffmpeg -i input.mp3 -acodec pcm_s16le output.aiff

# 或使用 afconvert（部分 MP3 可能不支持）
afconvert input.mp3 output.aiff -d LEI16
```

### 音效文件要求

- **格式**：`.aiff`, `.wav`, `.caf`, `.m4a`
- **时长**：必须小于 30 秒
- **安装**：使用 `-f` 参数时会自动复制到 `~/Library/Sounds/`

## 与 Claude Code Hooks 集成

在 `~/.claude/hooks/stop-check.sh` 中添加：

```bash
send_notification() {
    local title="Claude Code"
    local message="Claude 已完成回答"
    local notifier="$HOME/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier"
    local sound_file="$HOME/.claude/sounds/done-custom.aiff"

    if [[ -x "$notifier" ]]; then
        "$notifier" -t "$title" -m "$message" -f "$sound_file" 2>/dev/null || \
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\"" 2>/dev/null || true
    else
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\"" 2>/dev/null || true
    fi
}
```

## 手动安装

```bash
# 1. 编译
swiftc -O -o ClaudeNotifier src/ClaudeNotifier.swift

# 2. 创建 App Bundle
mkdir -p ~/.claude/apps/ClaudeNotifier.app/Contents/{MacOS,Resources}
cp ClaudeNotifier ~/.claude/apps/ClaudeNotifier.app/Contents/MacOS/
cp resources/Info.plist ~/.claude/apps/ClaudeNotifier.app/Contents/
cp resources/AppIcon.icns ~/.claude/apps/ClaudeNotifier.app/Contents/Resources/

# 3. 签名
codesign --force --deep --sign - ~/.claude/apps/ClaudeNotifier.app

# 4. 注册到 LaunchServices
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/.claude/apps/ClaudeNotifier.app
```

## 首次使用

首次运行时，macOS 会提示授权通知权限。请在「系统设置 → 通知」中允许「Claude Notifier」发送通知。

## 技术细节

- **API**: `UNUserNotificationCenter`（Apple 官方通知 API）
- **图标**: Claude 星芒图标（SVG → iconset → icns）
- **后台运行**: `LSUIElement=true`（不显示 Dock 图标）
- **最低系统**: macOS 12.0+

## 项目结构

```
claude-notifier/
├── README.md           # 本文档
├── LICENSE             # MIT 许可证
├── Makefile            # 构建脚本
├── src/
│   └── ClaudeNotifier.swift    # 主程序源码
├── resources/
│   ├── Info.plist              # App Bundle 配置
│   ├── AppIcon.icns            # Claude 图标
│   └── claude-starburst.svg    # 图标源文件
├── images/                     # 文档图片
│   ├── banner-2k.png           # 项目横幅 (2K)
│   ├── notification-mockup.png # 通知效果演示 (2K)
│   └── logo.png                # Claude 图标 PNG
├── sounds/                     # 示例音效目录
│   └── .gitkeep
└── examples/
    └── stop-check.sh           # Hook 集成示例
```

## 常见问题

### 通知不显示？

1. 检查「系统设置 → 通知 → Claude Notifier」是否允许
2. 重新注册应用：`lsregister -f ~/.claude/apps/ClaudeNotifier.app`

### 自定义音效不响？

1. 确认音效时长 < 30 秒
2. 确认格式为 `.aiff`（推荐）或 `.wav`
3. 检查 `~/Library/Sounds/` 目录是否有对应文件

### 图标显示为默认？

重新签名并注册：

```bash
codesign --force --deep --sign - ~/.claude/apps/ClaudeNotifier.app
lsregister -f ~/.claude/apps/ClaudeNotifier.app
```

## License

MIT License
