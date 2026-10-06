#!/usr/bin/env bash
# Runs the jsonquery GUI Robot Framework suite end to end:
# builds the app, sets up the Python venv if needed, starts an isolated Xvfb
# display (real desktops don't work here -- see docs/00_test_strategy.md),
# runs the suites, tears everything down, and reports where results landed.
#
# Usage: ./run.sh [target] [robot args...]  (the target path comes FIRST)
#   ./run.sh                                   # run everything
#   ./run.sh suites/tree_view/                 # run one suite
#   ./run.sh suites --include p1               # run only P1-tagged cases
# A second run beside the first: JQ_TEST_DISPLAY=:98 JQ_TEST_RESULTS=/some/dir
#   JQ_TEST_BINARY=/copy/of/jsonquery_gui JQ_TEST_NO_BUILD=1 ./run.sh ...
# The app is its own repository (https://github.com/nujufas/jsonquery_gui). It is
# taken from JQ_APP_DIR if that is set, else from ../jsonquery_gui (where `git clone`
# puts it beside this repository), else from ../jsonquery.
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${JQ_APP_DIR:-}"
if [ -z "$APP_DIR" ]; then
    for candidate in "$TEST_DIR/../jsonquery_gui" "$TEST_DIR/../jsonquery"; do
        if [ -f "$candidate/Cargo.toml" ]; then
            APP_DIR="$candidate"
            break
        fi
    done
fi
if [ -z "$APP_DIR" ] || [ ! -f "$APP_DIR/Cargo.toml" ]; then
    if [ -n "${JQ_APP_DIR:-}" ]; then
        echo "[run.sh] JQ_APP_DIR=$JQ_APP_DIR is not a checkout of the app -- there is no Cargo.toml in it." >&2
    else
        echo "[run.sh] The app is not beside this repository (looked in ../jsonquery_gui and ../jsonquery)." >&2
    fi
    echo "[run.sh] Clone it: git clone https://github.com/nujufas/jsonquery_gui.git ../jsonquery_gui" >&2
    echo "[run.sh] or set JQ_APP_DIR to a checkout of it." >&2
    exit 1
fi
APP_DIR="$(cd "$APP_DIR" && pwd)"
export JQ_APP_DIR="$APP_DIR" # AppLibrary.py and the suites find the binary and Cargo.toml through it
VENV_DIR="$TEST_DIR/.venv"
RESULTS_DIR="${JQ_TEST_RESULTS:-$TEST_DIR/results}"
XVFB_DISPLAY="${JQ_TEST_DISPLAY:-:99}"
XVFB_SIZE="1280x900x24"

PYENV_PYTHON="$HOME/.pyenv/versions/3.12.3/bin/python3.12"

log() { echo "[run.sh] $*"; }

log "App checkout: $APP_DIR; binary under test: ${JQ_TEST_BINARY:-$APP_DIR/target/debug/jsonquery_gui}"

# -- 1. build the app -----------------------------------------------------
# JQ_TEST_NO_BUILD=1 (with JQ_TEST_BINARY pointing at a copy) runs against a
# binary a rebuild will not replace; see AppLibrary.py.
if [ -z "${JQ_TEST_NO_BUILD:-}" ]; then
    log "Building jsonquery_gui..."
    (cd "$APP_DIR" && cargo build -p jsonquery_gui)
fi

# -- 2. venv ----------------------------------------------------------------
if [ ! -x "$VENV_DIR/bin/robot" ]; then
    log "Setting up test venv (Python 3.12, see 00_test_strategy.md for why)..."
    if [ -x "$PYENV_PYTHON" ]; then
        "$PYENV_PYTHON" -m venv "$VENV_DIR"
    else
        log "pyenv 3.12.3 not found at $PYENV_PYTHON -- falling back to python3, but"
        log "requirements.txt is only confirmed against 3.12; this may fail to install."
        python3 -m venv "$VENV_DIR"
    fi
    "$VENV_DIR/bin/pip" install --upgrade pip -q
    "$VENV_DIR/bin/pip" install -r "$TEST_DIR/requirements.txt"
