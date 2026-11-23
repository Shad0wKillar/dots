#!/usr/bin/env bash
# Restore the current wallpaper on any display that is not showing it, e.g. an
# LCD that was still initializing when ML4W set the wallpaper at login.
# Displays that already show it are left alone so their transition keeps going.
# Called from custom.lua after login, monitor changes and config reloads.
# Lives outside the ML4W scripts so dotfiles updates keep it.

CACHE_FOLDER="$HOME/.cache/ml4w/hyprland-dotfiles"
ML4W_WALLPAPER="$HOME/.config/ml4w/scripts/ml4w-wallpaper"
LOG_FILE="${XDG_RUNTIME_DIR:?}/restore-wallpaper.log"

log() { echo "$(date --iso-8601=seconds) $1" >>"$LOG_FILE"; }

# One restore at a time; a restore queued behind it re-checks every display.
# Children get fd 7 closed so a daemon they start cannot hold the lock.
exec 7>"$XDG_RUNTIME_DIR/restore-wallpaper.lock"
flock -w 120 7 || exit 1

# Let ML4W's own wallpaper runs (login, picker, automation) finish first, so
# this only fills in the displays they missed.
deadline=$((SECONDS + 60))
while pgrep -f 'ml4w-(autostart|wallpaper)( |$)' >/dev/null && (( SECONDS < deadline )); do
    sleep 0.5
done

image=$(cat "$CACHE_FOLDER/current_wallpaper" 2>/dev/null)
[ -f "$image" ] || { log "No cached wallpaper to restore"; exit 0; }

# With a wallpaper effect enabled, ML4W displays a processed copy instead.
effect=$(cat "$HOME/.config/ml4w/settings/wallpaper-effect" 2>/dev/null)
expected="$image"
[ -n "$effect" ] && [ "$effect" != off ] && expected="$CACHE_FOLDER/$effect-$(basename "$image")"

# A daemon that died while ML4W was restoring the wallpaper must be restarted.
# systemd also schedules this restore script after each automatic restart.
bash "$HOME/.config/ml4w/scripts/ml4w-start-wallpaper-daemon" 7>&- || {
    log "Could not start the wallpaper service; see journalctl --user -u ml4w-awww"
    exit 1
}

# awww can answer before it has registered a newly connected display.
# Wait for every active Hyprland display, not just the daemon's socket.
deadline=$((SECONDS + 30))
until outputs=$(timeout 2s awww query -j 2>/dev/null) &&
      monitors=$(timeout 2s hyprctl -j monitors 2>/dev/null) &&
      jq -en --argjson outputs "$outputs" --argjson monitors "$monitors" '
          [$outputs[][] | select(.width > 0 and .height > 0) | .name] as $ready
          | [$monitors[] | select(.disabled != true) | .name] as $expected
          | ($expected | length) > 0 and (($expected - $ready) | length) == 0
      ' >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
        log "awww is not ready for every display; restoring all of them"
        "$ML4W_WALLPAPER" "$image" --skip-theming 7>&- || {
            log "Failed to restore wallpaper on all displays"
            exit 1
        }
        exit 0
    fi
    sleep 0.2
done

missing=$(jq -r --arg image "$expected" '
    .[][] | select(.width > 0 and .height > 0)
          | select(.displaying.image? != $image) | .name
' <<<"$outputs")
if [ -z "$missing" ]; then
    log "Every display already shows $(basename "$expected")"
    exit 0
fi
for output in $missing; do
    log "Restoring $(basename "$image") on $output"
    "$ML4W_WALLPAPER" "$image" --skip-theming --monitor "$output" 7>&- || {
        log "Failed to restore wallpaper on $output"
        exit 1
    }
done
