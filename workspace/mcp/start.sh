#!/bin/sh
set -eu

DISPLAY_NUM="${DISPLAY_NUM:-99}"
SCREEN_GEOMETRY="${SCREEN_GEOMETRY:-1920x1080x24}"
VNC_PORT="${VNC_PORT:-5900}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
export DISPLAY=":${DISPLAY_NUM}"

rm -f "/tmp/.X${DISPLAY_NUM}-lock" "/tmp/.X11-unix/X${DISPLAY_NUM}" 2>/dev/null || true

Xvfb "$DISPLAY" -screen 0 "$SCREEN_GEOMETRY" -nolisten tcp -ac &
XVFB_PID=$!

for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ -e "/tmp/.X11-unix/X${DISPLAY_NUM}" ] && break
  sleep 0.2
done

fluxbox >/dev/null 2>&1 &

x11vnc -display "$DISPLAY" -forever -shared -nopw -quiet -rfbport "$VNC_PORT" -bg

websockify --web=/usr/share/novnc "$NOVNC_PORT" "localhost:${VNC_PORT}" >/var/log/novnc.log 2>&1 &

echo "Xvfb on $DISPLAY, VNC on :${VNC_PORT}, noVNC on http://localhost:${NOVNC_PORT}/vnc.html"

exec "$@"
