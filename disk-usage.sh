#!/bin/sh
# Report disk usage.
#   --clean           removes only the allowlisted caches below and prunes
#                     unused packages from the pnpm store.
#   --clean-projects  removes node_modules/ and target/ build folders under
#                     ~/pria-random.
set -eu

usage() {
    printf 'Usage: %s [--clean] [--clean-projects] | --help\n' "$0"
    printf '  --clean           delete the allowlisted caches and prune the pnpm store\n'
    printf '  --clean-projects  delete node_modules/ and target/ under ~/pria-random\n'
}

clean_caches=0
clean_projects=0
for arg do
    case "$arg" in
        --clean) clean_caches=1 ;;
        --clean-projects) clean_projects=1 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

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

# Fixed root for project build folders. Never accept it from arguments.
projects_root="$home/pria-random"

# Prints one line per node_modules/ or target/ under $projects_root.
# With "clean" as $1 it also deletes the ones that pass every check.
scan_projects() {
    action=$1
    if [ ! -d "$projects_root" ]; then
        printf 'Not found, skipping: %s\n' "$projects_root"
        return 0
    fi
    if [ -L "$projects_root" ] || [ ! -O "$projects_root" ]; then
        printf 'Refusing: %s is a symlink or not owned by you\n' "$projects_root" >&2
        exit 1
    fi
    # -type d never matches symlinks, and -prune stops at the first match,
    # so nested node_modules inside node_modules are not listed separately.
    find "$projects_root" -name .git -prune -o \
        -type d \( -name node_modules -o -name target \) -prune -print 2>/dev/null |
    {
        total_kb=0
        while IFS= read -r dir; do
            case "${dir##*/}" in
                node_modules) marker=package.json ;;
                *) marker=Cargo.toml ;;
            esac
            rel=${dir#"$projects_root"/}
            size=$(du -sh -- "$dir" 2>/dev/null | cut -f1)
            if [ ! -f "${dir%/*}/$marker" ]; then
                status="keep: no $marker beside it"
            else
                kb=$(du -sk -- "$dir" 2>/dev/null | cut -f1)
                total_kb=$((total_kb + kb))
                if [ "$action" = clean ]; then
                    rm -rf -- "$dir"
                    status="DELETED"
                else
                    status="would delete"
                fi
            fi
            printf '%6s  %-33s %s\n' "$size" "$status" "$rel"
        done
        if [ "$action" = clean ]; then
            label='Freed'
        else
            label='Would free'
        fi
        awk -v kb="$total_kb" -v label="$label" \
            'BEGIN { printf "%s: %.1f GB\n", label, kb / 1048576 }'
    }
}

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

if [ "$clean_caches" = 1 ]; then
    printf '\nBefore cleanup: close Brave, Software Center, Cursor and VS Code; finish package installs and builds.\n'
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
fi

if [ "$clean_projects" = 1 ]; then
    printf '\nProject build folders under %s (stop dev servers and builds first):\n' "$projects_root"
    scan_projects clean
else
    printf '\nProject build folders under %s:\n' "$projects_root"
    scan_projects report
fi

if [ "$clean_caches" = 1 ] || [ "$clean_projects" = 1 ]; then
    printf '\nCleanup complete. Disk space now:\n'
    df -h "$home"
else
    printf '\nLargest home entries (including hidden folders; total is first):\n'
    # Ignore unreadable directories; du still reports the accessible entries.
    du -xh --max-depth=1 "$home" 2>/dev/null | sort -hr | head -n 15
    printf '\nTo delete ONLY the allowlisted caches above and prune the pnpm store:\n'
    printf '  %s --clean\n' "$0"
    printf 'To delete the project build folders marked "would delete":\n'
    printf '  %s --clean-projects\n' "$0"
fi
