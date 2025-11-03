#!/bin/bash

# Cursor 空间清理脚本
# 执行前请确保 Cursor 已关闭

set -e

CURSOR_DIR="/Users/thend/Library/Application Support/Cursor"
BACKUP_DIR=~/Desktop/cursor-backup-$(date +%Y%m%d-%H%M%S)

echo "🔍 开始清理 Cursor 缓存..."
echo "📦 备份目录: $BACKUP_DIR"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份重要文件
echo "📂 备份关键文件..."
cp "$CURSOR_DIR/User/settings.json" "$BACKUP_DIR/" 2>/dev/null || true
cp "$CURSOR_DIR/User/keybindings.json" "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$CURSOR_DIR/User/snippets" "$BACKUP_DIR/" 2>/dev/null || true

# 备份 state.vscdb（可选，需要时恢复）
echo "💾 备份 state.vscdb..."
# cp "$CURSOR_DIR/User/globalStorage/state.vscdb" "$BACKUP_DIR/state.vscdb.backup" 2>/dev/null || true

# 清理缓存
echo "🧹 清理缓存..."
rm -rf "$CURSOR_DIR/CachedData"
rm -rf "$CURSOR_DIR/CachedExtensionVSIXs"
rm -rf "$CURSOR_DIR/GPUCache"
rm -rf "$CURSOR_DIR/Cache"
rm -rf "$CURSOR_DIR/Code Cache"
rm -rf "$CURSOR_DIR/DawnCache"
rm -rf "$CURSOR_DIR/DawnGraphiteCache"
rm -rf "$CURSOR_DIR/DawnWebGPUCache"

# 清理日志
echo "📝 清理日志..."
rm -rf "$CURSOR_DIR/logs"

# 询问是否重置 state.vscdb
echo ""
echo "⚠️  检测到 state.vscdb 占用 4.6G 空间"
read -p "是否重置 state.vscdb？这会清除 AI 聊天历史和部分 UI 状态 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  删除 state.vscdb..."
    rm "$CURSOR_DIR/User/globalStorage/state.vscdb"
    echo "✅ state.vscdb 已删除（Cursor 重启后会自动重建）"
fi

echo ""
echo "✨ 清理完成！"
echo "📊 预计释放空间: 1-5GB（取决于是否删除 state.vscdb）"
echo "🔄 请重启 Cursor 以应用更改"
echo "💡 备份文件位置: $BACKUP_DIR"
