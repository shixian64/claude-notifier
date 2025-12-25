# ClaudeNotifier Makefile (Linux)

PREFIX ?= $(HOME)/.claude
BIN_DIR = $(PREFIX)/bin
ICON_DIR = $(PREFIX)/icons
SOUNDS_DIR = $(PREFIX)/sounds

APP_NAME = claude-notifier
SVG_ICON = resources/claude-starburst.svg
PNG_ICON = $(ICON_DIR)/claude-notifier.png

.PHONY: all install uninstall clean help check-deps

all: check-deps

check-deps:
	@echo "检查依赖..."
	@command -v notify-send >/dev/null 2>&1 || { echo "❌ 缺少 notify-send，请安装: sudo apt install libnotify-bin"; exit 1; }
	@command -v convert >/dev/null 2>&1 || { echo "❌ 缺少 ImageMagick，请安装: sudo apt install imagemagick"; exit 1; }
	@echo "✅ 依赖检查通过"

install: check-deps
	@echo "安装 ClaudeNotifier..."
	@mkdir -p $(BIN_DIR) $(ICON_DIR) $(SOUNDS_DIR)

	@# 转换 SVG 为 PNG
	@echo "转换图标..."
	@convert -background none $(SVG_ICON) -resize 128x128 $(PNG_ICON)

	@# 安装脚本
	@echo "安装脚本..."
	@install -m 755 src/claude-notifier.sh $(BIN_DIR)/$(APP_NAME)

	@# 复制默认音效（如果存在）
	@if [ -f ../sounds/done.wav ]; then cp ../sounds/done.wav $(SOUNDS_DIR)/; fi

	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✅ 安装完成！"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📍 安装路径: $(BIN_DIR)/$(APP_NAME)"
	@echo "🖼️  图标路径: $(PNG_ICON)"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📋 下一步操作"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1️⃣  测试通知:"
	@echo "    $(BIN_DIR)/$(APP_NAME) -t '测试' -m '通知配置成功'"
	@echo ""
	@echo "2️⃣  配置 Claude Code Hooks:"
	@echo "    编辑 ~/.claude/settings.json，添加以下内容:"
	@echo ""
	@echo '    {'
	@echo '      "hooks": {'
	@echo '        "Stop": [{'
	@echo '          "matcher": "",'
	@echo '          "hooks": [{'
	@echo '            "type": "command",'
	@echo '            "command": "$(BIN_DIR)/$(APP_NAME) -t '\''Claude Code'\'' -m '\''Claude 已完成回答'\''"'
	@echo '          }]'
	@echo '        }]'
	@echo '      }'
	@echo '    }'
	@echo ""
	@echo "3️⃣  生成自定义语音音效:"
	@echo "    espeak -v zh '搞定咯' --stdout | ffmpeg -i - -ar 44100 ~/.claude/sounds/done.wav"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📖 详细文档: https://github.com/zengwenliang416/claude-notifier"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

uninstall:
	@echo "卸载 ClaudeNotifier..."
	@rm -f $(BIN_DIR)/$(APP_NAME)
	@rm -f $(PNG_ICON)
	@echo "✅ 卸载完成"

clean:
	@echo "清理..."
	@echo "✅ 清理完成"

help:
	@echo "ClaudeNotifier - Linux 桌面通知工具"
	@echo ""
	@echo "用法:"
	@echo "  make              检查依赖"
	@echo "  make install      安装到 $(PREFIX)"
	@echo "  make uninstall    卸载"
	@echo "  make help         显示此帮助"
	@echo ""
	@echo "选项:"
	@echo "  PREFIX=<path>     自定义安装前缀 (默认: ~/.claude)"
