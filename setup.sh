#!/bin/bash

# 为默认 shell 安装或移除命令别名。
set -e

show_usage() {
    printf '用法: bash setup.sh [--uninstall]\n'
}

if [ "$#" -gt 1 ]; then
    show_usage >&2
    exit 1
fi

UNINSTALL=false
case ${1:-} in
    '') ;;
    --uninstall) UNINSTALL=true ;;
    -h|--help) show_usage; exit 0 ;;
    *) show_usage >&2; exit 1 ;;
esac

case "${SHELL##*/}" in
    zsh) SHELL_RC="${ZDOTDIR:-$HOME}/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bashrc" ;;
    *)
        echo "无法识别默认 shell，请在 zsh 或 Bash 下配置别名。" >&2
        exit 1
        ;;
esac

CONFIG_MARKER='# VSCode/Cursor 清理工具'
if [ "$UNINSTALL" = true ] && ! grep -Fxq "$CONFIG_MARKER" "$SHELL_RC" 2>/dev/null; then
    printf '未找到可卸载的清理工具别名：%s\n' "$SHELL_RC"
    exit 0
fi

UPDATED_RC=$(mktemp)
trap 'rm -f "$UPDATED_RC"' EXIT

if [ -f "$SHELL_RC" ]; then
    # 只移除安装标记及紧随其后的工具别名。
    awk -v marker="$CONFIG_MARKER" '
        $0 == marker { managed = 1; next }
        managed && /^alias cleanup-(cursor|vscode|both|help|uninstall)=/ { next }
        { managed = 0; print }
    ' "$SHELL_RC" > "$UPDATED_RC"
fi

if [ "$UNINSTALL" = false ]; then
    PROJECT_DIR=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
    CLEANUP_SCRIPT="$PROJECT_DIR/vscode-cursor-cleanup.sh"
    HELP_FILE="$PROJECT_DIR/README.zh-CN.md"
    if [ ! -f "$CLEANUP_SCRIPT" ] || [ ! -f "$HELP_FILE" ]; then
        echo "缺少清理脚本或说明文档，请从完整的项目目录运行 setup.sh。" >&2
        exit 1
    fi

    # 先转义命令里的路径，再转义整个别名值。
    printf -v cleanup_command '/bin/bash %q' "$CLEANUP_SCRIPT"
    printf -v help_command 'cat %q' "$HELP_FILE"
    printf -v uninstall_command '/bin/bash %q --uninstall' "$PROJECT_DIR/setup.sh"
    unalias_command='builtin unalias cleanup-cursor cleanup-vscode cleanup-both cleanup-help cleanup-uninstall'
    {
        printf '%s\n' "$CONFIG_MARKER"
        printf 'alias cleanup-cursor=%q\n' "$cleanup_command --app cursor"
        printf 'alias cleanup-vscode=%q\n' "$cleanup_command --app vscode"
        printf 'alias cleanup-both=%q\n' "$cleanup_command --app both"
        printf 'alias cleanup-help=%q\n' "$help_command"
        printf 'alias cleanup-uninstall=%q\n' "$uninstall_command && $unalias_command"
    } >> "$UPDATED_RC"
fi

if ! cmp -s "$UPDATED_RC" "$SHELL_RC"; then
    if [ -f "$SHELL_RC" ]; then
        BACKUP_RC="$SHELL_RC.vscode-cursor-cleanup.bak"
        cp -p "$SHELL_RC" "$BACKUP_RC"
        printf '原配置已备份到 %s\n' "$BACKUP_RC"
    fi
    cat "$UPDATED_RC" > "$SHELL_RC"
fi

if [ "$UNINSTALL" = true ]; then
    printf '已从 %s 移除清理工具别名。\n' "$SHELL_RC"
else
    printf '可用命令：cleanup-cursor、cleanup-vscode、cleanup-both、cleanup-help、cleanup-uninstall\n'
    printf '运行以下命令，使配置在当前终端生效：\n  source %q\n' "$SHELL_RC"
fi
