#!/bin/bash
# Install the nvidia-slim dracut module and the config that enables it.
# Does not rebuild the initrd: run dracut --force [--regenerate-all] afterwards.
set -euo pipefail

MODDIR=/usr/lib/dracut/modules.d/99nvidia-slim
CONFDIR=/etc/dracut.conf.d
CONF=$CONFDIR/nvidia.conf

[[ $EUID -eq 0 ]] || exec sudo -- "$0" "$@"

src=$(cd "$(dirname "$0")" && pwd)

install -D -m 755 "$src/99nvidia-slim/module-setup.sh" "$MODDIR/module-setup.sh"
echo "Installed: $MODDIR"

install -m 644 "$src/conf/nvidia-slim.conf" "$CONF"
echo "Installed: $CONF (nvidia-slim, nouveau omitted)"

# Config file from a previous version of this project
rm -f -- "$CONFDIR/zz-nvidia-slim.conf"

# An NVIDIA force_drivers elsewhere would pull in every firmware again
if grep -HnE '^[^#]*force_drivers.*nvidia' "$CONFDIR"/*.conf | grep -v "^$CONF:"; then
    echo "Warning: remove these force_drivers lines, or nvidia-slim has no effect." >&2
fi
