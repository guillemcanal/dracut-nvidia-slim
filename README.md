# NVIDIA early KMS without the unused firmware for Dracut

A dracut module that adds the NVIDIA drivers to the initrd for early KMS, with only the GSP firmware the installed GPU needs.

## Why

With `force_drivers+=" nvidia ... "`, dracut copies every firmware the `nvidia`
module declares, for every GPU generation. With `hostonly`, it also adds
`nouveau` and its GSP firmware, even when `nouveau` is blacklisted. On a Turing
laptop (Quadro T2000), this gave a 235 MB initrd, mostly firmware the GPU never
loads.

| Configuration                           | initrd |
|-----------------------------------------|--------|
| `force_drivers` nvidia                  | 235 MB |
| `force_drivers` nvidia, nouveau omitted | 116 MB |
| `nvidia-slim`, nouveau omitted          |  61 MB |

dracut cannot exclude individual firmware files: `omit_drivers` only matches
module names. Instead, `nvidia-slim` installs the NVIDIA modules itself and
then removes the firmware files the GPU doesn't need.

## How it works

- Installs `nvidia`, `nvidia_modeset`, `nvidia_uvm` and `nvidia_drm`, and adds
  `rd.driver.pre=` for each module.
- Keeps `*_tu10x.bin` for Turing, or `*_ga10x.bin` for Ampere, Ada, Hopper and
  Blackwell. The architecture is detected with `nvidia-smi` at build time.
- Removes nothing if the architecture is unknown.

To choose the firmware manually, set the patterns in `/etc/dracut.conf.d/`:

```sh
nvidia_slim_keep="*_tu10x.bin"
```

## Usage

Both scripts manage `/etc/dracut.conf.d/nvidia.conf`, and both omit `nouveau`.
Neither rebuilds the initrd.

```sh
./install.sh     # module + add_dracutmodules+=" nvidia-slim "
./uninstall.sh   # no module + force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
```

Then rebuild the initrd:

```sh
sudo dracut --force --regenerate-all
```

> [!IMPORTANT]
> Remove any other NVIDIA `force_drivers` line from `/etc/dracut.conf.d/`, or the
> module has no effect. `install.sh` warns when it finds one.

## Check

```sh
sudo lsinitrd /boot/initrd.img-$(uname -r) | grep -E 'firmware/nvidia|nouveau'
```
