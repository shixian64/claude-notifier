<p align="center">
  <img src="images/banner-2k.png" alt="ClaudeNotifier Banner" width="800"/>
</p>

<p align="center">
  <a href="claude-notifier-macos/"><img src="https://img.shields.io/badge/macOS-12.0+-blue?style=flat-square&logo=apple" alt="macOS 12.0+"/></a>
  <a href="claude-notifier-windows/"><img src="https://img.shields.io/badge/Windows-10+-0078D6?style=flat-square&logo=windows" alt="Windows 10+"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License"/></a>
</p>

<p align="center">
  <b>跨平台桌面通知工具，当 Claude Code 完成任务时发送通知 + 语音提醒</b>
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

## 平台支持

| 平台        | 目录                                                   | 语言  | 状态      |
| ----------- | ------------------------------------------------------ | ----- | --------- |
| **macOS**   | [`claude-notifier-macos/`](claude-notifier-macos/)     | Swift | ✅ 稳定   |
| **Windows** | [`claude-notifier-windows/`](claude-notifier-windows/) | Rust  | 🚧 开发中 |

## 快速开始

### macOS

```bash
git clone https://github.com/zengwenliang416/claude-notifier.git
cd claude-notifier/claude-notifier-macos
make install
```

详细文档：[macOS 版 README](claude-notifier-macos/README.md)

### Windows

```powershell
# 下载 Release 或从源码构建
cd claude-notifier-windows
cargo build --release

# 首次运行（必需）
.\target\release\claude-notifier.exe --init
```

详细文档：[Windows 版 README](claude-notifier-windows/README.md)

## Claude Code Hooks 配置

### macOS

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
            "command": "$HOME/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier -t 'Claude Code' -m 'Claude 已完成回答'"
          }
        ]
      }
    ]
  }
}
```

### Windows

编辑 `%USERPROFILE%\.claude\settings.json`：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "%USERPROFILE%\\.claude\\apps\\claude-notifier.exe -t \"Claude Code\" -m \"Claude 已完成回答\""
          }
        ]
      }
    ]
  }
}
```

## 项目结构

```
claude-notifier/
├── README.md                    # 本文档（项目总览）
├── LICENSE                      # MIT 许可证
├── .github/workflows/           # GitHub Actions CI
├── config/                      # 配置文件模板
│   └── notifier.example.toml    # 多渠道推送配置示例
├── scripts/                     # 跨平台脚本
│   └── notify-remote.sh         # 远程推送脚本
├── images/                      # 文档图片（共用）
├── examples/                    # Hook 示例脚本（共用）
├── sounds/                      # 音效文件目录（共用）
├── claude-notifier-macos/       # macOS 版本
│   ├── README.md
│   ├── Makefile
│   ├── src/
│   │   └── ClaudeNotifier.swift
│   └── resources/
│       ├── Info.plist
│       └── AppIcon.icns
└── claude-notifier-windows/     # Windows 版本
    ├── README.md
    ├── Cargo.toml
    ├── build.rs
    ├── src/
    │   ├── main.rs
    │   ├── cli.rs
    │   ├── toast.rs
    │   ├── sound.rs
    │   └── registration.rs
    ├── resources/
    └── scripts/
        └── install.ps1
```

## 多渠道推送（实验性）

除了桌面通知，还支持推送到手机和 IM 工具：

| 渠道     | 平台        | 状态    |
| -------- | ----------- | ------- |
| ntfy.sh  | iOS/Android | ✅ 可用 |
| Telegram | 全平台      | ✅ 可用 |
| Bark     | iOS         | ✅ 可用 |
| 飞书     | 企业微信    | ✅ 可用 |
| 钉钉     | 企业微信    | ✅ 可用 |
| 企业微信 | 企业微信    | ✅ 可用 |

### 快速体验（ntfy 推荐）

```bash
# 1. 手机安装 ntfy App（iOS/Android 均可）
# 2. 订阅主题，如: claude-你的用户名

# 3. 配置并测试
mkdir -p ~/.config/claude-notifier
cp config/notifier.example.toml ~/.config/claude-notifier/notifier.toml
# 编辑配置文件，设置 [ntfy] enabled = true

# 4. 测试推送
./scripts/notify-remote.sh -t "测试" -m "推送成功！"
```

### Hook 配置（桌面+远程）

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier -t 'Claude Code' -m 'Claude 已完成回答' && $HOME/.claude/repos/claude-notifier/scripts/notify-remote.sh -t 'Claude Code' -m 'Claude 已完成回答'"
          }
        ]
      }
    ]
  }
}
```

详细配置说明见 [`config/notifier.example.toml`](config/notifier.example.toml)

## 技术对比

| 特性     | macOS                    | Windows                  |
| -------- | ------------------------ | ------------------------ |
| 语言     | Swift                    | Rust                     |
| 通知 API | UNUserNotificationCenter | ToastNotificationManager |
| 图标机制 | App Bundle (.icns)       | AUMID + 快捷方式 (.lnk)  |
| 音频格式 | .aiff, .wav, .caf        | 仅 .wav                  |
| 首次运行 | 自动授权弹窗             | 需手动 `--init`          |

## 自定义语音音效

### macOS

```bash
# 使用 TTS 生成
say -v Tingting "搞定咯~" -o ~/.claude/sounds/done.aiff
```

### Windows

```powershell
# 使用 PowerShell TTS
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SetOutputToWaveFile("$env:USERPROFILE\.claude\sounds\done.wav")
$synth.Speak("搞定咯")
$synth.Dispose()
```

## License

MIT License
