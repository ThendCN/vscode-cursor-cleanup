#!/bin/bash
set -eu

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
TEST_DIR=$(mktemp -d /tmp/vscode-cursor-cleanup-test.XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

test_cleanup() {
    local test_home="$TEST_DIR/cleanup home"
    local app app_dir archive
    mkdir -p "$test_home/Desktop"
    for app in Code Cursor; do
        app_dir="$test_home/Library/Application Support/$app"
        mkdir -p "$app_dir/CachedData" "$app_dir/User/globalStorage"
        printf '{}\n' > "$app_dir/User/settings.json"
        printf 'fixture database for %s\n' "$app" > "$app_dir/User/globalStorage/state.vscdb"
    done

    HOME="$test_home" /bin/bash "$REPO_DIR/vscode-cursor-cleanup.sh" --app both --yes --reset-state > "$TEST_DIR/cleanup.log" ||
        fail 'cleanup should run and back up both apps using the system Bash'

    for app in Code Cursor; do
        app_dir="$test_home/Library/Application Support/$app"
        [ ! -d "$app_dir/CachedData" ] || fail "$app cache still exists"
        [ ! -f "$app_dir/User/globalStorage/state.vscdb" ] || fail "$app database still exists"
        [ -f "$app_dir/User/settings.json" ] || fail "$app settings were removed"
    done

    for app in vscode cursor; do
        set -- "$test_home/Desktop/""$app"-backup-*.zip
        [ "$#" -eq 1 ] && [ -f "$1" ] || fail "expected one ZIP for $app"
        archive=$1
        [ "$(unzip -p "$archive" config/settings.json)" = '{}' ] || fail "$app settings missing from ZIP"
        unzip -p "$archive" state.vscdb | grep -q '^fixture database for ' || fail "$app database missing from ZIP"
    done
}

test_cleanup_modes() {
    local test_home="$TEST_DIR/modes home"
    local app_dir="$test_home/Library/Application Support/Cursor"
    local history="$app_dir/User/History"
    local state="$app_dir/User/globalStorage/state.vscdb"
    local script="$REPO_DIR/vscode-cursor-cleanup.sh"
    local preview_log="$TEST_DIR/preview.log"
    mkdir -p "$test_home/Desktop" "$app_dir/CachedData" "$app_dir/Code Cache" "$history" "$(dirname "$state")"
    printf 'fixture history\n' > "$history/entry"
    printf 'fixture database\n' > "$state"

    HOME="$test_home" /bin/bash "$script" --app cursor --dry-run </dev/null > "$preview_log" ||
        fail 'dry run should work for a selected app'
    grep -Eq 'User/History.*--clear-history' "$preview_log" || fail 'dry run did not show that history needs an opt-in'
    grep -Eq 'state.vscdb.*--reset-state' "$preview_log" || fail 'dry run did not show that the database needs an opt-in'

    HOME="$test_home" /bin/bash "$script" --dry-run --yes --clear-history --reset-state </dev/null > "$preview_log" ||
        fail 'dry run should work with no app selected or interactive input'
    grep -Fq 'Code Cache' "$preview_log" || fail 'dry run omitted a rendering cache'
    grep -Fq 'User/History' "$preview_log" || fail 'dry run omitted local history'
    grep -Fq 'User/globalStorage/state.vscdb' "$preview_log" || fail 'dry run omitted the database'
    [ -d "$app_dir/CachedData" ] || fail 'dry run removed the app cache'
    [ -d "$app_dir/Code Cache" ] || fail 'dry run removed the rendering cache'
    [ -f "$history/entry" ] || fail 'dry run removed local history'
    [ -f "$state" ] || fail 'dry run removed the database'
    [ -z "$(ls -A "$test_home/Desktop")" ] || fail 'dry run created a backup'

    HOME="$test_home" /bin/bash "$script" --app cursor --clear-history --reset-state </dev/null > "$TEST_DIR/unconfirmed.log"
    [ -f "$history/entry" ] || fail 'opted-in history cleanup proceeded without confirmation'
    [ -f "$state" ] || fail 'opted-in database reset proceeded without confirmation'

    HOME="$test_home" /bin/bash "$script" --app cursor --yes > "$TEST_DIR/default-cleanup.log"
    [ ! -d "$app_dir/CachedData" ] || fail 'default cleanup left the app cache'
    [ ! -d "$app_dir/Code Cache" ] || fail 'default cleanup left the rendering cache'
    [ -f "$history/entry" ] || fail '--yes removed local history without --clear-history'
    [ -f "$state" ] || fail '--yes removed the database without --reset-state'

    HOME="$test_home" /bin/bash "$script" --app cursor --yes --clear-history > "$TEST_DIR/history-cleanup.log"
    [ ! -d "$history" ] || fail '--clear-history left local history'
    [ -f "$state" ] || fail '--clear-history also removed the database'
    mkdir -p "$history"
    printf 'fixture history\n' > "$history/entry"

    HOME="$test_home" /bin/bash "$script" --app cursor --yes --reset-state > "$TEST_DIR/state-cleanup.log"
    [ ! -f "$state" ] || fail '--reset-state left the database'
    [ -f "$history/entry" ] || fail '--reset-state also removed local history'
}

test_setup() {
    local shell_path=$1
    local test_home="$TEST_DIR/${shell_path##*/} home"
    local checkout="$TEST_DIR/checkout & son's \$copy"
    local rc rc_dir app app_dir
    mkdir -p "$test_home" "$checkout"
    cp "$REPO_DIR/setup.sh" "$REPO_DIR/vscode-cursor-cleanup.sh" "$REPO_DIR"/README*.md "$checkout/"

    if [ "$shell_path" = /bin/zsh ]; then
        rc_dir="$test_home/zsh config"
        mkdir -p "$rc_dir"
        rc="$rc_dir/.zshrc"
    else
        rc_dir="$test_home"
        rc="$test_home/.bashrc"
    fi
    cat > "$rc" <<'EOF'
# VSCode/Cursor 清理工具
alias cleanup-both="~/Projects/vscode-cursor-cleanup/vscode-cursor-cleanup.sh --app both"
alias cleanup-help="cat ~/Projects/vscode-cursor-cleanup/README.md"
keep_this_setting=preserved
alias personal-cleanup='echo personal'
EOF
    cp "$rc" "$TEST_DIR/legacy-config"

    (cd "$TEST_DIR" && HOME="$test_home" ZDOTDIR="$rc_dir" SHELL="$shell_path" /bin/bash "$checkout/setup.sh" </dev/null) > "$TEST_DIR/install.log" ||
        fail "installation should work from another directory in $shell_path"
    cp "$rc" "$TEST_DIR/first-install"
    HOME="$test_home" ZDOTDIR="$rc_dir" SHELL="$shell_path" /bin/bash "$checkout/setup.sh" </dev/null > "$TEST_DIR/reinstall.log"
    cmp -s "$rc" "$TEST_DIR/first-install" || fail 'reinstall changed the startup file again'
    cmp -s "$TEST_DIR/legacy-config" "$rc.vscode-cursor-cleanup.bak" || fail 'the original startup file was not backed up'

    for app in Code Cursor; do
        app_dir="$test_home/Library/Application Support/$app"
        mkdir -p "$app_dir/CachedData"
    done

    HOME="$test_home" "$shell_path" -c '
        if [ -n "${BASH_VERSION:-}" ]; then shopt -s expand_aliases; fi
        . "$1"
        [ "$keep_this_setting" = preserved ] || exit 1
        eval "cleanup-help" >/dev/null || exit 1
        eval "cleanup-both"
    ' smoke "$rc" </dev/null > "$TEST_DIR/aliases.log" || fail "installed aliases did not run in $shell_path"
    grep -q '开始清理 VSCode' "$TEST_DIR/aliases.log" || fail 'cleanup-both omitted VSCode'
    grep -q '开始清理 Cursor' "$TEST_DIR/aliases.log" || fail 'cleanup-both omitted Cursor'
    [ -d "$test_home/Library/Application Support/Code/CachedData" ] || fail 'EOF confirmed cache removal'

    HOME="$test_home" ZDOTDIR="$rc_dir" SHELL="$shell_path" "$shell_path" -c '
        if [ -n "${BASH_VERSION:-}" ]; then shopt -s expand_aliases; fi
        . "$1"
        eval "cleanup-uninstall" || exit 1
        for name in cleanup-cursor cleanup-vscode cleanup-both cleanup-help cleanup-uninstall; do
            if alias "$name" >/dev/null 2>&1; then exit 1; fi
        done
        alias personal-cleanup >/dev/null
    ' smoke "$rc" > "$TEST_DIR/uninstall.log" || fail "uninstall did not remove the aliases in $shell_path"

    printf '%s\n' 'keep_this_setting=preserved' "alias personal-cleanup='echo personal'" > "$TEST_DIR/expected-config"
    cmp -s "$rc" "$TEST_DIR/expected-config" || fail 'uninstall changed unrelated startup configuration'
    cmp -s "$TEST_DIR/first-install" "$rc.vscode-cursor-cleanup.bak" || fail 'uninstall did not back up the installed configuration'
    [ -f "$checkout/vscode-cursor-cleanup.sh" ] || fail 'uninstall removed the cleanup script'
    [ -d "$test_home/Library/Application Support/Code/CachedData" ] || fail 'uninstall removed app data'

    HOME="$test_home" ZDOTDIR="$rc_dir" SHELL="$shell_path" /bin/bash "$checkout/setup.sh" --uninstall > "$TEST_DIR/uninstall-again.log"
    cmp -s "$rc" "$TEST_DIR/expected-config" || fail 'repeat uninstall changed the startup configuration'
    cmp -s "$TEST_DIR/first-install" "$rc.vscode-cursor-cleanup.bak" || fail 'repeat uninstall overwrote the backup'
}

case ${1:-all} in
    cleanup) test_cleanup ;;
    modes) test_cleanup_modes ;;
    setup) test_setup /bin/zsh; test_setup /bin/bash ;;
    all) test_cleanup; test_cleanup_modes; test_setup /bin/zsh; test_setup /bin/bash ;;
    *) fail "unknown test: $1" ;;
esac
printf 'Smoke tests passed (%s).\n' "${1:-all}"
