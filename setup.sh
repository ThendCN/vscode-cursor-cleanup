#!/bin/bash

# 快速设置脚本 - 自动配置命令别名

echo "🚀 VSCode/Cursor 清理工具 - 快速设置"
echo ""

# 检测 shell
SHELL_RC=""
if [ -f ~/.zshrc ]; then
    SHELL_RC=~/.zshrc
    SHELL_NAME="zsh"
elif [ -f ~/.bashrc ]; then
    SHELL_RC=~/.bashrc
    SHELL_NAME="bash"
else
    echo "❌ 未找到 .zshrc 或 .bashrc 文件"
    exit 1
fi

echo "检测到 shell: $SHELL_NAME"
echo "配置文件: $SHELL_RC"
echo ""

# 检查是否已经配置
if grep -q "VSCode/Cursor 清理工具" "$SHELL_RC" 2>/dev/null; then
    echo "⚠️  检测到已存在配置"
    read -p "是否覆盖现有配置？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 取消设置"
        exit 0
    fi

    # 删除旧配置
    sed -i.bak '/# VSCode\/Cursor 清理工具/,/^$/d' "$SHELL_RC"
fi

# 添加别名配置
cat >> "$SHELL_RC" << 'EOF'

# VSCode/Cursor 清理工具
alias cleanup-cursor="~/Projects/vscode-cursor-cleanup/vscode-cursor-cleanup.sh --app cursor"
alias cleanup-vscode="~/Projects/vscode-cursor-cleanup/vscode-cursor-cleanup.sh --app vscode"
alias cleanup-both="~/Projects/vscode-cursor-cleanup/vscode-cursor-cleanup.sh --app both"
alias cleanup-help="cat ~/Projects/vscode-cursor-cleanup/README.md"

EOF

echo "✅ 别名已添加到 $SHELL_RC"
echo ""
echo "📋 可用命令："
echo "  cleanup-cursor    - 清理 Cursor"
echo "  cleanup-vscode    - 清理 VSCode"
echo "  cleanup-both      - 清理两者"
echo "  cleanup-help      - 查看帮助文档"
echo ""
echo "🔄 请运行以下命令使配置生效："
echo "   source $SHELL_RC"
echo ""
echo "或者关闭并重新打开终端"
