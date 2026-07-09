#!/bin/sh
# Scaffold a new thin-edge.io extension Router App.
#
# Usage: scripts/new-extension.sh <name> ["Short summary"]
#
# Creates modules/<name>/ from the extension template and registers it in
# modules/Rules.mk so the recursive build picks it up. See docs/EXTENSION-API.md.
set -eu

NAME="${1:-}"
SUMMARY="${2:-A thin-edge.io extension Router App.}"
PLATFORMS_DEFAULT="v2i v3 v4 v4i"

if [ -z "$NAME" ]; then
    echo "Usage: $0 <name> [\"Short summary\"]" >&2
    exit 2
fi
case "$NAME" in
    *[!a-z0-9_-]*|"") echo "ERROR: name must be lowercase [a-z0-9_-]: '$NAME'" >&2; exit 2 ;;
    tedge)            echo "ERROR: 'tedge' is the platform module, pick another name" >&2; exit 2 ;;
esac

# Resolve repo root from this script's location (scripts/..).
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MOD="$ROOT/modules/$NAME"
UPPER=$(printf '%s' "$NAME" | tr '[:lower:]-' '[:upper:]_')

if [ -e "$MOD" ]; then
    echo "ERROR: $MOD already exists" >&2
    exit 1
fi

echo "==> Creating modules/$NAME"
mkdir -p "$MOD/merge/etc" "$MOD/merge/opt/$NAME/bin" "$MOD/merge/opt/$NAME/operations/c8y"

# --- Makefile (no INSTALL: an extension bundles no thin-edge.io runtime) ------
cat > "$MOD/Makefile" <<EOF
include ../../Rules.mk

# An extension Router App overlays merge/ (and optionally compiles source/) into
# images/$NAME/$NAME.<platform>.tgz. It bundles no thin-edge.io runtime and has
# no INSTALL line, so the build needs no downloads. It integrates with the tedge
# platform at runtime (local MQTT bus + operations registry). See
# docs/EXTENSION-API.md.
\$(eval \$(build-module))
EOF

# --- Module metadata ----------------------------------------------------------
printf '%s\n' "$NAME" > "$MOD/merge/etc/name"
printf '%s\n' "1.0.0" > "$MOD/merge/etc/version"
printf '%s\n' "$SUMMARY" > "$MOD/merge/etc/summary"
cat > "$MOD/merge/etc/description" <<EOF
$SUMMARY

This is a thin-edge.io extension Router App. It integrates with the thin-edge.io
platform module at runtime over the local MQTT bus and, optionally, by
registering Cumulocity operations. Install the thin-edge.io platform module
first, then this extension. See docs/EXTENSION-API.md.
EOF

# --- Settings (shown in the web UI) ------------------------------------------
cat > "$MOD/merge/etc/defaults" <<EOF
# $NAME extension configuration.
#
# Copied to /opt/$NAME/etc/settings on first install; editable from the router
# web interface or directly. Run "/opt/$NAME/etc/init restart" after a change.

# Start the extension automatically (1 = enabled, 0 = disabled).
MOD_${UPPER}_ENABLED=0
EOF

# --- Service control ----------------------------------------------------------
cat > "$MOD/merge/etc/init" <<EOF
#!/bin/sh
# ICR-OS service control for the $NAME extension.
# Called with start|stop|restart|status|defaults. Supervises the extension's
# daemon directly via a pid file (no dependency on the host init system).

MOD_NAME=$NAME
MOD_DIR=/opt/\$MOD_NAME
BIN=\$MOD_DIR/bin
MOD_DEFAULTS=\$MOD_DIR/etc/defaults
MOD_SETTINGS=\$MOD_DIR/etc/settings
[ -L "\$MOD_SETTINGS" ] && MOD_SETTINGS=\$(readlink "\$MOD_SETTINGS")

# thin-edge.io environment (PATH incl. the tedge CLI, TEDGE_CONFIG_DIR, ...).
[ -f /opt/tedge/env ] && . /opt/tedge/env

