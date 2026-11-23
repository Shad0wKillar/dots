#!/usr/bin/env bash
set -eu

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
state="${XDG_STATE_HOME:-$HOME/.local/state}/dots"
dry_run=0
case "${1:-}" in
  -n|--dry-run) dry_run=1 ;;
  "") ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

# Preflight every destination before installing the first link.
if (( ! dry_run )); then
  "$repo/sync.sh" --dry-run >/dev/null
fi

run_dir=
prepare_run() {
  if [[ -z "$run_dir" ]]; then
    mkdir -p -- "$state"
    run_dir=$(mktemp -d "$state/sync-XXXXXXXX")
    echo "[BACKUPS] $run_dir/originals"
  fi
}

# Keep backups outside paths that Neovim, Zsh and systemd discover on startup.
backup() {
  prepare_run
  mkdir -p -- "$run_dir/originals/$(dirname "$1")"
  cp -a -- "$HOME/$1" "$run_dir/originals/$1"
}

while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -z "$path" || "$path" == \#* ]] && continue
  target="$HOME/$path"
  source="$repo/$path"
  if [[ -d "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    echo "[ERROR] Expected a regular file at $target" >&2
    exit 1
  fi
  if [[ -L "$target" && "$(readlink -- "$target")" == *".mydotfiles/"* ]]; then
    echo "[SKIP] ML4W manages the link at $path"
    continue
  fi

  if [[ -f "$repo/patches/$path.patch" ]]; then
    # Accept a clean upstream file or a file that already has all our edits.
    # Alternative patches cover incompatible upstream revisions.
    input=$(realpath -m -- "$target")
    applied=0
    matched=0
    for delta in "$repo/patches/$path.patch" "$repo/patches/$path".*.patch; do
      [[ -f "$delta" && -f "$target" ]] || continue
      if patch -s -f -R -F0 --dry-run "$input" -i "$delta" >/dev/null; then
        matched=1
        applied=1
        break
      elif patch -s -f -F0 --dry-run "$input" -i "$delta" >/dev/null; then
        matched=1
        break
      fi
    done
    if (( ! matched )); then
      echo "[ERROR] $path needs a compatible ML4W base or a rebased patch." >&2
      exit 1
    fi
    if (( applied )) && [[ -L "$target" && "$(realpath -- "$target")" == "$state"/sync-*/merged/"$path" ]]; then
      echo "[OK] $path"
      continue
    fi
    echo "[OVERLAY] $path"
    (( dry_run )) && continue
    prepare_run
    source="$run_dir/merged/$path"
    mkdir -p -- "$(dirname "$source")"
    if (( applied )); then
      cp -p -- "$target" "$source"
    else
      patch -s -f -F0 -o "$source" "$input" -i "$delta"
      chmod --reference="$target" "$source"
    fi
  elif [[ -f "$source" && "$target" -ef "$source" ]]; then
    echo "[OK] $path"
    continue
  elif [[ ! -e "$source" && -f "$target" && ! -L "$target" ]]; then
    echo "[INGEST] $path"
    if (( ! dry_run )); then
      mkdir -p -- "$(dirname "$source")"
      cp -p -- "$target" "$source"
    fi
  elif [[ ! -f "$source" ]]; then
    echo "[ERROR] Missing source for $path" >&2
    exit 1
  fi

  echo "[LINK] $path"
  (( dry_run )) && continue
  mkdir -p -- "$(dirname "$target")"
  if [[ -L "$target" || -e "$target" ]]; then
    backup "$path"
  fi
  ln -sfnT -- "$source" "$target"
done < "$repo/manifest.txt"

# ML4W uses the presence of an empty marker to disable Waybar.
marker=.config/ml4w/settings/waybar-disabled
if [[ "$(cat "$repo/.config/ml4w/settings/statusbar")" == waybar && ( -e "$HOME/$marker" || -L "$HOME/$marker" ) ]]; then
  if [[ ! -f "$HOME/$marker" || -s "$HOME/$marker" || -L "$HOME/$marker" ]]; then
    echo "[ERROR] Unexpected Waybar marker at $HOME/$marker" >&2
    exit 1
  fi
  echo "[ARCHIVE] $marker"
  if (( ! dry_run )); then
    prepare_run
    mkdir -p "$run_dir/originals/$(dirname "$marker")"
    mv -T -- "$HOME/$marker" "$run_dir/originals/$marker"
  fi
fi
