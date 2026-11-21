# VS Code and Cursor Cleanup

[简体中文](README.zh-CN.md)

An interactive macOS tool for checking disk usage and clearing caches, logs, local file history, and editor state in VS Code and Cursor. Configuration and the global state database can be backed up to a ZIP archive.

## Install

The scripts run on macOS with the built-in Bash 3.2. Leave the project in any folder, including one with spaces in its path.

```bash
git clone https://github.com/ThendCN/vscode-cursor-cleanup.git
cd vscode-cursor-cleanup
bash setup.sh
```

If you downloaded a ZIP, extract it and run `bash setup.sh` from the extracted folder. Run the `source` command printed by the installer to activate the aliases in your current terminal.

The installer updates the aliases in your zsh startup file or Bash’s `~/.bashrc`. Bash login shells need to load `~/.bashrc` to pick up the aliases automatically. If you move the project or have aliases from an older installation, run `bash setup.sh` from the folder you want to use, then run the printed `source` command again.

## Use

Quit the apps you want to clean, then run one of these commands and respond to the prompts.

| Command | Action |
| --- | --- |
| `cleanup-vscode` | Clean VS Code |
| `cleanup-cursor` | Clean Cursor |
| `cleanup-both` | Clean VS Code, then Cursor |
| `cleanup-help` | Open the Chinese README in the terminal |

You can also run the script directly from the project folder.

```bash
bash vscode-cursor-cleanup.sh --dry-run         # Preview both apps
cleanup-cursor --dry-run                       # Preview Cursor only
bash vscode-cursor-cleanup.sh                   # Choose an app interactively
bash vscode-cursor-cleanup.sh --help
```

The script looks in `~/Library/Application Support/Code` and `~/Library/Application Support/Cursor`. `--dry-run` lists each target, its disk usage, and whether it is eligible for cleanup. It runs without prompts, backups, or deletions, even when combined with `--yes`.

By default, cleanup offers to remove caches and logs. Use `--clear-history` to opt into deleting local file history and `--reset-state` to opt into resetting `state.vscdb`. The options work independently and can be combined. `--yes` automatically accepts prompts for any enabled operations, including the two additional confirmations for a state reset.

| Step | Data affected |
| --- | --- |
| 1. App cache | Cached app data, rebuilt as needed |
| 2. Extension package cache | Downloaded installation packages |
| 3. Rendering caches | GPU, browser, code, and Dawn caches |
| 4. Logs | Existing application logs |
| 5. Local file history (`--clear-history`) | Local snapshots stored by the editor |
| 6. Global state database (`--reset-state`) | May include Cursor chats, recently opened items, UI state, and extension state |

## Backup and restore

Choose configuration backup to save any existing `settings.json`, `keybindings.json`, and `snippets`. If you choose to reset `state.vscdb`, the script offers a separate backup prompt for that file. ZIP archives are saved to `~/Desktop` with a `vscode-backup-` or `cursor-backup-` prefix.

To restore, quit the app and extract the ZIP. In the app’s data folder, copy the contents of the archive’s `config/` back into `User/`. If the archive contains `state.vscdb`, first move any current `state.vscdb`, `state.vscdb-wal`, and `state.vscdb-shm` aside, then place the archived database in `User/globalStorage/`. Backups cover the files listed above. Cache, logs, and local file history are outside the backup.

## Uninstall

```bash
cleanup-uninstall
```

This removes the tool’s aliases from the shell startup file and the current terminal. Before updating the startup file, the installer saves a copy with a `.vscode-cursor-cleanup.bak` suffix. Reopen any other terminals that still have the aliases loaded.

If `cleanup-uninstall` is unavailable, run `bash setup.sh --uninstall` from the project folder, then reopen your terminal. To remove the project files as well, delete the project folder after uninstalling the aliases.

[MIT License](LICENSE)
