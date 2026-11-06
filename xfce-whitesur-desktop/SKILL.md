---
name: xfce-whitesur-desktop
description: >-
  Configure or reproduce a macOS-like Xfce desktop on Ubuntu using WhiteSur,
  Inter, Labwc Wayland, and native Xfce panels. Use when auditing an existing
  Xfce theme or planning a clean Ubuntu 24.04/26.04 desktop that should match a
  Cursor cloud environment's colors, icons, fonts, window controls, top bar, and
  dock. Not for generic macOS theming or unrelated desktop environments.
---

# Xfce WhiteSur Desktop

Build a macOS-like desktop from standard Linux components. The visual identity
comes from WhiteSur, Inter, and a restrained panel layout; the operating system
uses Xfce rather than a patched or proprietary desktop shell.

## Default target

For a fresh Intel/AMD laptop that should use modern Linux while retaining this
look, use:

- Ubuntu 26.04 LTS, x86_64
- `Xfce Session (Wayland)`
- Labwc as the Wayland compositor
- WhiteSur Light GTK, icon, cursor, and Labwc themes
- Inter 11 for UI text
- A 28px top Xfce Panel with application menu and clock
- A fixed, centered bottom Xfce Panel used as the dock

Do not add Plank to this native-Wayland target. Xfce's bottom Panel provides the
standard Wayland behavior and intentionally has no icon magnification. Treat a
request for the original cloud setup's Plank zoom or X11/TigerVNC behavior as a
different fidelity target, not as an implementation detail to improvise.

## Before changing a system

Determine these three choices from the user's request:

1. **Target state:** fresh installation, dual boot, existing Linux desktop, or
   WSL/VM. Preserve an existing OS and working session unless the user
   explicitly asks to replace them.
2. **Display stack:** native Wayland, native X11, or remote desktop. The default
   is native Wayland. Do not assume an X11 desktop, `Xvnc`, or TigerVNC is
   available under Wayland.
3. **Fidelity goal:** approximate visual style or copy a specific existing
   desktop. Approximate style can use current upstream WhiteSur. An exact copy
   requires the source desktop's actual theme files, fonts, wallpaper, logo,
   and configuration rather than only its `dpkg -l` output.

Installing packages, changing sessions, or replacing an OS requires explicit
user authorization. Read-only audits are safe to run first.

## Workflow

1. If a desktop already exists, run the read-only
   [`scripts/audit-desktop.sh`](scripts/audit-desktop.sh) before proposing
   replacements. If the target is remote or not reachable, give the command to
   the user rather than pretending the local machine represents it.
2. If the task is to reproduce this particular Cursor cloud desktop, read
   [`reference/cloud-baseline.md`](reference/cloud-baseline.md) to distinguish
   observed values from inferred defaults.
3. For the native Wayland build, read
   [`reference/setup-wayland.md`](reference/setup-wayland.md) before running
   setup commands.
4. Apply the minimum requested scope. Keep WhiteSur files in XDG user
   directories, do not patch package internals, and do not install the source
   host's unrelated development packages.
5. Log out and select the correct Xfce session, then verify the session type,
   compositor, theme values, and panel layout. A configuration command that
   succeeds does not prove the visual result without the intended session.

## Important invariants

- On Xfce Wayland, `xfwm4` is not the compositor. Ubuntu's Wayland session uses
  Labwc; configure the `WhiteSur-Light` Labwc theme rather than expecting the
  Xfwm theme to control server-side decorations.
- Install WhiteSur to `~/.local/share/themes` when it must be discovered by
  Labwc. The older `~/.themes` location is suitable for the X11 target.
- The WhiteSur GTK theme affects GTK applications. Native Chromium and some
  libadwaita applications retain their own chrome.
- The cloud desktop's wallpaper and Cursor logo were manually installed, not
  supplied by an apt package. Do not claim they are reproducible from package
  names alone.
- Xfce Panel and Plank are different deliverables. Do not promise Plank's zoom
  effect from a Panel, and do not introduce Plank into the native-Wayland
  baseline unless the user asks for compatibility compromise.
