#!/bin/sh
# Report disk usage; --clean removes only the allowlisted caches below
# and prunes unused packages from the pnpm store.
set -eu

usage() {
    printf 'Usage: %s [--clean | --help]\n' "$0"
}

mode=report
case "$#" in
    0) ;;
    1)
        case "$1" in
            --clean) mode=clean ;;
            --help|-h) usage; exit 0 ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    *) usage >&2; exit 2 ;;
esac

# Use the current user's home; refuse anything that is not clearly theirs.
home=${HOME:-}
case "$home" in
    /|''|[!/]*)
        printf 'Refusing: HOME must be an absolute path other than /: %s\n' "$home" >&2
        exit 1
        ;;
esac
if [ ! -d "$home" ] || [ ! -O "$home" ]; then
    printf 'Refusing: HOME is not a directory owned by you: %s\n' "$home" >&2
    exit 1
fi

# Fixed allowlist under $home. Never accept deletion paths from arguments.
brave_profile="$home/.config/BraveSoftware/Brave-Browser/Default"
set -- \
    "$home/.npm/_cacache" \
    "$home/.cache/pip" \
    "$home/.cache/yarn" \
    "$home/.cache/BraveSoftware" \
    "$home/.cache/gnome-software" \
    "$home/.cache/pnpm" \
    "$home/.cache/uv" \
    "$home/.npm/_npx" \
    "$home/.cache/go-build" \
    "$home/.cache/node-gyp" \
    "$home/.config/Cursor/CachedData" \
    "$home/.config/Code/CachedExtensionVSIXs" \
    "$brave_profile/Service Worker/CacheStorage" \
    "$brave_profile/IndexedDB/https_www.youtube.com_0.indexeddb.leveldb" \
    "$brave_profile/IndexedDB/https_www.youtube.com_0.indexeddb.blob"

printf '\nDisk space:\n'
df -h "$home"

printf '\nTargeted caches:\n'
for path do
    if [ -e "$path" ] || [ -L "$path" ]; then
        du -sh -- "$path"
    else
        printf 'Already absent: %s\n' "$path"
    fi
done

printf '\nBefore cleanup: close Brave, Software Center, Cursor and VS Code; finish package installs and builds.\n'

if [ "$mode" = clean ]; then
    # Deleting live profile data corrupts it; Brave must be fully closed.
    if pgrep -x brave >/dev/null 2>&1; then
        printf 'Refusing cleanup: Brave is running. Quit it completely and retry.\n' >&2
        exit 1
    fi
    # Refuse redirected parent directories; do not follow them outside the allowlist.
    for parent in "$home/.npm" "$home/.cache" "$home/.config" \
        "$home/.config/Cursor" "$home/.config/Code" \
        "$home/.config/BraveSoftware" "$home/.config/BraveSoftware/Brave-Browser" \
        "$brave_profile" "$brave_profile/IndexedDB" "$brave_profile/Service Worker"; do
        if [ -L "$parent" ]; then
            printf 'Refusing cleanup: parent is a symlink: %s\n' "$parent" >&2
            exit 1
        fi
    done
    printf '\nRemoving only the listed caches...\n'
    rm -rf -- "$@"
    if command -v pnpm >/dev/null 2>&1; then
        printf '\nPruning unused packages from the pnpm store...\n'
        # A failed prune should not hide the final disk report.
        pnpm store prune || printf 'pnpm store prune failed; continuing.\n' >&2
    fi
    printf '\nCleanup complete. Disk space now:\n'
    df -h "$home"
else
    printf '\nLargest home entries (including hidden folders; total is first):\n'
    # Ignore unreadable directories; du still reports the accessible entries.
    du -xh --max-depth=1 "$home" 2>/dev/null | sort -hr | head -n 15
    printf '\nTo delete ONLY the allowlisted caches above and prune the pnpm store, run:\n'
    printf '  %s --clean\n' "$0"
fi
