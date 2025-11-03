#!/bin/bash

# VSCode/Cursor 安全清理脚本
# 支持交互式确认每个清理步骤

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -a, --app [vscode|cursor]  指定要清理的应用（不指定则交互选择）"
    echo "  -y, --yes                  自动确认所有操作（谨慎使用）"
    echo "  -h, --help                 显示此帮助信息"
    echo ""
}

# 解析命令行参数
AUTO_YES=false
APP_TYPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--app)
            APP_TYPE="$2"
            shift 2
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 询问函数
ask_confirm() {
    if [ "$AUTO_YES" = true ]; then
        return 0
    fi

    local prompt="$1"
    local default="${2:-N}"

    if [ "$default" = "Y" ]; then
        read -p "$prompt (Y/n): " -n 1 -r
    else
        read -p "$prompt (y/N): " -n 1 -r
    fi
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 显示大小
show_size() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sh "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "0B"
    fi
}

# 压缩备份函数
zip_backup() {
    local source="$1"
    local zip_file="$2"
    local description="$3"

    if [ -e "$source" ]; then
        local original_size=$(show_size "$source")
        echo -e "   📦 压缩 ${description}... (原始大小: ${original_size})"

        if [ -d "$source" ]; then
            # 目录压缩
            (cd "$(dirname "$source")" && zip -r -q "$zip_file" "$(basename "$source")")
        else
            # 文件压缩
            zip -j -q "$zip_file" "$source"
        fi

        if [ -f "$zip_file" ]; then
            local zip_size=$(show_size "$zip_file")
            echo -e "   ${GREEN}✅ 已压缩: ${original_size} → ${zip_size}${NC}"
            return 0
        else
            echo -e "   ${RED}❌ 压缩失败${NC}"
            return 1
        fi
    else
        echo -e "   ${BLUE}ℹ️  ${description} 不存在，跳过${NC}"
        return 1
    fi
}

# 清理函数
cleanup_path() {
    local path="$1"
    local description="$2"

    if [ -e "$path" ]; then
        rm -rf "$path"
        echo -e "${GREEN}✅ 已删除${NC}"
    else
        echo -e "${BLUE}ℹ️  路径不存在，跳过${NC}"
    fi
}

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}   VSCode/Cursor 空间清理工具${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# 选择应用
if [ -z "$APP_TYPE" ]; then
    echo "请选择要清理的应用:"
    echo "1) VSCode"
    echo "2) Cursor"
    echo "3) 两者都清理"
    read -p "请输入选项 (1-3): " -n 1 -r app_choice
    echo ""

    case $app_choice in
        1) APP_TYPE="vscode" ;;
        2) APP_TYPE="cursor" ;;
        3) APP_TYPE="both" ;;
        *)
            echo -e "${RED}❌ 无效选项${NC}"
            exit 1
            ;;
    esac
fi

# 设置目录路径
declare -A APPS
if [ "$APP_TYPE" = "vscode" ] || [ "$APP_TYPE" = "both" ]; then
    APPS["VSCode"]="/Users/thend/Library/Application Support/Code"
fi
if [ "$APP_TYPE" = "cursor" ] || [ "$APP_TYPE" = "both" ]; then
    APPS["Cursor"]="/Users/thend/Library/Application Support/Cursor"
fi

