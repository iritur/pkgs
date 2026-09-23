# gnome-git

GNOME built from the development branches at gitlab.gnome.org, packaged with
the official Arch Linux PKGBUILDs pointed at those checkouts. Install it with
pacman on any x86_64 Arch machine. Nothing is compiled on your side.

**119 packages, updated 2026-09-23 13:47 UTC.**

## Before you start

This is unreleased GNOME. It is rebuilt whenever upstream moves, it does not
get the testing Arch gives its own packages, and it can break in ways a stable
desktop does not. A spare machine or a virtual machine is the sensible place
for it. Uninstalling is supported and described at the end.

You need:

- Arch Linux, x86_64.
- An up-to-date system. Run `sudo pacman -Syu` and reboot first. These
  packages are linked against current Arch libraries, so on an old install
  pacman will either drag in half the distribution or refuse the transaction.
- Roughly 2 GB free for the packages and their dependencies.

## Install

```bash
curl -fLO https://raw.githubusercontent.com/iritur/pkgs/arch/install-gnome-git.sh
less install-gnome-git.sh      # it edits pacman.conf and calls sudo; read it
bash install-gnome-git.sh --all
```

The script adds this repository to `/etc/pacman.conf` above `[core]` and
`[extra]`, so its packages win over the Arch ones, keeps a backup of the file,
then syncs and installs. Without `--all` it only upgrades the GNOME packages
you already have.

To do it by hand instead, put this above `[core]` in `/etc/pacman.conf`:

```
[gnome-git]
SigLevel = Optional TrustAll
Server = https://raw.githubusercontent.com/iritur/pkgs/arch/$arch
```

then run `sudo pacman -Syu`.

## Getting to a desktop

```bash
sudo pacman -S --needed networkmanager
sudo systemctl enable --now NetworkManager gdm
```

NetworkManager is only an optional dependency of the control center, so
without it the shell's network menu stays dead. Enabling gdm brings up the
login screen straight away; a reboot is cleaner for the first run.

If the session fails to start, switch to a console with Ctrl+Alt+F2 and read
`journalctl -b -u gdm`. `sudo systemctl disable --now gdm` returns you to a
text login.

## What is in here

The GNOME platform (glib, gtk4, libadwaita, gobject-introspection and the
rest), the shell and session (mutter, gnome-shell, gdm, gnome-session, the
settings daemon, the control center), the core applications, and the
development tools including Builder. Everything else the system needs, the
kernel, mesa, pipewire, systemd, comes from the official Arch repositories as
ordinary dependencies.

Deliberately left out: API documentation and the help manual, the GTK and
libadwaita demo programs, the vte sample terminals, and `gvfs-dnssd`.

## Updating

```bash
sudo pacman -Syu
```

These packages carry a raised epoch, which is what keeps them ahead of the
Arch ones. Repository order alone would not: pacman installs the highest
version it can see, and a build of GNOME's main branch often sorts below the
release Arch ships, because releases are tagged on the stable branch.

## Going back to stock Arch

```bash
bash install-gnome-git.sh --remove
sudo pacman -Syuu
```

The first command unregisters the repository, the second downgrades everything
to the official packages.

## Things worth knowing

- Packages are unsigned. `SigLevel = Optional TrustAll` tells pacman to
  trust whatever this URL serves. The transport is HTTPS, so the trust is in
  the GitHub account that publishes it.
- Version numbers read `51.0.r2.geb74a99`: the last tag, the number of commits
  since it, and the commit id. They sort above the matching Arch release.
- Just after an update here, `raw.githubusercontent.com` can serve a cached
  package database for a few minutes. If pacman reports 404s on package files,
  wait five minutes and run `sudo pacman -Syy`.

## How these are built

The build tooling is at <https://github.com/iritur/gnome-git>. It takes the official Arch PKGBUILDs,
repoints their sources at local git checkouts, derives the version from git,
and builds them with makepkg into a pacman repository.
