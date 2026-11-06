#!/usr/bin/env bash
set -u

section() {
  printf '\n=== %s ===\n' "$1"
}

show_optional() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>&1 || true
  else
    printf 'not available: %s\n' "$1"
  fi
}

section "System"
show_optional uname -a
if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  printf 'PRETTY_NAME=%s\n' "${PRETTY_NAME:-unknown}"
  printf 'VERSION_ID=%s\n' "${VERSION_ID:-unknown}"
fi
printf 'user=%s\n' "$(id -un)"

section "Session"
printf 'DISPLAY=%s\n' "${DISPLAY:-unset}"
printf 'WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-unset}"
printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-unset}"
printf 'XDG_CURRENT_DESKTOP=%s\n' "${XDG_CURRENT_DESKTOP:-unset}"
printf 'XDG_SESSION_DESKTOP=%s\n' "${XDG_SESSION_DESKTOP:-unset}"
if [ -n "${XDG_SESSION_ID:-}" ] && command -v loginctl >/dev/null 2>&1; then
  loginctl show-session "$XDG_SESSION_ID" -p Type -p Desktop -p Active 2>&1 || true
fi

section "Desktop processes"
ps -eo user,pid,args 2>/dev/null |
  grep -E '[X]vnc|[x]fce4-session|[x]fwm4|[l]abwc|[x]fdesktop|[p]lank' ||
  true

section "Display geometry"
if [ -n "${DISPLAY:-}" ]; then
  show_optional xdpyinfo
  show_optional xrandr --current
fi

section "Xfce values"
for channel in xsettings xfwm4 xfce4-panel xfce4-desktop; do
  printf '\n--- %s ---\n' "$channel"
  show_optional xfconf-query -c "$channel" -l -v
done

printf '\n--- Plank (if present) ---\n'
for file in "$HOME"/.config/plank/dock*/settings; do
  [ -f "$file" ] || continue
  printf '\n[%s]\n' "$file"
  sed -n '1,240p' "$file"
done

section "Theme directories"
find \
  "$HOME/.local/share/themes" \
  "$HOME/.themes" \
  "$HOME/.local/share/icons" \
  "$HOME/.icons" \
  /usr/share/themes \
  /usr/share/icons \
  -mindepth 1 -maxdepth 1 -type d 2>/dev/null |
  sort

section "Relevant package versions"
if command -v dpkg-query >/dev/null 2>&1; then
  dpkg-query -W \
    xfce4 xfce4-session xfwm4 xfce4-panel xfdesktop4 thunar \
    xfce4-terminal plank tigervnc-standalone-server \
    fonts-inter 2>/dev/null || true
fi

section "Output"
printf 'Audit complete. Paste the output when asking for a desktop comparison.\n'
