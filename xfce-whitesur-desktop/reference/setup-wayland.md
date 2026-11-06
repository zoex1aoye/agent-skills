# Ubuntu 26.04 Xfce Wayland setup

Use this reference for a clean native-Wayland target with standard Xfce panels.
It deliberately does not install Plank or patch theme files.

## 1. Install the base and desktop

Use the Ubuntu 26.04 LTS `amd64` ISO for Intel/AMD laptops. During installation,
choose a minimal desktop if offered. Keep Windows or existing Linux partitions
only when the user has explicitly chosen dual boot and has a backup plan.

Install the desktop packages:

```bash
sudo apt update
sudo apt install -y \
  xfce4 xfce4-terminal xfce4-pulseaudio-plugin \
  labwc xwayland \
  fonts-inter fonts-noto-core fonts-noto-color-emoji \
  fonts-dejavu-core fonts-dejavu-mono fonts-jetbrains-mono \
  fonts-wqy-microhei adwaita-icon-theme gnome-themes-extra \
  ubuntu-mono humanity-icon-theme \
  git curl sassc libglib2.0-dev-bin
```

Log out and choose `Xfce Session (Wayland)`. Ubuntu's Xfce session launches
Labwc as the compositor. Verify after login:

```bash
printf '%s\n' "${XDG_SESSION_TYPE:-unset}"
pgrep -a labwc || true
```

The expected session type is `wayland`.

## 2. Install WhiteSur

Install the GTK and Labwc theme into the XDG user theme directory:

```bash
mkdir -p "$HOME/src"
cd "$HOME/src"

git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh -d "$HOME/.local/share/themes" \
  -c light -t blue -o normal -a normal
```

Install the matching icons and cursors:

```bash
cd "$HOME/src"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh -d "$HOME/.local/share/icons" -t blue

cd "$HOME/src"
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors
./install.sh
```

Load the new font cache only if Inter does not appear after installing the distro
package:

```bash
fc-cache -fv
fc-match Inter
```

## 3. Set GTK, icon, cursor, and font values

Run these inside the Xfce Wayland session:

```bash
xfconf-query -c xsettings -p /Net/ThemeName -s WhiteSur-Light
xfconf-query -c xsettings -p /Net/IconThemeName -s WhiteSur
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s WhiteSur-cursors
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 24
xfconf-query -c xsettings -p /Gtk/FontName -s 'Inter 11'
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s 'Monospace 10'
```

WhiteSur supplies Labwc server-side decoration resources. After the first
Wayland login, Xfce creates `~/.config/xfce4/labwc/rc.xml`. Merge the following
theme values into its existing `<theme>` element; do not overwrite unrelated
Labwc window, keyboard, or workspace settings.

```xml
<theme>
  <name>WhiteSur-Light</name>
  <icon>WhiteSur</icon>
  <titlebar>
    <layout>close,iconify,max:menu</layout>
    <showTitle>yes</showTitle>
  </titlebar>
  <cornerRadius>10</cornerRadius>
  <dropShadows>yes</dropShadows>
  <font place="ActiveWindow">
    <name>Inter</name>
    <size>11</size>
    <weight>bold</weight>
  </font>
  <font place="InactiveWindow">
    <name>Inter</name>
    <size>11</size>
    <weight>bold</weight>
  </font>
</theme>
```

Reload Labwc:

```bash
labwc --reconfigure
```

If the theme is not found, confirm that
`~/.local/share/themes/WhiteSur-Light/labwc/themerc` exists.

## 4. Configure the two native panels

Open panel preferences:

```bash
xfce4-panel --preferences
```

Configure the existing panel as the top bar:

- Horizontal, top edge, full width, 28px high
- Locked, without automatic hiding
- Cursor-logo application menu on the left
- Digital clock on the right
- No task list or dock entries

Create a second panel and configure it as the dock:

- Horizontal, bottom edge, centered, locked
- Fixed length around 40%-50% of the screen width
- About 56px high
- Automatic length growth disabled
- Launcher plugin only: Chrome, Thunar, Xfce Terminal
- No task list, workspace switcher, notification area, or status tray
- Keep the theme background; avoid custom CSS or source patches

This is a native Xfce Wayland panel. It will not magnify icons on hover like
Plank. That limitation is part of the selected design, not a defect to work
around.

## 5. Verify and capture state

```bash
printf 'session=%s desktop=%s\n' \
  "${XDG_SESSION_TYPE:-unset}" "${XDG_CURRENT_DESKTOP:-unset}"
pgrep -a labwc || true
xfconf-query -c xsettings -p /Net/ThemeName
xfconf-query -c xsettings -p /Net/IconThemeName
xfconf-query -c xsettings -p /Gtk/CursorThemeName
xfconf-query -c xsettings -p /Gtk/FontName
xfconf-query -c xfce4-panel -p /panels
```

For acceptance, compare at the target laptop's actual resolution and scaling.
Do not claim the result is pixel-identical to the X11 source when Xfce, GTK,
Labwc, and the dock component versions differ.

## Remote-desktop boundary

The source Cursor desktop used X11 through TigerVNC. A native Wayland session
cannot simply replace that with `Xvnc`. If the user needs remote access, choose
and test a Wayland-capable remote-desktop design separately; do not route the
entire native desktop through TigerVNC as an implicit workaround.
