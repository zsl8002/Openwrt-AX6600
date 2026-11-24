#!/usr/bin/env bash
set -Eeuo pipefail

# These unselected packages in the pinned vendor feeds contain known Kconfig
# recursion loops. Remove only feed symlinks; never modify feed source trees or
# regular files. Treat built-in (y) and module (m) selections as selected.
cd "${1:?OpenWrt source directory required}"

remove_unselected_link() {
  local link="$1"
  if [ -L "$link" ]; then
    rm -f -- "$link"
    echo "Removed unselected feed symlink: $link"
  elif [ -e "$link" ]; then
    echo "::error::Expected a feed symlink; refusing to remove: $link" >&2
    exit 1
  fi
}

# qt5base contains a choice dependency loop. Keep it if any Qt5 package is
# selected, including module selections and dependencies from the seed config.
if ! grep -Eq '^CONFIG_PACKAGE_qt5[^=]*=(y|m)$' .config; then
  remove_unselected_link package/feeds/video/qt5base
fi

# These optional Qt6 consumers refer to split qt6base packages that are not
# present in this pinned feed snapshot. Preserve them whenever any Qt6 package
# is selected.
if ! grep -Eq '^CONFIG_PACKAGE_qt6[^=]*=(y|m)$' .config; then
  remove_unselected_link package/feeds/video/qt6quick
  remove_unselected_link package/feeds/video/qt6svg
fi

# fwknopd and its LuCI app form a dependency cycle through FWKNOPD_GPG.
# Keep both feeds if either package is selected as built-in or as a module.
if ! grep -Eq '^CONFIG_PACKAGE_fwknopd=(y|m)$' .config &&
   ! grep -Eq '^CONFIG_PACKAGE_luci-app-fwknopd=(y|m)$' .config; then
  remove_unselected_link package/feeds/packages/fwknop
  remove_unselected_link package/feeds/luci/luci-app-fwknopd
  remove_unselected_link package/feeds/packages/luci-app-fwknopd
fi

# The feed directory is named "squeezelite", while its generated Kconfig
# symbol/package name is "squeezelite-custom". Remove only its unselected
# feed symlink; retain it for both built-in and module selections.
if ! grep -Eq '^CONFIG_PACKAGE_squeezelite-custom=(y|m)$' .config; then
  for link in package/feeds/*/squeezelite package/feeds/*/squeezelite-custom; do
    [ -L "$link" ] || [ -e "$link" ] || continue
    remove_unselected_link "$link"
  done
fi

echo "Unselected recursive-dependency feed links checked."
