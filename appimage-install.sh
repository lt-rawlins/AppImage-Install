#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# appimage-install.sh
# Installs an AppImage into ~/Applications, writes a .desktop launcher into
# ~/.local/share/applications, and copies an icon to ~/.local/share/icons.

usage() {
  cat <<'USAGE'
Usage: appimage-install.sh [OPTIONS] /path/to/AppImage

Installs an AppImage into ~/Applications and integrates it with a desktop entry and icon.

Options:
  --name NAME          Display name for the app (defaults to file basename)
  --categories CATS    Desktop Categories (default: Utility;)
  --comment TEXT       One-line description for the launcher
  --icon PATH          Path to a custom icon file (.png/.svg)
  --exec-args ARGS     Extra args appended to Exec= (e.g., --no-sandbox)
  --force              Overwrite existing AppImage, desktop, and icon
  -h, --help           Show this help and exit

Notes:
  - No root required. Writes only to user directories.
  - GNOME-based desktops are the primary target, but .desktop is freedesktop-compliant.
  - Sets the desktop entry working directory (Path=) to ~/Applications for more reliable launches.
  - Launchers now auto-fallback to --no-sandbox if the first launch fails (helps on Ubuntu 24.04).
USAGE
}

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
err()  { printf '[ERROR] %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

abs_path() {
  # Best-effort absolute path resolution
  # Prefers realpath, falls back to readlink -f, else prefixes with $PWD
  if command_exists realpath; then
    realpath "$1"
  elif command_exists readlink; then
    readlink -f "$1" 2>/dev/null || printf '%s/%s' "$PWD" "${1#./}"
  else
    printf '%s/%s' "$PWD" "${1#./}"
  fi
}

slugify() {
  # Lowercase, replace spaces/underscores with dashes, strip invalids
  # shellcheck disable=SC2020
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr ' ' '-' \
    | tr '_' '-' \
    | sed -E 's/[^a-z0-9.-]+/-/g; s/^-+//; s/-+$//'
}

copy_file() {
  # cp with parents
  # $1 src, $2 dest
  mkdir -p "$(dirname "$2")"
  cp -f "$1" "$2"
}

try_extract_icon_from_appimage() {
  # $1 appimage_path, $2 dest_basename_without_ext, $3 icons_dir
  # Attempts to extract an icon from the AppImage payload.
  # Returns 0 on success and sets ICON_TARGET global; else 1.
  local appimage="$1" base="$2" icons_dir="$3"
  local tmp
  tmp=$(mktemp -d)
  local cleanup
  cleanup() { [ -n "${tmp-}" ] && rm -rf "$tmp" || true; }
  trap cleanup RETURN

  # AppImage self-extractor writes into squashfs-root
  (
    cd "$tmp"
    if ! "$appimage" --appimage-extract >/dev/null 2>&1; then
      return 1
    fi
  )

  local root="$tmp/squashfs-root"
  [ -d "$root" ] || return 1

  # Priority: .DirIcon, then SVGs, then PNGs commonly placed in icons dirs.
  local candidate=""
  if [ -f "$root/.DirIcon" ]; then
    candidate="$root/.DirIcon"
  else
    # Prefer SVG, then PNG anywhere typical under usr/share/icons or top-level app icons
    # Gather a few common locations first to avoid scanning everything
    local -a search_dirs
    search_dirs=(
      "$root/usr/share/icons"
      "$root/usr/share/pixmaps"
      "$root"
    )
    for d in "${search_dirs[@]}"; do
      [ -d "$d" ] || continue
      # SVG first
      candidate=$(find "$d" -type f -name '*.svg' -print 2>/dev/null | head -n 1 || true)
      if [ -n "$candidate" ]; then break; fi
      # PNG next
      candidate=$(find "$d" -type f -name '*.png' -print 2>/dev/null | head -n 1 || true)
      if [ -n "$candidate" ]; then break; fi
    done
  fi

  if [ -z "$candidate" ]; then
    return 1
  fi

  local ext=""
  case "$candidate" in
    *.svg) ext=".svg" ;;
    *.png) ext=".png" ;;
    *)
      # Try to detect from mime
      if command_exists file; then
        local mime
        mime=$(file --mime-type -b "$candidate" || true)
        case "$mime" in
          image/svg+xml) ext=".svg" ;;
          image/png) ext=".png" ;;
          *) ext="" ;;
        esac
      fi
      ;;
  esac

  # Default to .png if unknown
  [ -n "$ext" ] || ext=".png"

  local target="$icons_dir/${base}${ext}"
  mkdir -p "$icons_dir"
  cp -f "$candidate" "$target"
  ICON_TARGET="$target"
  return 0
}

