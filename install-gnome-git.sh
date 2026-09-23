#!/usr/bin/env bash
# Registers this package repository with pacman and installs GNOME from it.
# Nothing is built: every package was compiled from GNOME git elsewhere.
#
#   ./install-gnome-git.sh            add the repo, upgrade what is installed
#   ./install-gnome-git.sh --all      also install every package in the repo
#   ./install-gnome-git.sh --remove   unregister the repo again
set -euo pipefail

REPO=gnome-git
URL="https://raw.githubusercontent.com/iritur/pkgs/arch"
SIGLEVEL="Optional TrustAll"
# packages never installed here (built, but not wanted on a desktop)
EXCLUDE_RE='^.*-docs$|^.*-doc$|^gtk4-demos$|^libadwaita-demos$|^vte3-utils$|^vte4-utils$|^gvfs-dnssd$'
CONF=/etc/pacman.conf
B="# >>> $REPO >>>"
E="# <<< $REPO <<<"

strip_block() {
    awk -v b="$B" -v e="$E" '
        $0 == b { skip = 1 }
        skip    { if ($0 == e) { skip = 0; eat = 1 }; next }
        eat && $0 == "" { eat = 0; next }
        { eat = 0; print }' "$CONF"
}

if [[ ${1:-} == --remove ]]; then
    strip_block | sudo tee "$CONF.new" >/dev/null && sudo mv "$CONF.new" "$CONF"
    sudo pacman -Sy
    echo "Removed [$REPO]. Run 'sudo pacman -Syuu' to go back to the Arch versions."
    exit 0
fi

echo "==> registering [$REPO] in $CONF (backup: $CONF.$REPO.bak)"
sudo cp "$CONF" "$CONF.$REPO.bak"
block=$(printf '%s\n[%s]\nSigLevel = %s\nServer = %s/$arch\n%s\n' "$B" "$REPO" "$SIGLEVEL" "$URL" "$E")
# placed above core/extra so these packages win over the Arch ones
strip_block | awk -v top="$block" '
    /^\[/ && $0 != "[options]" && !done { print top; print ""; done = 1 }
    { print }' | sudo tee "$CONF.new" >/dev/null
sudo mv "$CONF.new" "$CONF"
sudo pacman -Sy

if [[ ${1:-} == --all ]]; then
    echo "==> installing from [$REPO], leaving out docs, demos and samples"
    sudo pacman -Syu
    # same exclusions as the build machine's exclude.list
    mapfile -t want < <(pacman -Slq "$REPO" | grep -vE "$EXCLUDE_RE")
    echo "    ${#want[@]} packages"
    sudo pacman -S --needed "${want[@]}"
else
    echo "==> upgrading the packages you already have"
    sudo pacman -Syu
fi

cat <<MSG

Done. To run the desktop:
  sudo pacman -S --needed networkmanager
  sudo systemctl enable --now NetworkManager gdm
MSG
