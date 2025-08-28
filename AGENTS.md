# Repository Guidelines

## Project Structure & Module Organization
- `appimage-install.sh`: Main Bash script to install an AppImage into `~/Applications`, create a `.desktop` entry in `~/.local/share/applications/`, and copy the icon to `~/.local/share/icons/`.
- `README.md`: Usage notes and supported environments (GNOME-based distros).
- `LICENSE`: Project license.

## Build, Test, and Development Commands
- Run locally: `./appimage-install.sh ~/Downloads/My.AppImage`
  - Installs the AppImage and registers launcher + icon.
- Lint (recommended): `shellcheck appimage-install.sh`
  - Static analysis for Bash pitfalls.
- Format (recommended): `shfmt -w appimage-install.sh`
  - Consistent shell formatting.

## Coding Style & Naming Conventions
- Shell: Bash (`#!/usr/bin/env bash`). Start scripts with `set -Eeuo pipefail`.
- Indentation: 2 spaces; no tabs.
- Quoting: Always quote variable expansions and paths (e.g., `"$name"`).
- Naming: Lowercase, hyphen-separated script names; descriptive variable names (e.g., `app_name`, `desk_dir`).
- Utilities: Prefer `mktemp -d` for staging over hardcoded temp paths; avoid `ls | grep` anti-patterns; use `find`/globbing safely.

## Testing Guidelines
- Manual verification on GNOME (e.g., Pop!_OS, Fedora):
  - Run with a known AppImage; ensure executable exists in `~/Applications/`.
  - Check `.desktop` in `~/.local/share/applications/` references the installed path.
  - Confirm icon appears in `~/.local/share/icons/` and the launcher shows in the app menu.
- Negative tests: Pass a missing path and confirm a clear error message and non-zero exit.

## Commit & Pull Request Guidelines
- Commits: Use Conventional Commits where possible (e.g., `feat:`, `fix:`, `docs:`). Keep changes focused.
- PRs: Include a brief description, tested OS/DE, and before/after behavior. Add screenshots of the app menu entry when UI changes apply.
- CI (future): If added, include `shellcheck` and `shfmt` checks.

## Security & Configuration Tips
- No root required; writes to user directories only. Do not run untrusted AppImages.
- Validate inputs and handle spaces in paths. Prefer defensive checks and clear error messages.