main() {
  local appimage_path=""
  local name=""
  local categories="Utility;"
  local comment=""
  local custom_icon=""
  local exec_args=""
  local force_overwrite=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --name)
        shift; name="${1:-}"; [ -n "$name" ] || die "--name requires a value"; shift || true ;;
      --categories)
        shift; categories="${1:-}"; [ -n "$categories" ] || die "--categories requires a value"; shift || true ;;
      --comment)
        shift; comment="${1:-}"; [ -n "$comment" ] || die "--comment requires a value"; shift || true ;;
      --icon)
        shift; custom_icon="${1:-}"; [ -n "$custom_icon" ] || die "--icon requires a value"; shift || true ;;
      --exec-args)
        shift; exec_args="${1:-}"; [ -n "$exec_args" ] || die "--exec-args requires a value"; shift || true ;;
      --force)
        force_overwrite=true; shift ;;
      -h|--help)
        usage; exit 0 ;;
      --)
        shift; break ;;
      -*)
        die "Unknown option: $1" ;;
      *)
        # First non-flag is the AppImage
        if [ -z "$appimage_path" ]; then
          appimage_path="$1"; shift
        else
          die "Unexpected positional argument: $1"
        fi
        ;;
    esac
  done

  [ -n "$appimage_path" ] || { usage; die "Missing AppImage path"; }
  [ -f "$appimage_path" ] || die "File not found: $appimage_path"

  # Make sure it's executable; some downloads are not +x
  if [ ! -x "$appimage_path" ]; then
    warn "AppImage is not executable; adding +x: $appimage_path"
    chmod +x "$appimage_path"
  fi

  local abs_appimage
  abs_appimage=$(abs_path "$appimage_path")

  local base_from_file
  base_from_file=$(basename "$abs_appimage")
  base_from_file=${base_from_file%.*}

  local app_name
  if [ -n "$name" ]; then
    app_name="$name"
  else
    app_name="$base_from_file"
  fi

  local app_slug
  app_slug=$(slugify "$app_name")
  [ -n "$app_slug" ] || die "Could not derive a valid slug from name: $app_name"

  local install_dir="$HOME/Applications"
  local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
  local desktop_dir="$data_dir/applications"
  local icons_dir="$data_dir/icons"

  mkdir -p "$install_dir" "$desktop_dir" "$icons_dir"

  local dest_appimage="$install_dir/${app_name}.AppImage"
  if [ -e "$dest_appimage" ] && [ "$force_overwrite" = false ]; then
    die "Destination already exists: $dest_appimage (use --force to overwrite)"
  fi

  log "Copying AppImage to: $dest_appimage"
  copy_file "$abs_appimage" "$dest_appimage"
  chmod +x "$dest_appimage"

  # Icon handling
  local icon_target=""
  if [ -n "$custom_icon" ]; then
    [ -f "$custom_icon" ] || die "Custom icon not found: $custom_icon"
    local ext
    case "$custom_icon" in
      *.png) ext=".png" ;;
      *.svg) ext=".svg" ;;
      *) die "Unsupported icon type (use .png or .svg): $custom_icon" ;;
    esac
    icon_target="$icons_dir/${app_slug}${ext}"
    log "Copying provided icon to: $icon_target"
    copy_file "$custom_icon" "$icon_target"
  else
    if try_extract_icon_from_appimage "$abs_appimage" "$app_slug" "$icons_dir"; then
      icon_target="$ICON_TARGET"
      log "Extracted icon to: $icon_target"
    else
      warn "Could not extract icon; launcher will reference the AppImage path as icon"
      icon_target="$dest_appimage"
    fi
  fi

  # Create a tiny wrapper so desktop launchers can retry with --no-sandbox if needed
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"
  local wrapper_path="$bin_dir/${app_slug}-appimage-launcher"
  log "Writing launcher wrapper: $wrapper_path"
  cat >"$wrapper_path" <<'WRAP'
#!/usr/bin/env bash
set -Eeuo pipefail
app="$APPIMAGE_PATH_PLACEHOLDER"
extra_args="$EXEC_ARGS_PLACEHOLDER"

# If libfuse2 is missing, prefer extract-and-run to avoid mount issues
if command -v ldconfig >/dev/null 2>&1; then
  if ! ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
    export APPIMAGE_EXTRACT_AND_RUN=1
  fi
fi

# Try normal launch first
if "$app" $extra_args "$@"; then
  exit 0
fi

# Fallback commonly needed for Electron-based AppImages on some Ubuntu configs
exec "$app" --no-sandbox $extra_args "$@"
WRAP
  sed -i "s|$APPIMAGE_PATH_PLACEHOLDER|$dest_appimage|g" "$wrapper_path"
  sed -i "s|$EXEC_ARGS_PLACEHOLDER|$exec_args|g" "$wrapper_path"
  chmod +x "$wrapper_path"

  # Use wrapper to handle fallbacks and pass through desktop arguments
  local exec_line
  exec_line="\"$wrapper_path\" %U"

  # Icon can be a name (no ext) if placed into icons theme; if a file path, keep absolute
  local icon_field
  case "$icon_target" in
    "$icons_dir/${app_slug}.png"|"$icons_dir/${app_slug}.svg")
      icon_field="$app_slug" ;;
    *)
      icon_field="$icon_target" ;;
  esac

  log "Writing desktop entry: $desktop_file"
  cat >"$desktop_file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$app_name
Exec=$exec_line
Path=$install_dir
Icon=$icon_field
Terminal=false
Categories=$categories
TryExec=$dest_appimage
Comment=${comment}
StartupNotify=true
DESKTOP

  chmod +x "$desktop_file"

  log "Installed AppImage: $dest_appimage"
  log "Desktop entry created: $desktop_file"
  log "Icon installed: $icon_target"
  printf "\nDone. You may need to refresh your desktop's app index or log out/in.\n"
}

main "$@"
