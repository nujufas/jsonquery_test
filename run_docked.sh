#!/usr/bin/env bash
# Runs the suites with the Tools docked in the main window, as tabs: the other half of
# ./run_parallel.sh, which runs them with the Tools in a window of their own (the default).
#
# Two passes, each through run_parallel.sh (see its header for the lanes and the displays):
#   tools      the Tools suites, whose pages are in the main window as tabs. The window is
#              given the size of the Tools window, so a docked page is the window's page pixel
#              for pixel and the cases are the same cases (resources/docked_tools.py); the cases
#              that are about the window itself (tagged window-only) or about the main window's
#              own layout beside a tool (main-layout) are left out.
#   main view  every other suite, with the Json Query tab in front: the main window is the
#              suites' window with a row of tabs on top, which the test library allows for
#              (JQ_DOCKED_DY, resources/docked_main.py). The cases that need the Tools window
#              (window-only) or its pages (uses-tools: they run in the first pass), or that
#              are about the toolbar or the settings file as they are without tabs
#              (undocked-only), are left out.
# The suite of the dock itself (suites/tools/tools_docked.robot) docks and undocks by itself
# and is part of the ordinary run.
#
# Usage: ./run_docked.sh [-j LANES] [tools|main] [robot args...]
#   ./run_docked.sh                 # both passes, 6 lanes
#   ./run_docked.sh -j 4 main       # the main view only
#   ./run_docked.sh tools --test 'TC-FMT-0*'
# JQ_TEST_RESULTS is the folder both passes' results go under (default: results/docked/), each
# in a folder of its own: tools/ and main/. Everything else is as for run_parallel.sh.
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$TEST_DIR" # run_parallel.sh hands each lane the suites' paths from here
LANES=6
if [ "${1:-}" = "-j" ]; then
    LANES="${2:?-j needs a number of lanes}"
    shift 2
fi
PASSES="tools main"
case "${1:-}" in
    tools | main) PASSES="$1"; shift ;;
esac
ROBOT_ARGS=("$@")
RESULTS="${JQ_TEST_RESULTS:-$TEST_DIR/results/docked}"

log() { echo "[run_docked.sh] $*"; }

FAILED=0
for pass in $PASSES; do
    log "Pass: $pass"
    case "$pass" in
        tools)
            export JQ_TOOLS_PLACE=docked JQ_WINDOW_SIZE=900x580
            unset JQ_DOCKED_DY || true
            args=(--include tools --include uses-tools --exclude docked --exclude window-only
                --exclude main-layout --variablefile "$TEST_DIR/resources/docked_tools.py")
            ;;
        main)
            export JQ_TOOLS_PLACE=docked JQ_DOCKED_DY=23
            unset JQ_WINDOW_SIZE || true
            args=(--exclude tools --exclude uses-tools --exclude window-only --exclude undocked-only
                --variablefile "$TEST_DIR/resources/docked_main.py")
            ;;
    esac
    if ! JQ_TEST_RESULTS="$RESULTS/$pass" "$TEST_DIR/run_parallel.sh" -j "$LANES" "${args[@]}" "${ROBOT_ARGS[@]}"; then
        FAILED=1
    fi
done
log "Results: $RESULTS/<pass>/report.html"
exit $FAILED
