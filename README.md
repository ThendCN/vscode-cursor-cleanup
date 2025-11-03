# VSCode/Cursor 空间清理工具

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![Version](https://img.shields.io/badge/version-2.0-brightgreen.svg)

强大的 macOS 清理工具，支持 VSCode 和 Cursor 编辑器的空间管理和备份。

[特性](#-核心功能) • [安装](#-安装) • [使用](#-使用方法) • [文档](#-文档)

</div>

---

## 🌟 为什么选择这个工具？

- 💾 **节省 87% 备份空间** - ZIP 压缩技术将 4.6G 备份压缩至 615M
- 🛡️ **安全第一** - 每步确认、自动备份、进程检测
- ⚡ **释放 5.5GB 空间** - 深度清理可释放大量磁盘空间
- 🎯 **精准控制** - 6 个清理步骤独立确认
- 🔄 **一键恢复** - 出问题？从 ZIP 备份快速恢复

## 📊 清理效果对比

```
清理前：Cursor 占用 6.4G
├── state.vscdb: 4.6G  ← AI 聊天历史膨胀
├── 缓存数据: 700M
└── 编辑历史: 350M

清理后：Cursor 占用 850M (-5.5G)
备份大小：615M (ZIP 压缩)
净释放：4.9GB
```

## 🎯 核心功能

### ✨ 主要特性

| 特性 | 说明 |
|------|------|
| **ZIP 压缩备份** | 备份文件自动压缩，节省 87% 空间 |
| **交互式确认** | 每个清理步骤都需用户确认，安全可控 |
| **双应用支持** | 同时支持 VSCode 和 Cursor |
| **可选备份** | 用户可选择是否需要备份 |
| **进程检测** | 自动检测应用是否运行，避免数据损坏 |
| **二次确认** | 高风险操作（如删除 state.vscdb）需二次确认 |
| **一键设置** | 提供 setup.sh 快速配置命令别名 |

### 🧹 清理步骤

| 步骤 | 内容 | 风险 | 释放空间 |
|------|------|------|---------|
| 1 | 应用缓存 | 🟢 无 | ~450MB |
| 2 | 扩展缓存 | 🟢 无 | ~250MB |
| 3 | GPU 缓存 | 🟢 无 | ~10MB |
| 4 | 日志文件 | 🟢 无 | ~10MB |
| 5 | 编辑历史 | 🟡 低 | ~350MB |
| 6 | 状态数据库 | 🔴 高 | ~4.6GB |

## 🚀 安装

### 方法 1：克隆仓库（推荐）

```bash
# 克隆到 Projects 目录
git clone https://github.com/ThendCN/vscode-cursor-cleanup.git ~/Projects/vscode-cursor-cleanup

# 运行快速设置
~/Projects/vscode-cursor-cleanup/setup.sh

# 使配置生效
source ~/.zshrc
```

### 方法 2：手动下载

```bash
# 下载 ZIP 并解压到 ~/Projects/vscode-cursor-cleanup/
# 然后运行
chmod +x ~/Projects/vscode-cursor-cleanup/*.sh
~/Projects/vscode-cursor-cleanup/setup.sh
```

## 💻 使用方法

### 快速开始

```bash
# 1. 关闭 VSCode/Cursor

# 2. 运行清理工具
cleanup-cursor   # 清理 Cursor
cleanup-vscode   # 清理 VSCode
cleanup-both     # 清理两者

# 3. 按照提示选择清理项目
```

### 使用演示

```
═══════════════════════════════════════════════
   VSCode/Cursor 空间清理工具
═══════════════════════════════════════════════

请选择要清理的应用:
1) VSCode
2) Cursor
3) 两者都清理
请输入选项 (1-3): 2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 开始清理 Cursor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 当前总占用: 6.4G

💾 配置文件备份
   是否备份配置文件？ (y/N): y
   ✅ 配置已备份: 48KB

[1/6] 清理应用缓存
   预计释放: 453M
   是否清理？ (y/N): y
   ✅ 已删除

...
```

### 三种清理方案

#### 🟢 保守清理（推荐新手）

```bash
cleanup-cursor
# 清理：缓存 + 日志
# 释放：~700MB
# 风险：零
# 频率：每月
```

#### 🟡 标准清理（定期维护）

```bash
cleanup-cursor
# 清理：缓存 + 日志 + 编辑历史
# 释放：~1GB
# 风险：低
# 频率：每季度
```

#### 🔴 深度清理（state.vscdb 膨胀时）

```bash
cleanup-cursor
# 清理：所有项目 + state.vscdb
# 释放：~5.5GB
# 风险：高（需备份）
# 频率：仅当 state.vscdb > 2GB
```

## 📖 文档

| 文档 | 内容 |
|------|------|
| [README.md](./README.md) | 项目概览（本文件）|
| [清理工具使用说明_v2.md](./清理工具使用说明_v2.md) | 完整使用文档 |
| [v2更新摘要.md](./v2更新摘要.md) | v2.0 版本更新说明 |

## 🛡️ 安全机制

1. **进程检测** - 检查应用是否运行
2. **可选备份** - 每个备份都可选择
3. **二次确认** - 高风险操作需二次确认
4. **ZIP 压缩** - 自动压缩备份
5. **完整性校验** - ZIP 自带 CRC32 校验

## 🔧 恢复备份

```bash
# 使用一键恢复脚本（如果已创建）
~/Projects/vscode-cursor-cleanup/restore-backup.sh ~/Desktop/cursor-backup-xxx.zip Cursor

# 或手动恢复
unzip ~/Desktop/cursor-backup-xxx.zip -d ~/Desktop/restore
cp -r ~/Desktop/restore/config/* "/Users/$USER/Library/Application Support/Cursor/User/"
```

## 📊 技术细节

### 压缩效果

| 文件类型 | 原始大小 | 压缩后 | 压缩比 |
|---------|---------|-------|--------|
| state.vscdb | 4.6G | 615M | 87% |
| 配置文件 | 500KB | 48KB | 70% |

### 性能测试

- **平台**: Apple M1
- **压缩时间**: 45 秒（4.6G 文件）
- **解压时间**: 30 秒

## 💡 最佳实践

### 定期维护计划

```bash
# 每月：保守清理
cleanup-cursor  # 选择：清理步骤 1-4

# 每季度：标准清理
cleanup-cursor  # 选择：清理步骤 1-5

# 每半年：检查 state.vscdb
du -sh ~/Library/Application\ Support/Cursor/User/globalStorage/state.vscdb
# 超过 2GB 则执行深度清理
```

### 备份管理

```bash
# 查看所有备份
ls -lh ~/Desktop/*-backup-*.zip

# 保留最近 3 个备份
ls -t ~/Desktop/cursor-backup-*.zip | tail -n +4 | xargs rm

# 上传到云盘
cp ~/Desktop/cursor-backup-*.zip ~/Dropbox/backups/
```

## 🎓 常见问题

<details>
<summary><b>Q: 会丢失代码吗？</b></summary>

不会！脚本只清理缓存和状态，不触碰项目文件。
</details>

<details>
<summary><b>Q: 会丢失已安装的扩展吗？</b></summary>

不会！只清理扩展的缓存，扩展本身保留。
</details>

<details>
<summary><b>Q: 删除 state.vscdb 会丢失什么？</b></summary>

- ❌ AI 聊天历史（Cursor）
- ❌ 最近文件列表
- ❌ UI 状态
- ✅ 但可以从备份恢复！
</details>

<details>
<summary><b>Q: 压缩备份需要多久？</b></summary>

约 45 秒（4.6G 文件，M1 Mac）。时间换空间，值得！
</details>

<details>
<summary><b>Q: 支持 Windows/Linux 吗？</b></summary>

目前仅支持 macOS。Windows/Linux 需要修改路径。
</details>

## 🤝 贡献

欢迎贡献！请查看贡献指南：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 改进建议

- 🔄 Windows/Linux 支持
- 🔄 GUI 界面
- 🔄 自动清理旧备份
- 🔄 云盘备份集成

## ⚙️ 系统要求

- **操作系统**: macOS 10.14+
- **Shell**: Bash 3.2+
- **工具**: zip（系统自带）
- **应用**: VSCode 或 Cursor

## 📝 更新日志

### v2.0 (2025-11-03)
- ✅ 新增 ZIP 压缩备份（节省 87% 空间）
- ✅ 新增可选备份机制
- ✅ 优化分离确认流程
- ✅ 新增压缩比实时显示
- ✅ 新增快速设置脚本

### v1.0 (2025-11-03)
- 基础清理功能
- 自动备份机制
- 交互式确认

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## ⭐ Star History

如果这个工具帮到了你，请给个 Star ⭐！

---

<div align="center">

**[⬆ 回到顶部](#vscode-cursor-空间清理工具)**

Made with ❤️ by [ThendCN](https://github.com/ThendCN)

</div>
