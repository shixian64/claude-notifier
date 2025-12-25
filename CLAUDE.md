# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

ClaudeNotifier 是一个跨平台桌面通知工具，用于在 Claude Code 完成任务时发送桌面通知和语音提醒。该项目为 macOS、Windows 和 Linux 分别提供原生实现，通过 Claude Code Hooks 机制与 AI 工作流集成。

## 核心架构

### 三平台独立实现

项目采用**单仓多平台**架构，每个平台使用最适合的原生技术栈：

- **macOS 版本** (`claude-notifier-macos/`): Swift 实现，使用 UNUserNotificationCenter API
- **Windows 版本** (`claude-notifier-windows/`): Rust 实现，使用 Windows Runtime Toast API
- **Linux 版本** (`claude-notifier-linux/`): Bash 实现，使用 libnotify (notify-send)

三个平台的通知工具**完全独立**，没有共享代码，仅共享以下资源：
- `images/` - 文档图片和 banner
- `sounds/` - 语音音效文件（供用户参考）
- `examples/stop-check.ts` - TypeScript Hook 示例

### Hook 集成架构

通知系统通过 Claude Code Hooks 的 `Stop` 事件触发，支持两种使用模式：

1. **直接调用模式**（简化版）: Hook 直接执行平台原生通知工具
2. **TypeScript Hook 模式**（推荐）:
   - 检查 `~/.claude/todos.json` 确保任务完成
   - 调用桌面通知（ClaudeNotifier）
   - 并行发送远程推送（ntfy/Telegram/Bark，三选一）
   - 显示项目名称（通过 `basename(cwd)` 获取）

### 关键技术差异

| 特性 | macOS | Windows | Linux |
|------|-------|---------|-------|
| **语言** | Swift | Rust | Bash |
| **通知 API** | UNUserNotificationCenter | ToastNotificationManager | libnotify (notify-send) |
| **图标机制** | App Bundle (.icns) | AUMID + 快捷方式 (.lnk) | PNG 图标 |
| **音频格式** | .aiff, .wav, .caf, .m4a | 仅 .wav | .wav, .ogg, .mp3 |
| **首次运行** | 自动授权弹窗 | 需手动执行 `--init` 注册 | 无需 |
| **安装目录** | `~/.claude/apps/ClaudeNotifier.app/` | `%USERPROFILE%\.claude\apps\claude-notifier.exe` | `~/.claude/bin/claude-notifier` |

## 常用命令

### macOS

```bash
# 构建和安装
cd claude-notifier-macos
make install                    # 安装到 ~/.claude/apps/
make install PREFIX=/Applications  # 安装到系统应用

# 测试通知
~/.claude/apps/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier -t "测试" -m "通知测试"

# 生成自定义语音音效
say -v Tingting "搞定咯~" -o ~/.claude/sounds/done.aiff

# 清理和卸载
make clean
make uninstall
```

### Windows

```bash
# 从源码构建
cd claude-notifier-windows
cargo build --release
cargo clippy -- -D warnings
cargo fmt --check

# 首次安装（必需）
.\target\release\claude-notifier.exe --init

# 测试通知
.\target\release\claude-notifier.exe -t "测试" -m "通知测试"

# 生成自定义语音音效（PowerShell）
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SetOutputToWaveFile("$env:USERPROFILE\.claude\sounds\done.wav")
$synth.Speak("搞定咯")
$synth.Dispose()

# 卸载
.\target\release\claude-notifier.exe --uninstall
```

### Linux

```bash
# 安装依赖 (Ubuntu/Debian)
sudo apt install libnotify-bin imagemagick pulseaudio-utils

# 构建和安装
cd claude-notifier-linux
make install                    # 安装到 ~/.claude/

# 测试通知
~/.claude/bin/claude-notifier -t "测试" -m "通知测试"

# 生成自定义语音音效
espeak -v zh '搞定咯' --stdout | ffmpeg -i - -ar 44100 ~/.claude/sounds/done.wav

# 卸载
make uninstall
```

### 运行 Hook 示例

```bash
# 测试 TypeScript Hook（需要 tsx）
npx tsx examples/stop-check.ts
```

## 代码结构说明

### macOS 实现 (`claude-notifier-macos/`)

- **单文件实现**: `src/ClaudeNotifier.swift` - 包含完整的通知逻辑
- **App Bundle 资源**:
  - `resources/Info.plist` - 定义 LSUIElement=true（后台运行）
  - `resources/AppIcon.icns` - Claude 星芒图标
- **Makefile**: 自动化编译、App Bundle 创建、代码签名、LaunchServices 注册

### Windows 实现 (`claude-notifier-windows/`)