[ -f "\$MOD_SETTINGS" ] || cp "\$MOD_DEFAULTS" "\$MOD_SETTINGS"
. "\$MOD_SETTINGS"

if   [ -d /var/run ]; then PIDDIR=/var/run
elif [ -d /run ];     then PIDDIR=/run
else                       PIDDIR=/tmp
fi
LOGDIR=/var/log/\$MOD_NAME
mkdir -p "\$LOGDIR" 2>/dev/null || true
PIDFILE="\$PIDDIR/\$MOD_NAME-agent.pid"

log() { /usr/bin/logger -t "\$MOD_NAME" "\$1" 2>/dev/null; echo "\$1"; }

is_running() {
    [ -f "\$PIDFILE" ] || return 1
    kill -0 "\$(cat "\$PIDFILE" 2>/dev/null)" 2>/dev/null
}

start_ext() {
    if is_running; then echo "  \$MOD_NAME-agent already running"; return 0; fi
    log "Starting \$MOD_NAME"
    "\$BIN/\$MOD_NAME-agent" >> "\$LOGDIR/agent.log" 2>&1 &
    echo \$! > "\$PIDFILE"
    echo "  started \$MOD_NAME-agent (pid \$!)"
}

stop_ext() {
    log "Stopping \$MOD_NAME"
    if [ -f "\$PIDFILE" ]; then
        kill "\$(cat "\$PIDFILE" 2>/dev/null)" 2>/dev/null
        rm -f "\$PIDFILE"
    fi
    pkill -f "\$BIN/\$MOD_NAME-agent" 2>/dev/null || true
    echo "  stopped \$MOD_NAME-agent"
}

case "\$1" in
    start)
        [ "\$MOD_${UPPER}_ENABLED" = "1" ] || { echo "\$MOD_NAME is disabled (set MOD_${UPPER}_ENABLED=1)"; exit 0; }
        start_ext ;;
    stop)
        stop_ext ;;
    restart)
        stop_ext; sleep 1
        [ "\$MOD_${UPPER}_ENABLED" = "1" ] || { echo "\$MOD_NAME is disabled (set MOD_${UPPER}_ENABLED=1)"; exit 0; }
        start_ext ;;
    status)
        echo "Module \$MOD_NAME:"
        if is_running; then echo "  \$MOD_NAME-agent: running"; else echo "  \$MOD_NAME-agent: stopped"; exit 1; fi ;;
    defaults)
        cp "\$MOD_DEFAULTS" "\$MOD_SETTINGS"; echo "Settings reset to defaults" ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|defaults}"; exit 1 ;;
esac
EOF

# --- Install: chmod, register c8y operations, reload -------------------------
cat > "$MOD/merge/etc/install" <<EOF
#!/bin/sh
# Executed once by ICR-OS when the extension is installed.
set -e
MOD_DIR=/opt/$NAME
TEDGE_DIR=/opt/tedge

# The tedge platform module must be installed first (provides the MQTT bus,
# the CLI and the operations registry).
if [ ! -d "\$TEDGE_DIR" ]; then
    echo "ERROR: the thin-edge.io platform module (/opt/tedge) is not installed." >&2
    echo "Install it before this extension. See docs/EXTENSION-API.md." >&2
    exit 1
fi

# Promote settings on first install (never clobber operator changes).
[ -f "\$MOD_DIR/etc/settings" ] || cp "\$MOD_DIR/etc/defaults" "\$MOD_DIR/etc/settings"

# Make shipped scripts executable.
chmod +x "\$MOD_DIR/bin/"* "\$MOD_DIR/etc/init" 2>/dev/null || true

