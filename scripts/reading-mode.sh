#!/bin/sh
# Reading mode = constant warm Night Light. Remembers your previous Night Light
# settings and restores them when switched off.
#   reading-mode.sh on [kelvin] | off | status

STATE="${XDG_CACHE_HOME:-$HOME/.cache}/kde-island/reading.prev"

kw() { kwriteconfig6 --file kwinrc --group NightColor --key "$1" "$2"; }
kr() { kreadconfig6 --file kwinrc --group NightColor --key "$1" --default "$2"; }
reload() {
    busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 \
        || qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
}

case "$1" in
    on)
        mkdir -p "$(dirname "$STATE")"
        if [ ! -f "$STATE" ]; then
            printf '%s\n%s\n%s\n' "$(kr Active false)" "$(kr Mode Automatic)" "$(kr NightTemperature 4500)" > "$STATE"
        fi
        kw Active true
        kw Mode Constant
        kw NightTemperature "${2:-3600}"
        reload
        ;;
    off)
        if [ -f "$STATE" ]; then
            kw Active "$(sed -n 1p "$STATE")"
            kw Mode "$(sed -n 2p "$STATE")"
            kw NightTemperature "$(sed -n 3p "$STATE")"
            rm -f "$STATE"
        else
            kw Active false
        fi
        reload
        ;;
    status)
        if [ -f "$STATE" ]; then echo on; else echo off; fi
        ;;
    *)
        echo "usage: $0 on [kelvin] | off | status" >&2
        exit 1
        ;;
esac
