#!/usr/bin/env bash
set -Eeuo pipefail

# These unselected packages in the pinned vendor feeds contain known Kconfig
# recursion loops. Remove only package symlinks; never modify feed source trees.
cd "${1:?OpenWrt source directory required}"

if ! grep -q '^CONFIG_PACKAGE_qt5base-' .config; then
  rm -f package/feeds/video/qt5base
fi

if ! grep -q '^CONFIG_PACKAGE_qt6base-' .config; then
  rm -f package/feeds/video/qt6quick package/feeds/video/qt6svg
fi

if ! grep -q '^CONFIG_PACKAGE_fwknopd=y' .config &&
   ! grep -q '^CONFIG_PACKAGE_luci-app-fwknopd=y' .config; then
  rm -f package/feeds/packages/fwknop
  rm -f package/feeds/luci/luci-app-fwknopd
  rm -f package/feeds/packages/luci-app-fwknopd
fi

if ! grep -q '^CONFIG_PACKAGE_squeezelite-custom=y' .config; then
  rm -f package/feeds/*/squeezelite-custom
fi

echo "Removed only unselected feed links known to trigger recursive Kconfig dependencies."
