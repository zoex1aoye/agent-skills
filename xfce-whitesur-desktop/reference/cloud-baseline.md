# Cursor cloud desktop baseline

This is the observed state of the source Cursor cloud desktop. Treat it as
evidence for visual matching, not as a package list to reproduce wholesale.

## Observed system and session

| Item | Observed value |
|---|---|
| Distribution | Ubuntu 24.04.5 LTS |
| Architecture | `x86_64` |
| Display | X11 `:1`, TigerVNC |
| Resolution | 1920x1200 at 96 DPI |
| Desktop | Xfce 4.18 |
| Window manager | Xfwm4 |
| Dock | Plank 0.11.89 |
| UI theme | `WhiteSur-Light` |
| Window theme | `WhiteSur-Light` |
| Icons | `WhiteSur` |
| Cursor | `WhiteSur-cursors`, 24px |
| UI font | `Inter 11` |
| Window title font | `Inter Bold 11` |
| Window controls | Close, minimize, maximize on the left; menu on the right |
| Workspaces | 4 |

The installed packages did not include a WhiteSur package. The theme, icons,
cursor set, Inter font, wallpaper, and Cursor menu logo were installed outside
the package manager. A `dpkg -l` snapshot therefore cannot identify the final
appearance by itself.

## Panel and dock

The top Xfce Panel was full-width, 28px high, opaque, locked, and contained:

- Cursor logo application menu on the left
- Expanding spacer
- Digital clock on the right

The Plank dock was bottom-centered, always visible, with 48px icons and 150%
hover zoom. Its launchers were Google Chrome, Thunar, and Xfce Terminal. Its
theme was `WhiteSur-Light`.

## Wallpaper

Workspace 0 used:

```text
/usr/share/backgrounds/desktop-background-3.png
```

The other workspaces referenced `/usr/share/backgrounds/xfce/xfce-shapes.svg`.
Desktop icons were disabled.

## Matching guidance

- To match only the look on Ubuntu 26.04 Wayland, use the values above as style
  inputs but replace Plank with a native bottom Xfce Panel.
- To copy the exact visual state, first collect the actual source assets and
  the `xfce4`, `xfce4-panel`, `xfce4-desktop`, `xfwm4`, and `plank` settings.
  Confirm that copying the wallpaper and logo is authorized.
- A screenshot is not required to identify the selected theme and layout, but
  it is required before claiming pixel-level visual parity.
- The source runs X11 under TigerVNC. Do not describe that session setup as
  Wayland-compatible.
