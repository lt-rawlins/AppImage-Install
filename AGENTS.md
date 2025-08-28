Agent Guide
===========

This repository uses a simple Bash script to integrate AppImages into a user’s desktop environment. When contributing as an AI coding agent or automation, follow the practices below to keep the project consistent, safe, and easy to review.

Scope & Goals
- Primary artifact: `appimage-install.sh` (Bash, no root).
- Purpose: Copy AppImage to `~/Applications`, create `.desktop` in `~/.local/share/applications/`, and install icon in `~/.local/share/icons/`.
- Target: GNOME-based distros (freedesktop-compliant launchers).

Ubuntu/Sandbox Wrapper
- Wrapper: Script writes a small launcher to `~/.local/bin/<slug>-appimage-launcher` and points the `.desktop` `Exec` to it.
- Behavior: Wrapper launches the installed AppImage normally first; on failure, it retries with `--no-sandbox` (helps on Ubuntu 24.04+ where Chromium/Electron apps may fail from menu launchers).
- FUSE fallback: If `libfuse2` is not present (checked via `ldconfig -p`), sets `APPIMAGE_EXTRACT_AND_RUN=1` in the wrapper to improve reliability.
- `--exec-args`: Any extra args passed via `--exec-args` are included in both the normal and fallback launch paths.
- Security note: `--no-sandbox` reduces process isolation. Keep the warning in docs and avoid enabling it unconditionally.

Coding Standards
- Shell: Bash with `#!/usr/bin/env bash` and `set -Eeuo pipefail`.
- Indentation: 2 spaces; no tabs.
- Quoting: Always quote variables and paths (`"$var"`).
- Utilities: Prefer `mktemp -d` for temp dirs; avoid `ls | grep`; prefer `find`/globbing.
- Names: Descriptive, lowercase with hyphens for scripts; e.g., `app_name`, `desktop_dir`.
- Safety: Validate inputs; handle spaces; offer `--force` for overwrites; clear errors.
 - Wrapper parity: Keep wrapper style and safety identical to the main script (shebang, strict mode, quoting).

Dev Workflow
- Lint: `shellcheck appimage-install.sh`
- Format: `shfmt -w appimage-install.sh`
- Manual testing on GNOME:
  - Install a known AppImage; verify presence in `~/Applications/`.
  - Check `.desktop` references the installed path.
  - Confirm icon in `~/.local/share/icons/` and launcher visible in the app grid.
- Negative tests: Use an invalid/missing path; ensure non-zero exit and readable error.
 - Ubuntu wrapper checks:
   - Verify wrapper exists at `~/.local/bin/<slug>-appimage-launcher` and is referenced by the `.desktop` `Exec`.
   - On Ubuntu 24.04+, confirm normal launch works; if it fails for Chromium/Electron apps, confirm the wrapper retries with `--no-sandbox` and the app launches.
   - With `--exec-args`, ensure the args are passed to both normal and fallback paths.
   - If AppImages fail due to missing FUSE, verify wrapper respects `APPIMAGE_EXTRACT_AND_RUN=1` behavior.

Change Guidelines
- Keep changes focused and minimal; avoid unrelated refactors.
- Prefer small, composable helpers over complex monolith functions.
- When adding options, update README with usage and examples.
- If modifying wrapper logic, update README’s Ubuntu/sandboxing section and this guide.

README Sync (User-Facing Changes)
- Always update `README.md` for any change that affects how users interact with the script.
- Examples: adding/removing/renaming options, changing defaults, altering `usage()` text, modifying outputs, or launch behavior.
- Keep `usage()` help text and README “Options”/“Examples” in lockstep.
- If deprecating/removing an option, mark it clearly in README with migration guidance; call out breaking changes.
- Update relevant sections beyond Options as needed: Quick Start, Examples, How It Works, Ubuntu/Sandbox notes, Troubleshooting.

PR & Commit Conventions
- Conventional Commits preferred (e.g., `feat:`, `fix:`, `docs:`).
- Describe tested OS/DE and before/after behavior; include screenshots if UI-visible.
 - Call out Ubuntu 24.04+ behavior when relevant (normal vs. `--no-sandbox` fallback; FUSE fallback).

Security
- Never escalate privileges; do not write outside user directories.
- Do not download or execute untrusted binaries during tests.
 - Do not force `--no-sandbox` unless explicitly requested or as a runtime fallback; keep the warning prominent.
