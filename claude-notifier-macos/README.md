# Claude Notifier (macOS)

macOS 原生通知工具，当 Claude Code 完成任务时发送桌面通知 + 语音提醒。

## 功能特性

- 🔔 **桌面通知**：显示 Claude 星芒图标的原生 macOS 通知
- 🔊 **语音提醒**：支持系统声音和自定义音效文件
- 🎯 **点击跳转**：点击通知自动跳转到对应项目窗口
- 🪟 **智能匹配**：通过项目路径/名称匹配正确的编辑器窗口

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

### 基础参数

| 参数               | 说明               | 默认值           |
| ------------------ | ------------------ | ---------------- |
| `-t, --title`      | 通知标题           | "Claude Code"    |
| `-m, --message`    | 通知消息           | "Task completed" |
| `-s, --sound`      | 系统声音名称       | "Glass"          |
| `-f, --sound-file` | 自定义音效文件路径 | -                |
| `--no-sound`       | 禁用通知声音       | -                |
| `-h, --help`       | 显示帮助信息       | -                |

### 点击跳转参数

| 参数               | 说明                            | 示例                   |
| ------------------ | ------------------------------- | ---------------------- |
| `--host-bundle-id` | 宿主应用 Bundle ID              | `dev.zed.Zed`          |
| `--project-path`   | 项目完整路径                    | `/Users/xxx/myproject` |
| `--project-name`   | 项目文件夹名称                  | `myproject`            |
| `--tty`            | 终端 TTY 路径（保留，暂未使用） | `/dev/ttys003`         |

**支持的 Bundle ID**：

| 应用      | Bundle ID                       |
| --------- | ------------------------------- |
| Zed       | `dev.zed.Zed`                   |
| VS Code   | `com.microsoft.VSCode`          |
| Cursor    | `com.todesktop.230313mzl4w4u92` |
| Terminal  | `com.apple.Terminal`            |
| iTerm2    | `com.googlecode.iterm2`         |
| Warp      | `dev.warp.Warp-Stable`          |
| Alacritty | `org.alacritty`                 |
| Kitty     | `net.kovidgoyal.kitty`          |

## 点击跳转功能

### 功能说明

点击通知时，ClaudeNotifier 会：

1. **激活宿主应用**：将指定的 IDE/终端带到前台
2. **聚焦项目窗口**：在多窗口中找到并 raise 对应的项目窗口

### 窗口匹配逻辑

支持两种匹配方式（满足任一即匹配）：

- **AXDocument 匹配**：窗口的文档路径包含 `--project-path`
- **标题匹配**：窗口标题包含 `--project-name`，或窗口标题出现在 `--project-path` 中

> 例如：Zed 窗口标题为 `.claude`，项目路径为 `/Users/xxx/.claude/repos/myproject`，
> 由于 `.claude` 出现在路径中，也会匹配成功。

### 技术实现

1. **AX API**（首选）：通过 `AXUIElementPerformAction` 执行 `kAXRaiseAction`
2. **AppleScript**（备用）：通过 System Events 控制窗口

### 权限要求

点击跳转需要 **辅助功能权限**：

1. 首次使用时会弹出授权提示
2. 或手动前往：**系统设置 → 隐私与安全性 → 辅助功能**
3. 添加 `ClaudeNotifier.app` 并勾选

### 使用示例

```bash
# 完整的点击跳转通知
ClaudeNotifier \
  -t "Claude Code" \
  -m "myproject 任务完成" \
  --host-bundle-id dev.zed.Zed \
  --project-path /Users/xxx/myproject \
  --project-name myproject
```

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

### 基础配置

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

### 带点击跳转的高级配置

推荐使用 TypeScript hook 脚本（`~/.claude/hooks/stop-check.ts`），自动检测宿主应用：

```typescript
// 检测宿主应用 Bundle ID
function detectHostBundleId(): string | undefined {
  const bundleMap: Record<string, string> = {
    zed: "dev.zed.Zed",
    vscode: "com.microsoft.VSCode",
    cursor: "com.todesktop.230313mzl4w4u92",
    // ...
  };
  const termProgram = process.env.TERM_PROGRAM?.toLowerCase();
  return termProgram ? bundleMap[termProgram] : undefined;
}

// 调用 ClaudeNotifier
const args = ["-t", "Claude Code", "-m", `${projectName} 任务完成`];
const hostBundleId = detectHostBundleId();
if (hostBundleId) {
  args.push("--host-bundle-id", hostBundleId);
  args.push("--project-path", process.cwd());
  args.push("--project-name", path.basename(process.cwd()));
}
spawn(notifierPath, args, { detached: true });
```

完整示例参考：[stop-check.ts](https://github.com/user/claude-notifier/blob/main/examples/stop-check.ts)

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

- **通知 API**: `UNUserNotificationCenter`（Apple 官方通知 API）
- **点击处理**: `UNUserNotificationCenterDelegate.didReceive`
- **窗口聚焦**: Accessibility API (`AXUIElement`) + AppleScript 备用
- **事件循环**: `NSApplication.run()` 接收通知回调
- **图标**: Claude 星芒图标（SVG → iconset → icns）
- **后台运行**: `LSUIElement=true`（不显示 Dock 图标）
- **激活策略**: `.accessory`（隐藏 Dock 图标，仅接收事件）
- **超时机制**: 60 秒无点击自动退出
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
