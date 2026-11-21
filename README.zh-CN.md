# VS Code 和 Cursor 空间清理工具

[English](README.md)

在 macOS 上查看并清理 VS Code 和 Cursor 的缓存、日志、本地文件历史及应用状态。配置文件和全局状态数据库可选择压缩备份。

## 安装

脚本支持 macOS 自带的 Bash 3.2。项目可放在任意目录，路径中可以有空格。

```bash
git clone https://github.com/ThendCN/vscode-cursor-cleanup.git
cd vscode-cursor-cleanup
bash setup.sh
```

如果下载的是 ZIP，解压后进入项目目录，运行 `bash setup.sh`。然后执行安装脚本打印的 `source` 命令，让别名在当前终端生效。

安装脚本会更新 zsh 的启动配置，或 Bash 的 `~/.bashrc`。Bash 登录 shell 需要加载 `~/.bashrc` 才能自动获得别名。移动项目目录后，或遇到旧别名仍指向原目录时，在想使用的项目目录重新运行 `bash setup.sh`，再执行打印出的 `source` 命令。

## 使用

先退出要清理的应用，再运行以下命令，按提示选择清理项目。

| 命令 | 用途 |
| --- | --- |
| `cleanup-vscode` | 清理 VS Code |
| `cleanup-cursor` | 清理 Cursor |
| `cleanup-both` | 依次清理 VS Code 和 Cursor |
| `cleanup-help` | 在终端查看中文说明 |

也可以在项目目录直接运行脚本。

```bash
bash vscode-cursor-cleanup.sh --dry-run         # 预览两个应用
cleanup-cursor --dry-run                       # 只预览 Cursor
bash vscode-cursor-cleanup.sh                   # 交互选择应用
bash vscode-cursor-cleanup.sh --help
```

脚本会检查 `~/Library/Application Support/Code` 和 `~/Library/Application Support/Cursor`。`--dry-run` 会列出各项目的磁盘占用和是否可清理。即使同时指定 `--yes`，预览也只读取数据，不询问、不备份，也不删除文件。

默认可清理的项目是缓存和日志。要清理本地文件历史，请加 `--clear-history`。要重置 `state.vscdb`，请加 `--reset-state`。两个选项可以单独使用，也可以一起使用。`--yes` 会自动确认所有已启用的操作，包括重置数据库时的两次确认。

| 步骤 | 涉及的数据 |
| --- | --- |
| 1. 应用缓存 | 应用生成的缓存，可按需重建 |
| 2. 扩展安装包缓存 | 已下载的扩展安装包 |
| 3. 渲染缓存 | GPU、浏览器、代码和 Dawn 缓存 |
| 4. 日志 | 已有的应用日志 |
| 5. 本地文件历史（`--clear-history`） | 编辑器保存的本地文件快照 |
| 6. 全局状态数据库（`--reset-state`） | 可能包含 Cursor 聊天记录、最近打开的项目、界面状态及扩展状态 |

## 备份与恢复

选择备份配置时，脚本会保存已有的 `settings.json`、`keybindings.json` 和 `snippets`。如果选择重置 `state.vscdb`，脚本会另行询问是否备份该文件。ZIP 会保存到 `~/Desktop`，文件名以 `vscode-backup-` 或 `cursor-backup-` 开头。

恢复时，先退出应用并解压 ZIP。进入对应的应用数据目录，把 ZIP 中 `config/` 的内容复制回 `User/`。如果 ZIP 中有 `state.vscdb`，先把现有的 `state.vscdb`、`state.vscdb-wal` 和 `state.vscdb-shm`（如果存在）移到其他位置，再将备份中的数据库复制到 `User/globalStorage/`。备份覆盖上述配置和数据库文件，缓存、日志及本地文件历史在备份范围之外。

## 卸载

```bash
cleanup-uninstall
```

这条命令会从 shell 启动配置和当前终端移除本工具的命令别名。修改前会备份启动配置，备份文件的后缀是 `.vscode-cursor-cleanup.bak`。如果其他终端已经加载了这些别名，重新打开相应的终端即可。

如果 `cleanup-uninstall` 不可用，可以在项目目录运行 `bash setup.sh --uninstall`，然后重新打开终端。如需移除项目文件，卸载别名后可自行删除项目目录。

[MIT 许可证](LICENSE)
