# Shad0wKillar's Arch System Dotfiles

This repository contains the custom configuration files for my Arch Linux system. It is specifically designed to sit on top of the **ML4W (MyLinuxForWork)** base system without interfering with its default symlink management. 

The tracking and deployment of these files are handled by a custom **Manifest-Driven Symlink System** rather than standard tools like GNU Stow, ensuring safe, conflict-free integration.

---

## Screenshots
<img src="assets/ss_1.jpg" alt="Screenshot 1" width="100%">
<img src="assets/ss_2.jpg" alt="Screenshot 2" width="100%">
<img src="assets/ss_3.jpg" alt="Screenshot 3" width="100%">
<img src="assets/ss_4.jpg" alt="Screenshot 4" width="100%">

## Hardware & Software Stack

These configurations were built and tested on a Dell Latitude 5490 (LightBox) with an i5 8th gen processor and an Nvidia MX130. 

### Restore the configuration

Install ML4W's Lua-based Hyprland configuration and the AstroNvim v6 template first. Clone this repository, then run the following from the checkout.

```sh
./sync.sh --install-deps
./sync.sh --dry-run
./sync.sh
```

The [manifest](manifest.txt) lists the active paths relative to your home directory. Older Hyprland, Zsh and Yazi files outside the manifest are retained for review. Sync leaves them alone.

Most entries link directly to this checkout. For six files that mix ML4W code with personal edits, the [patches](patches) directory holds just the differences. Sync checks the installed file, applies a matching patch to a private copy and links that copy into place. On an incompatible base it reports the path during preflight. After an ML4W update, rerun the dry run and sync to restore any replaced links.

Edit personal files through their links as usual. For a patched file, keep permanent edits in its patch. The linked merged copy lives under `$XDG_STATE_HOME/dots` (normally `~/.local/state/dots`). Keep this directory and the checkout while using the links. Each sync that replaces a file prints the backup directory containing the originals under their home-relative paths. Selecting Waybar also archives ML4W’s empty `waybar-disabled` marker if present.

### Machine-specific dependencies

- The display profile recognizes the Dell P2419H by its description. The laptop display uses 1.2 scaling.
- The Hyprland bindings reference T3 Code and the local Kotodama checkout, including its Python virtual environment. The wallpaper folder setting points to `~/Pictures/wallpaper/ml4w_wallpapers`.
- The Zsh prompt uses Oh My Posh and the ML4W Zsh override in `~/.config/zshrc/custom/20-customization`. The Neovim language packs are selected in `~/.config/nvim/lua/community.lua`.
- The Arch dependency step installs Fontconfig, Noto text, CJK and emoji fonts, plus PAM, KWallet and its PAM integration. Pacman pulls in the helper dependencies. The font selection rules then take effect through the user Fontconfig link.
- The wallpaper helper starts the supervised awww daemon on demand. Its post-start action schedules wallpaper restoration for connected displays. The temporary keep-awake service runs when explicitly started.

### KWallet on a fresh login

Sync places the two wallet unit files in the user unit directory. They are available for manual use. On this laptop Hyprland already runs `/usr/lib/pam_kwallet_init` at startup. Leave the two units unenabled for that setup.

For a password login through a TTY, this laptop uses the PAM service `login`. Its `/etc/pam.d/login` contains these entries, each after the matching `system-local-login` include. Use the existing PAM stack for the actual login service on the new machine. A graphical login manager may already supply its own KWallet integration.

```text
auth       optional     pam_kwallet5.so force_run
session    optional     pam_kwallet5.so auto_start force_run
```

The login password must match the wallet password for automatic unlock. The package step installs the module and helper. System PAM configuration and the wallet itself are separate from this repository. [KDE’s PAM integration](https://github.com/KDE/kwallet-pam)
