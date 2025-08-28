AppImage Install
================

Install and integrate an AppImage into your user environment — no root required. The script copies the AppImage to `~/Applications`, creates a desktop launcher in `~/.local/share/applications/`, and installs an icon in `~/.local/share/icons/` so the app shows up in your app menu on GNOME-based desktops.

Features
- No root: Writes only to your user directories.
- App menu integration: Generates a `.desktop` launcher.
- Icon support: Uses a provided icon, or extracts one from the AppImage when possible.
- Safe defaults: Validates inputs, handles spaces, and avoids destructive changes unless `--force` is used.

Requirements
- Linux desktop with freedesktop-compatible menu (GNOME-based recommended).
- AppImage file to install.
- Optional: `file` command for better icon type detection (usually preinstalled).

Quick Start
- Make the script executable: `chmod +x appimage-install.sh`
- Install an AppImage: `./appimage-install.sh ~/Downloads/My.AppImage`
  - AppImage is copied to `~/Applications/My.AppImage` (renamed to the app name if provided).
  - A desktop entry is written to `~/.local/share/applications/<app>.desktop`.
  - An icon is copied to `~/.local/share/icons/<app>.png` or `.svg` when available.

Options
- `--name NAME`: Display name and base filename (default: from AppImage filename)
- `--categories CATS`: Desktop menu categories (default: `Utility;`)
- `--comment TEXT`: One-line description for the launcher
- `--icon PATH`: Custom icon file (`.png` or `.svg`)
- `--exec-args ARGS`: Extra args appended to `Exec=` (e.g., `--no-sandbox`)
- `--force`: Overwrite existing AppImage, desktop entry, and icon
- `-h, --help`: Show usage

Examples
- Basic install:
  - `./appimage-install.sh ~/Downloads/Obsidian-1.5.3.AppImage`
- Custom name and icon:
  - `./appimage-install.sh --name "Obsidian" --icon ~/Pictures/obsidian.svg ~/Downloads/Obsidian.AppImage`
- Chromium-based app requiring `--no-sandbox`:
  - `./appimage-install.sh --name "Brave" --exec-args "--no-sandbox" ~/Downloads/Brave.AppImage`
- Overwrite existing install:
  - `./appimage-install.sh --force ~/Downloads/Foo.AppImage`

How It Works
- Copies the AppImage to `~/Applications/` and ensures it is executable.
- Tries to extract an icon by running the AppImage with `--appimage-extract` and searching common icon paths; if none is found, uses the AppImage path as a fallback icon.
- Writes a `.desktop` file referencing the installed AppImage, ensuring quoted paths and `%U` to support file/url arguments from the launcher.

Uninstall
- Remove the installed files:
  - `rm ~/Applications/<Name>.AppImage`
  - `rm ~/.local/share/applications/<slug>.desktop`
  - `rm ~/.local/share/icons/<slug>.png` (or `.svg`) if present
  - Optionally run `update-desktop-database ~/.local/share/applications` if available.

Troubleshooting
- App does not appear in menu:
  - Ensure the `.desktop` exists in `~/.local/share/applications/`.
  - Try reloading the desktop index (`gnome-shell --replace` from a TTY) or log out/in.
  - Verify `Categories` include a recognized category (e.g., `Utility;` or `Office;`).
- Icon missing:
  - Provide a custom icon via `--icon path/to/icon.svg|png`.
  - Some AppImages do not contain icons in standard locations.
- Exec errors on launch:
  - Some sandboxed apps require additional flags; use `--exec-args "--no-sandbox"` as needed.
  - Confirm the AppImage has execute permissions.

Testing
- Positive path:
  - Run: `./appimage-install.sh ~/Downloads/My.AppImage`
  - Confirm executable at `~/Applications/`.
  - Confirm `.desktop` references the installed path.
  - Confirm icon in `~/.local/share/icons/` and launcher appears in app menu.
- Negative path:
  - Run with a missing path and verify a clear error and non-zero exit.

Development
- Lint (recommended): `shellcheck appimage-install.sh`
- Format (recommended): `shfmt -w appimage-install.sh`

Security Notes
- Do not run untrusted AppImages.
- This script writes only to user directories; no root required.
- All paths and variable expansions are quoted; the script uses `set -Eeuo pipefail` and defensive checks.

Supported Environments
- GNOME-based distros (Pop!_OS, Fedora Workstation, Ubuntu GNOME). Other freedesktop-compliant desktops may work, but are untested.

License
- See `LICENSE`.