fi
# A venv made before the file dialogs could be answered lacks jeepney (resources/fake_portal.py).
if ! "$VENV_DIR/bin/python" -c "import jeepney" >/dev/null 2>&1; then
    log "Installing the Python packages added since this venv was made..."
    "$VENV_DIR/bin/pip" install -q -r "$TEST_DIR/requirements.txt"
fi

# -- 3. system prerequisites (fail fast with a clear message) ---------------
missing=()
for bin in Xvfb fluxbox xdotool wmctrl tesseract gnome-screenshot xclip dbus-daemon; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if [ ${#missing[@]} -gt 0 ]; then
    log "Missing required system packages: ${missing[*]}"
    log "Install with: sudo apt install tesseract-ocr wmctrl xclip xvfb fluxbox gnome-screenshot xdotool dbus-daemon"
    exit 1
fi

# -- 4. isolated display: Xvfb must exist before Python (and therefore Robot)
#       ever starts, since pyautogui probes DISPLAY at import time -----------
# python-xlib (pulled in by pyautogui) refuses to talk to an X server unless the
# Xauthority file exists, even to Xvfb, which needs no authorization. A desktop session
# usually provides one; a fresh account, a container or a CI runner may not.
XAUTH_FILE="${XAUTHORITY:-$HOME/.Xauthority}"
[ -e "$XAUTH_FILE" ] || touch "$XAUTH_FILE" 2>/dev/null || true

cleanup() {
    log "Tearing down test display..."
    [ -n "${FLUXBOX_PID:-}" ] && kill -9 "$FLUXBOX_PID" 2>/dev/null || true
    if [ "$STARTED_XVFB" = "1" ] && [ -n "${XVFB_PID:-}" ]; then
        kill -9 "$XVFB_PID" 2>/dev/null || true
        rm -f "/tmp/.X${XVFB_DISPLAY#:}-lock"
    fi
}
trap cleanup EXIT

STARTED_XVFB=0
if [ -e "/tmp/.X11-unix/X${XVFB_DISPLAY#:}" ] && ! DISPLAY="$XVFB_DISPLAY" xdotool getdisplaygeometry >/dev/null 2>&1; then
    log "Found a stale Xvfb socket for $XVFB_DISPLAY with nothing listening -- clearing it."
    rm -f "/tmp/.X${XVFB_DISPLAY#:}-lock" "/tmp/.X11-unix/X${XVFB_DISPLAY#:}"
fi
if [ ! -e "/tmp/.X11-unix/X${XVFB_DISPLAY#:}" ]; then
    log "Starting Xvfb on $XVFB_DISPLAY..."
    Xvfb "$XVFB_DISPLAY" -screen 0 "$XVFB_SIZE" -nolisten tcp &
    XVFB_PID=$!
    STARTED_XVFB=1
    sleep 1
else
    log "Xvfb already running on $XVFB_DISPLAY, reusing it."
fi
export DISPLAY="$XVFB_DISPLAY"

# fluxbox: bare Xvfb has no window manager, which silently breaks keyboard
# focus (confirmed -- see 00_test_strategy.md). The Deco:NONE apps rule is
# required for AppLibrary's window-relative coordinates to be accurate;
# AppLibrary writes it itself on Suite Setup, but write it here too so it
# exists before fluxbox's very first launch in a brand new environment.
mkdir -p "$HOME/.fluxbox"
if ! grep -q "class=jsonquery_gui" "$HOME/.fluxbox/apps" 2>/dev/null; then
    printf '[app] (class=jsonquery_gui)\n  [Deco] {NONE}\n[end]\n' >> "$HOME/.fluxbox/apps"
fi
fluxbox >/dev/null 2>&1 &
FLUXBOX_PID=$!
sleep 1

# -- 5. run the suite ---------------------------------------------------------
mkdir -p "$RESULTS_DIR"
TARGET="${1:-$TEST_DIR/suites}"
if [ "$#" -gt 0 ]; then
    shift
fi

log "Running Robot Framework suite(s): $TARGET"
set +e
"$VENV_DIR/bin/robot" \
    --outputdir "$RESULTS_DIR" \
    --pythonpath "$TEST_DIR/resources" \
    "$@" \
    "$TARGET"
RC=$?
set -e

log "Results: $RESULTS_DIR/report.html (summary), $RESULTS_DIR/log.html (detail)"
exit $RC
