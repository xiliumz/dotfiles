#!/bin/sh
# Report disk usage; --clean removes only the allowlisted caches below.
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

# Fixed allowlist. Never accept deletion paths from arguments or environment.
set -- \
    /home/user/.npm/_cacache \
    /home/user/.cache/pip \
    /home/user/.cache/yarn \
    /home/user/.cache/BraveSoftware \
    /home/user/.cache/gnome-software \
    /home/user/.cache/pnpm \
    /home/user/.cache/uv \
    /home/user/.npm/_npx

printf '\nDisk space:\n'
df -h /home/user

printf '\nTargeted caches:\n'
for path do
    if [ -e "$path" ] || [ -L "$path" ]; then
        du -sh -- "$path"
    else
        printf 'Already absent: %s\n' "$path"
    fi
done

printf '\nBefore cleanup: close Brave and Software Center; finish package installs.\n'

if [ "$mode" = clean ]; then
    # Refuse redirected parent directories; do not follow them outside the allowlist.
    for parent in /home/user/.npm /home/user/.cache; do
        if [ -L "$parent" ]; then
            printf 'Refusing cleanup: parent is a symlink: %s\n' "$parent" >&2
            exit 1
        fi
    done
    printf '\nRemoving only the listed caches...\n'
    rm -rf -- "$@"
    printf '\nCleanup complete. Disk space now:\n'
    df -h /home/user
else
    printf '\nLargest home entries (including hidden folders; total is first):\n'
    # Ignore unreadable directories; du still reports the accessible entries.
    du -xh --max-depth=1 /home/user 2>/dev/null | sort -hr | head -n 15
    printf '\nTo delete ONLY the allowlisted caches above, run:\n'
    printf '  %s --clean\n' "$0"
fi
