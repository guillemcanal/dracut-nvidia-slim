#!/bin/bash
# Remove the nvidia-slim dracut module and restore NVIDIA force_drivers.
# Does not rebuild the initrd: run dracut --force [--regenerate-all] afterwards.
set -euo pipefail

MODDIR=/usr/lib/dracut/modules.d/99nvidia-slim
CONFDIR=/etc/dracut.conf.d
CONF=$CONFDIR/nvidia.conf

[[ $EUID -eq 0 ]] || exec sudo -- "$0" "$@"

src=$(cd "$(dirname "$0")" && pwd)

rm -f -- "$MODDIR/module-setup.sh"
rmdir -- "$MODDIR" 2> /dev/null || true
echo "Removed: $MODDIR"

install -m 644 "$src/conf/nvidia.conf" "$CONF"
echo "Installed: $CONF (force_drivers nvidia, nouveau omitted)"

# Config file from a previous version of this project
rm -f -- "$CONFDIR/zz-nvidia-slim.conf"
