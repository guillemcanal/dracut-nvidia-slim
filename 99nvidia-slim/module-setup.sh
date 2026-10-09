#!/bin/bash
# Install the NVIDIA modules for early KMS, then keep in the initrd only the
# GSP firmware for the installed GPU generation.
# Replaces force_drivers+=" nvidia ... " (which would pull in every firmware).
#
# Optional setting (in /etc/dracut.conf.d/):
#   nvidia_slim_keep: space-separated glob patterns of the firmware files to
#                     keep, e.g. "*_tu10x.bin" (Turing) or "*_ga10x.bin"
#                     (Ampere and later). Default: detected with nvidia-smi.

nvidia_slim_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm"

check() {
    # Only when requested through add_dracutmodules
    return 255
}

depends() {
    return 0
}

# Print the firmware patterns for the installed GPUs, nothing if any is unknown
nvidia_slim_detect() {
    command -v nvidia-smi > /dev/null || return 0

    local arch pats=""
    while read -r arch; do
        case $arch in
            # GA100 (A100) also uses the tu10x firmware
            Turing) pats+=" *_tu10x.bin" ;;
            Ampere | Ada* | Hopper | Blackwell) pats+=" *_ga10x.bin" ;;
            *) return 0 ;;
        esac
    done < <(nvidia-smi -q 2> /dev/null | awk -F': *' '/Product Architecture/ {print $2}' | sort -u)

    echo "${pats# }"
}

installkernel() {
    # shellcheck disable=SC2086
    hostonly='' instmods -c $nvidia_slim_modules || return 1

    local keep_pats=${nvidia_slim_keep:-$(nvidia_slim_detect)}
    if [[ -z ${keep_pats// /} ]]; then
        dwarn "nvidia-slim: unknown GPU architecture, no firmware removed"
        return 0
    fi
    dinfo "nvidia-slim: keeping firmware: $keep_pats"

    local f pat keep=() drop=()
    for f in "$initdir"/usr/lib/firmware/nvidia/[0-9]*/*.bin; do
        [[ -f $f ]] || continue
        for pat in $keep_pats; do
            # shellcheck disable=SC2053
            if [[ ${f##*/} == $pat ]]; then
                keep+=("$f")
                continue 2
            fi
        done
        drop+=("$f")
    done

    if ((${#keep[@]} == 0)); then
        dwarn "nvidia-slim: no firmware matching '$keep_pats' found, nothing removed"
        return 0
    fi

    for f in "${drop[@]}"; do
        dinfo "nvidia-slim: removing ${f#"$initdir"}"
        rm -f -- "$f"
    done
}

install() {
    local mod
    for mod in $nvidia_slim_modules; do
        echo "rd.driver.pre=$mod"
    done > "$initdir/etc/cmdline.d/20-nvidia-slim.conf"
}