模块化 Rust 架构：
- `src/main.rs` - 入口点和流程控制
- `src/cli.rs` - Clap 命令行参数解析
- `src/toast.rs` - Toast 通知 XML 生成和显示
- `src/sound.rs` - MediaPlayer 音频播放
- `src/registration.rs` - AUMID 注册和快捷方式创建
- `build.rs` - 嵌入应用图标资源

**关键注意事项**:
- Windows Toast 通知必须先执行 `--init` 创建开始菜单快捷方式，否则无法显示自定义图标
- AUMID（Application User Model ID）用于系统识别通知来源

### Linux 实现 (`claude-notifier-linux/`)

轻量级 Bash 脚本实现：
- `src/claude-notifier.sh` - 主程序，调用 notify-send 和音频播放器
- `resources/claude-starburst.svg` - Claude 星芒图标源文件
- `Makefile` - 自动化安装，包含 SVG→PNG 转换

**关键注意事项**:
- 使用 ImageMagick `convert` 将 SVG 转换为 128x128 PNG 图标
- 音频播放按优先级尝试: paplay → aplay → mpv → ffplay
- 无需首次运行初始化，安装后即可使用

### Hook 示例 (`examples/stop-check.ts`)

TypeScript Hook 的核心逻辑：
1. **任务完成检查**: 读取 `~/.claude/todos.json`，阻止任务未完成时结束
2. **跨平台桌面通知**: 根据 `os.platform()` 自动选择对应平台的通知工具
3. **项目名称显示**: 使用 `basename(process.cwd())` 获取当前项目名
4. **返回格式**: `{decision: "block"|"approve", reason?: string}` JSON 输出

远程推送功能（ntfy/Telegram/Bark）已移除，需要时参考 Git 历史。

## 开发注意事项

### macOS 开发

1. **代码签名**: App Bundle 必须签名才能注册到 LaunchServices，否则图标不显示
   ```bash
   codesign --force --deep --sign - ~/.claude/apps/ClaudeNotifier.app
   ```

2. **LaunchServices 注册**: 安装后必须注册，否则系统无法识别 App
   ```bash
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f <app路径>
   ```

3. **音效限制**: UNNotificationSound 要求音频文件小于 30 秒

### Windows 开发

1. **AUMID 注册顺序**: 必须先创建快捷方式，再发送通知，否则系统使用默认 PowerShell 图标

2. **音频格式**: Windows Toast 仅支持 .wav 格式，使用 MediaPlayer API 播放

3. **Release 构建优化**: Cargo.toml 配置了激进优化（`opt-level="z"`, LTO, strip）以减小体积

4. **CI/CD**: 仅 Windows 有 GitHub Actions 自动构建（`.github/workflows/build-windows.yml`）
   - 推送到 main 或 PR 时触发
   - 执行 fmt check、clippy、release 构建
   - 上传构建产物到 Artifacts

### Linux 开发

1. **依赖检查**: Makefile 会自动检查 `notify-send` 和 `convert` 是否可用

2. **图标转换**: 使用 ImageMagick 将 SVG 转换为 PNG
   ```bash
   convert -background none resources/claude-starburst.svg -resize 128x128 ~/.claude/icons/claude-notifier.png
   ```

3. **音频播放器优先级**: paplay (PulseAudio) → aplay (ALSA) → mpv → ffplay

4. **脚本权限**: 安装时自动设置 755 权限

### Hook 开发

1. **环境变量**: Claude Code Hooks 不加载 shell 环境变量（如 .zshrc/.bashrc），远程推送配置必须写在 `~/.claude/settings.json` 的 `env` 字段

2. **并行执行**: 桌面通知和远程推送使用 `spawnSync(..., {stdio: "ignore"})` 并行执行，不阻塞主流程

3. **错误处理**: ClaudeNotifier 不可用时静默跳过（`try-catch`），不影响 Hook 正常返回

## CI/CD 说明

当前仅 Windows 版本配置了自动构建：
- **触发条件**: 修改 `claude-notifier-windows/**` 文件或工作流配置
- **构建步骤**: Rust 格式检查 → Clippy → Release 构建 → 上传 Artifact
- **发布流程**: 手动创建 Git Tag 触发 Release（配置已包含但需 Tag）

macOS 和 Linux 版本无自动构建，依赖本地 Makefile 构建。

## 音效文件说明

- `sounds/` 目录包含共享的示例音效文件
- `task-complete.wav` 直接存在于 `claude-notifier-windows/` 根目录（历史遗留，待清理）
- 用户自定义音效应放在：
  - macOS: `~/.claude/sounds/` (支持 .aiff, .wav, .caf, .m4a)
  - Windows: `%USERPROFILE%\.claude\sounds\` (仅 .wav)
  - Linux: `~/.claude/sounds/` (支持 .wav, .ogg, .mp3)
