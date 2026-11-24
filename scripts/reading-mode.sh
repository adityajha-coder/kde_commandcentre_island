#!/bin/sh
# Reading mode = constant warm Night Light. Remembers your previous Night Light
# settings and restores them when switched off.
#   reading-mode.sh on [kelvin] | off | status

STATE="${XDG_CACHE_HOME:-$HOME/.cache}/kde-island/reading.prev"

kw() { kwriteconfig6 --notify --file kwinrc --group NightColor --key "$1" "$2"; }
kwb() { kwriteconfig6 --notify --file kwinrc --group NightColor --key "$1" --type bool "$2"; }
kdel() { kwriteconfig6 --notify --file kwinrc --group NightColor --key "$1" --delete ''; }
kr() { kreadconfig6 --file kwinrc --group NightColor --key "$1" --default ""; }
reload() {
    busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 \
        || qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 \
        || qdbus-qt6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 \
        || true
}

case "$1" in
    on)
        mkdir -p "$(dirname "$STATE")"
        if [ ! -f "$STATE" ]; then
            printf '%s\n%s\n%s\n' "$(kr Active)" "$(kr Mode)" "$(kr NightTemperature)" > "$STATE"
        fi
        kwb Active true
        kw Mode Constant
        kw NightTemperature "${2:-3600}"
        reload
        ;;
    off)
        if [ -f "$STATE" ]; then
            prev_active=$(sed -n 1p "$STATE")
            prev_mode=$(sed -n 2p "$STATE")
            prev_temp=$(sed -n 3p "$STATE")
            if [ -n "$prev_active" ]; then kwb Active "$prev_active"; else kdel Active; fi
            if [ -n "$prev_mode" ]; then kw Mode "$prev_mode"; else kdel Mode; fi
            if [ -n "$prev_temp" ]; then kw NightTemperature "$prev_temp"; else kdel NightTemperature; fi
            rm -f "$STATE"
        else
            kwb Active false
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