# 处理每个应用
for APP_NAME in "${!APPS[@]}"; do
    APP_DIR="${APPS[$APP_NAME]}"

    if [ ! -d "$APP_DIR" ]; then
        echo -e "${YELLOW}⚠️  ${APP_NAME} 目录不存在，跳过${NC}"
        echo ""
        continue
    fi

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🎯 开始清理 ${APP_NAME}${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 检查应用是否在运行
    if pgrep -x "$APP_NAME" > /dev/null; then
        echo -e "${RED}❌ ${APP_NAME} 正在运行！${NC}"
        if ask_confirm "是否要继续？（建议先关闭应用）"; then
            echo -e "${YELLOW}⚠️  继续执行，可能导致数据丢失${NC}"
        else
            echo "跳过 ${APP_NAME}"
            continue
        fi
    fi

    # 显示当前占用
    TOTAL_SIZE=$(show_size "$APP_DIR")
    echo -e "📊 当前总占用: ${BLUE}${TOTAL_SIZE}${NC}"
    echo ""

    # 备份配置
    BACKUP_CREATED=false
    BACKUP_ZIP=""

    echo -e "${BLUE}💾 配置文件备份${NC}"
    echo "   建议：在清理前备份重要配置"

    if ask_confirm "   是否备份配置文件？"; then
        BACKUP_ZIP=~/Desktop/${APP_NAME,,}-backup-$(date +%Y%m%d-%H%M%S).zip
        TEMP_BACKUP_DIR=$(mktemp -d)
        BACKUP_CREATED=true

        echo -e "   📦 准备备份到: ${BACKUP_ZIP}"

        # 收集备份文件到临时目录
        mkdir -p "$TEMP_BACKUP_DIR/config"
        [ -f "$APP_DIR/User/settings.json" ] && cp "$APP_DIR/User/settings.json" "$TEMP_BACKUP_DIR/config/"
        [ -f "$APP_DIR/User/keybindings.json" ] && cp "$APP_DIR/User/keybindings.json" "$TEMP_BACKUP_DIR/config/"
        [ -d "$APP_DIR/User/snippets" ] && cp -r "$APP_DIR/User/snippets" "$TEMP_BACKUP_DIR/config/"

        # 压缩备份
        (cd "$TEMP_BACKUP_DIR" && zip -r -q "$BACKUP_ZIP" .)
        rm -rf "$TEMP_BACKUP_DIR"

        if [ -f "$BACKUP_ZIP" ]; then
            BACKUP_SIZE=$(show_size "$BACKUP_ZIP")
            echo -e "   ${GREEN}✅ 配置已备份: ${BACKUP_SIZE}${NC}"
        fi
    else
        echo -e "   ${BLUE}ℹ️  跳过备份${NC}"
    fi
    echo ""

    # 1. 清理缓存数据
    echo -e "${YELLOW}[1/6] 清理应用缓存${NC}"
    CACHE_SIZE=$(show_size "$APP_DIR/CachedData")
    echo "   预计释放: ${CACHE_SIZE}"
    if ask_confirm "   是否清理 CachedData？（安全，会自动重建）"; then
        cleanup_path "$APP_DIR/CachedData" "应用缓存"
    fi
    echo ""

    # 2. 清理扩展缓存
    echo -e "${YELLOW}[2/6] 清理扩展安装包缓存${NC}"
    EXT_SIZE=$(show_size "$APP_DIR/CachedExtensionVSIXs")
    echo "   预计释放: ${EXT_SIZE}"
    if ask_confirm "   是否清理 CachedExtensionVSIXs？（安全，会自动重建）"; then
        cleanup_path "$APP_DIR/CachedExtensionVSIXs" "扩展缓存"
    fi
    echo ""

    # 3. 清理 GPU 缓存
    echo -e "${YELLOW}[3/6] 清理 GPU 和渲染缓存${NC}"
    GPU_SIZE=$(du -sh "$APP_DIR/GPUCache" "$APP_DIR/Cache" "$APP_DIR/Code Cache" \
               "$APP_DIR/DawnCache" "$APP_DIR/DawnGraphiteCache" "$APP_DIR/DawnWebGPUCache" \
               2>/dev/null | awk '{sum+=$1} END {print sum "M"}' || echo "未知")
    echo "   预计释放: ${GPU_SIZE}"
    if ask_confirm "   是否清理 GPU 缓存？（安全，会自动重建）"; then
        cleanup_path "$APP_DIR/GPUCache" "GPU 缓存"
        cleanup_path "$APP_DIR/Cache" "通用缓存"
        cleanup_path "$APP_DIR/Code Cache" "代码缓存"
        cleanup_path "$APP_DIR/DawnCache" "Dawn 缓存"
        cleanup_path "$APP_DIR/DawnGraphiteCache" "DawnGraphite 缓存"
        cleanup_path "$APP_DIR/DawnWebGPUCache" "DawnWebGPU 缓存"
    fi
    echo ""

    # 4. 清理日志文件
    echo -e "${YELLOW}[4/6] 清理日志文件${NC}"
    LOG_SIZE=$(show_size "$APP_DIR/logs")
    echo "   预计释放: ${LOG_SIZE}"
    if ask_confirm "   是否清理日志？（安全，会丢失历史日志）"; then
        cleanup_path "$APP_DIR/logs" "日志文件"
    fi
    echo ""

    # 5. 清理编辑历史
    echo -e "${YELLOW}[5/6] 清理本地编辑历史${NC}"
    HISTORY_SIZE=$(show_size "$APP_DIR/User/History")
    HISTORY_COUNT=$(find "$APP_DIR/User/History" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "   预计释放: ${HISTORY_SIZE} (${HISTORY_COUNT} 个文件)"
    echo -e "   ${RED}⚠️  警告: 会删除本地撤销历史（不影响 Git）${NC}"
    if ask_confirm "   是否清理编辑历史？（中等风险）"; then
        cleanup_path "$APP_DIR/User/History" "编辑历史"
    fi
    echo ""

    # 6. 清理 state.vscdb（最危险操作）
    echo -e "${YELLOW}[6/6] 清理全局状态数据库${NC}"
    STATE_FILE="$APP_DIR/User/globalStorage/state.vscdb"
    if [ -f "$STATE_FILE" ]; then
        STATE_SIZE=$(show_size "$STATE_FILE")
        echo "   当前大小: ${STATE_SIZE}"
        echo -e "   ${RED}⚠️  高风险操作！会丢失：${NC}"
        echo "   - AI 聊天历史（Cursor）"
        echo "   - 最近打开文件列表"
        echo "   - UI 状态和布局"
        echo "   - 扩展状态数据"

        # 根据大小给出建议
        STATE_SIZE_MB=$(du -m "$STATE_FILE" 2>/dev/null | awk '{print $1}')
        if [ "$STATE_SIZE_MB" -gt 1000 ]; then
            echo -e "   ${YELLOW}💡 建议：数据库异常膨胀（${STATE_SIZE}），建议重置${NC}"
        fi

        if ask_confirm "   是否重置 state.vscdb？（高风险）"; then
            # 额外确认
            echo -e "   ${RED}⚠️  最后确认：此操作不可逆！${NC}"
            if ask_confirm "   确定要删除吗？"; then
                # 询问是否备份
                echo ""
                echo -e "   ${BLUE}💾 强烈建议备份 state.vscdb${NC}"
                if ask_confirm "   是否压缩备份 state.vscdb？（推荐）"; then
                    # 如果之前没有创建备份，创建新的
                    if [ -z "$BACKUP_ZIP" ]; then
                        BACKUP_ZIP=~/Desktop/${APP_NAME,,}-backup-$(date +%Y%m%d-%H%M%S).zip
                        BACKUP_CREATED=true
                    fi

                    # 备份到临时目录再添加到 zip
                    TEMP_DIR=$(mktemp -d)
                    echo "   📦 压缩备份 state.vscdb..."
                    cp "$STATE_FILE" "$TEMP_DIR/state.vscdb"

                    # 添加到现有 zip 或创建新 zip
                    (cd "$TEMP_DIR" && zip -q "$BACKUP_ZIP" state.vscdb)
                    rm -rf "$TEMP_DIR"

                    if [ -f "$BACKUP_ZIP" ]; then
                        BACKUP_SIZE=$(show_size "$BACKUP_ZIP")
                        echo -e "   ${GREEN}✅ 已备份到: ${BACKUP_ZIP} (${BACKUP_SIZE})${NC}"
                    fi
                fi

                echo ""
                cleanup_path "$STATE_FILE" "状态数据库"
                echo -e "   ${GREEN}✅ 已删除（应用重启后会重建）${NC}"
            fi
        fi
    else
        echo -e "   ${BLUE}ℹ️  state.vscdb 不存在${NC}"
    fi
    echo ""

    # 清理后统计
    if [ -d "$APP_DIR" ]; then
        NEW_SIZE=$(show_size "$APP_DIR")
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✨ ${APP_NAME} 清理完成！${NC}"
        echo -e "📊 清理前: ${TOTAL_SIZE} → 清理后: ${NEW_SIZE}"
        if [ "$BACKUP_CREATED" = true ] && [ -f "$BACKUP_ZIP" ]; then
            BACKUP_SIZE=$(show_size "$BACKUP_ZIP")
            echo -e "💾 备份位置: ${BACKUP_ZIP} (${BACKUP_SIZE})"
        fi
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    echo ""
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 所有清理任务完成！${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "📝 ${YELLOW}后续步骤:${NC}"
echo "   1. 重启 VSCode/Cursor"
echo "   2. 检查应用是否正常运行"
echo "   3. 如有问题，从备份目录恢复文件"
echo ""
