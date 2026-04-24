# Shad0wKillar's Arch System Dotfiles

This repository contains the custom configuration files for my Arch Linux system. It is specifically designed to sit on top of the **ML4W (MyLinuxForWork)** base system without interfering with its default symlink management. 

The tracking and deployment of these files are handled by a custom **Manifest-Driven Symlink System** rather than standard tools like GNU Stow, ensuring safe, conflict-free integration.

---

## Hardware & Software Stack

These configurations were built and tested on a Dell Latitude 5490 (LightBox) with an i5 8th gen processor and an Nvidia MX130. 

### Prerequisites
To accurately replicate this environment, the following core software must be installed on your Arch system:
* **Arch Linux**
* **Hyprland**
* **ML4W Dotfiles**
* **Kitty**
* **Zsh**
* **Oh-My-Posh**
* **Neovim** (configured with AstroNvim)

---

## The Manifest System

Because ML4W heavily utilizes symlinks pointing to its own deployment directories (`~/.mydotfiles`), using a blanket directory-mirroring tool like GNU Stow is dangerous and will cause immediate file collisions. To solve this, this repository uses a surgical, file-by-file tracking system.

### How It Works
The core of the system is the `sync.sh` bash script and the `manifest.txt` file.

1. **`manifest.txt`**: A flat text list of all custom files tracked by this repository. All paths are written relative to the home directory (`~`).
2. **`sync.sh`**: The engine that parses the manifest, dynamically determines its own location (allowing the repo to be cloned anywhere), and synchronizes the local system with the repository.

### Edge Cases and Safety Mechanisms
The script is built with strict safeguards to prevent data loss or system breakage:

* **ML4W Collision Avoidance:** Before touching any file, the script checks if it is a symlink pointing to `.mydotfiles`. If it is, the file is strictly ignored. This guarantees custom configurations never override ML4W's base files.
* **Automated Ingestion:** If a file exists as a standard file on the system but not in the repository (e.g., a newly created AstroNvim plugin), the script automatically creates the necessary directory structure in the repo, moves the file into it, and replaces the local file with a symlink.
* **Conflict Resolution:** If a file exists in both the system and the repository independently, the script prioritizes the repository version but safely backs up the local system file by appending `.bak` to it.
* **Dead Link Pruning:** If the repository is moved to a new directory, running the script detects broken old links, removes them, and establishes fresh symlinks pointing to the new repository location.

> **NOTE:** If you have files in AstroNvim, adding the `.bak` file can break it. For that, you have to manually go to `~/.config/nvim/` and delete all the `*.bak` files. Same is the case for `~/.zshrc/custom`. So whenever you get the errors, you have to remove the `*.bak` file to make it work.

---

## Usage

### Installation
1. Clone this repository anywhere on your system.
2. Make the script executable: 
   ```bash
   chmod +x sync.sh
   ```
3. Run the script: 
   ```bash
   ./sync.sh
   ```

### Dry Run Mode
To see exactly what operations the script will perform without actually modifying, moving, or deleting any files, run the script with the dry-run flag:
```bash
./sync.sh --dry-run 
# or 
./sync.sh -n
```

---

## Monitored Files

Below is the current structure of tracked custom files defined in `manifest.txt` (you can check the latest list in the `manifest.txt` file at the root of the repo):

```bash
# You should put the path of the files here
# Remember, all the paths automatically starts
# from "~". 
# So for ~/.zshrc , you only have to write .zshrc

# --- Zsh ---
.zshrc_custom
.config/zshrc/custom/20-customization
.config/zshrc/custom/25-aliases
.config/zshrc/custom/30-autostart

# --- Kitty ---
.config/kitty/custom.conf

# --- Hyprland Environment ---
.config/hypr/conf/custom.conf
.config/hypr/conf/keybindings/default.conf

# --- Neovim (AstroNvim Additions) ---
.config/nvim/lua/plugins/astroui.lua
.config/nvim/lua/plugins/custom.lua

# --- Oh My Posh ---
.config/ohmyposh/quick-term.omp.json
```