# Register this extension's Cumulocity custom operations into the platform's
# operations registry, then ask the mapper to re-announce supported operations.
if [ -d "\$MOD_DIR/operations/c8y" ]; then
    mkdir -p "\$TEDGE_DIR/operations/c8y"
    for f in "\$MOD_DIR"/operations/c8y/*; do
        [ -e "\$f" ] || continue
        ln -sf "\$f" "\$TEDGE_DIR/operations/c8y/\$(basename "\$f")"
    done
    tedge reconnect c8y >/dev/null 2>&1 || true
fi

exit 0
EOF

# --- Uninstall: deregister, stop, reload -------------------------------------
cat > "$MOD/merge/etc/uninstall" <<EOF
#!/bin/sh
# Executed by ICR-OS when the extension is removed.
MOD_DIR=/opt/$NAME
TEDGE_DIR=/opt/tedge

[ -x "\$MOD_DIR/etc/init" ] && "\$MOD_DIR/etc/init" stop 2>/dev/null

# Remove only the operation links that point back into this extension.
if [ -d "\$TEDGE_DIR/operations/c8y" ]; then
    for l in "\$TEDGE_DIR"/operations/c8y/*; do
        [ -h "\$l" ] || continue
        case "\$(readlink "\$l" 2>/dev/null)" in
            "\$MOD_DIR"/*) rm -f "\$l" ;;
        esac
    done
    tedge reconnect c8y >/dev/null 2>&1 || true
fi

exit 0
EOF

# --- A starter daemon (Pattern A: MQTT participant) --------------------------
cat > "$MOD/merge/opt/$NAME/bin/$NAME-agent" <<EOF
#!/bin/sh
# $NAME extension daemon — a thin-edge.io MQTT participant (Pattern A).
#
# Subscribes to a local command topic and acts on it. Replace the handler with
# your own logic. Test locally with:
#   tedge mqtt pub '$NAME/main/cmd' 'hello'
set -eu
[ -f /opt/tedge/env ] && . /opt/tedge/env

TOPIC="$NAME/+/cmd"
echo "\$(date '+%F %T') $NAME-agent: subscribing to \$TOPIC"

tedge mqtt sub "\$TOPIC" | while IFS= read -r line; do
    echo "\$(date '+%F %T') $NAME-agent: received: \$line"
    # TODO: act on the message here.
done
EOF

# --- README for the operations dir -------------------------------------------
cat > "$MOD/merge/opt/$NAME/operations/c8y/.gitkeep" <<EOF
Cumulocity custom-operation declarations live here (Pattern B). Files placed
here are symlinked into /opt/tedge/operations/c8y/ by etc/install. See
docs/EXTENSION-API.md and modules/relay for a worked example.
EOF

# --- CHANGELOG ---------------------------------------------------------------
cat > "$MOD/CHANGELOG.txt" <<EOF
$NAME Router App - Changelog
$(printf '%*s' $((${#NAME} + 22)) '' | tr ' ' '=')

1.0.0
-----
* Initial release. thin-edge.io extension scaffolded by scripts/new-extension.sh.
EOF

chmod +x "$MOD/merge/etc/init" "$MOD/merge/etc/install" "$MOD/merge/etc/uninstall" \
         "$MOD/merge/opt/$NAME/bin/$NAME-agent"

# --- Register in the platform build matrix -----------------------------------
RULES="$ROOT/modules/Rules.mk"
if grep -q "^$NAME[[:space:]]*=" "$RULES" 2>/dev/null; then
    echo "==> modules/Rules.mk already lists '$NAME'"
else
    printf '%s = %s\n' "$NAME" "$PLATFORMS_DEFAULT" >> "$RULES"
    echo "==> Registered '$NAME' in modules/Rules.mk ($PLATFORMS_DEFAULT)"
fi

cat <<EOF

Created modules/$NAME. Next:
  1. Edit modules/$NAME/merge/opt/$NAME/bin/$NAME-agent (your logic).
  2. Add Cumulocity operations under merge/opt/$NAME/operations/c8y/ (see modules/relay).
  3. Build:  make PLATFORMS="v4i"   ->  images/$NAME/$NAME.v4i.tgz
EOF
