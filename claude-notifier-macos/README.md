# Claude Notifier (macOS)

macOS 原生通知工具，当 Claude Code 完成任务时发送桌面通知 + 语音提醒。

## 系统要求

- macOS 12.0+
- Swift 5.0+

## 快速开始

### 1. 安装

```bash
cd claude-notifier-macos

# 默认安装到 ~/.claude/apps/（推荐）
make install

# 或安装到 /Applications（系统级）
make install PREFIX=/Applications
```

### 2. 授权通知权限

首次运行时，macOS 会提示授权通知权限：

```bash
~/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier
```

在弹出的对话框中点击「允许」，或前往「系统设置 → 通知 → Claude Notifier」手动开启。

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

### 使用 macOS TTS 生成

```bash
# 使用中文语音生成音效
say -v Tingting "搞定咯~" -o done.aiff

# 可用的中文语音
say -v '?' | grep zh

# 常用语音：Tingting（女声）、Meijia（女声）
```

### 音效文件要求

- **格式**：`.aiff`, `.wav`, `.caf`, `.m4a`
- **时长**：必须小于 30 秒
- **安装**：使用 `-f` 参数时会自动复制到 `~/Library/Sounds/`

## Claude Code Hooks 配置

编辑 `~/.claude/settings.json`：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier -t 'Claude Code' -m 'Claude 已完成回答' -f '$HOME/.claude/sounds/done.aiff'"
          }
        ]
      }
    ]
  }
}
```

## 手动安装

如不使用 Makefile，可手动执行以下步骤：

```bash
# 编译 → 创建 App Bundle → 签名 → 注册
swiftc -O -o ClaudeNotifier src/ClaudeNotifier.swift
mkdir -p ~/.claude/apps/ClaudeNotifier.app/Contents/{MacOS,Resources}
cp ClaudeNotifier ~/.claude/apps/ClaudeNotifier.app/Contents/MacOS/
cp resources/Info.plist ~/.claude/apps/ClaudeNotifier.app/Contents/
cp resources/AppIcon.icns ~/.claude/apps/ClaudeNotifier.app/Contents/Resources/
codesign --force --deep --sign - ~/.claude/apps/ClaudeNotifier.app
lsregister -f ~/.claude/apps/ClaudeNotifier.app
```

## 技术细节

- **API**: `UNUserNotificationCenter`（Apple 官方通知 API）
- **图标**: Claude 星芒图标（SVG → iconset → icns）
- **后台运行**: `LSUIElement=true`（不显示 Dock 图标）
- **最低系统**: macOS 12.0+

## 卸载

```bash
# 默认路径
make uninstall

# 自定义路径
make uninstall PREFIX=/Applications
```

## 常见问题

| 问题           | 解决方案                                                                            |
| -------------- | ----------------------------------------------------------------------------------- |
| 通知不显示     | 检查「系统设置 → 通知 → ClaudeNotifier」是否允许                                    |
| 图标显示异常   | 重新签名：`codesign --force --deep --sign - <app路径>` 后 `lsregister -f <app路径>` |
| 自定义音效不响 | 确认格式为 `.aiff`、时长 < 30 秒、已复制到 `~/Library/Sounds/`                      |

## License

MIT License
