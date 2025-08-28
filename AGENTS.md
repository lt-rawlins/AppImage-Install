Agent Guide
===========

This repository uses a simple Bash script to integrate AppImages into a user’s desktop environment. When contributing as an AI coding agent or automation, follow the practices below to keep the project consistent, safe, and easy to review.

Scope & Goals
- Primary artifact: `appimage-install.sh` (Bash, no root).
- Purpose: Copy AppImage to `~/Applications`, create `.desktop` in `~/.local/share/applications/`, and install icon in `~/.local/share/icons/`.
- Target: GNOME-based distros (freedesktop-compliant launchers).

Coding Standards
- Shell: Bash with `#!/usr/bin/env bash` and `set -Eeuo pipefail`.
- Indentation: 2 spaces; no tabs.
- Quoting: Always quote variables and paths (`"$var"`).
- Utilities: Prefer `mktemp -d` for temp dirs; avoid `ls | grep`; prefer `find`/globbing.
- Names: Descriptive, lowercase with hyphens for scripts; e.g., `app_name`, `desktop_dir`.
- Safety: Validate inputs; handle spaces; offer `--force` for overwrites; clear errors.

Dev Workflow
- Lint: `shellcheck appimage-install.sh`
- Format: `shfmt -w appimage-install.sh`
- Manual testing on GNOME:
  - Install a known AppImage; verify presence in `~/Applications/`.
  - Check `.desktop` references the installed path.
  - Confirm icon in `~/.local/share/icons/` and launcher visible in the app grid.
- Negative tests: Use an invalid/missing path; ensure non-zero exit and readable error.

Change Guidelines
- Keep changes focused and minimal; avoid unrelated refactors.
- Prefer small, composable helpers over complex monolith functions.
- When adding options, update README with usage and examples.

PR & Commit Conventions
- Conventional Commits preferred (e.g., `feat:`, `fix:`, `docs:`).
- Describe tested OS/DE and before/after behavior; include screenshots if UI-visible.

Security
- Never escalate privileges; do not write outside user directories.
- Do not download or execute untrusted binaries during tests.

