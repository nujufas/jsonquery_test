#!/usr/bin/env bash
# Runs the whole suite in several lanes at once and merges the results into one report.
#
# One display runs a case at a time and the app is launched for every case, so a full run on
# a single display takes well over an hour. This script builds the app once, makes one copy of
# the binary that a rebuild cannot replace, splits the suite files over the lanes (by their
# number of cases, so that the lanes finish together) and runs each lane through run.sh on a
# display and a results directory of its own. The lanes' outputs are then merged with rebot.
#
# Usage: ./run_parallel.sh [-j LANES] [robot args...]
#   ./run_parallel.sh                        # 6 lanes, every suite
#   ./run_parallel.sh -j 8                   # 8 lanes
#   ./run_parallel.sh -j 4 --include p1      # only the cases tagged p1, in 4 lanes
#   ./run_parallel.sh -j 3 --test 'TC-FMT-0*'  # a lane that has no such case just has nothing to do
# Environment (all optional):
#   JQ_TEST_RESULTS            where the results go          (default: results/parallel/)
#   JQ_PARALLEL_DISPLAY_BASE   first display, one per lane   (default: 120, so :120, :121, ...)
#   JQ_APP_DIR, JQ_TEST_BINARY, JQ_TEST_NO_BUILD             as for run.sh
# Each lane starts its own virtual display, window manager and D-Bus (for the file dialogs), and
# a lane needs 1-2 GB of memory with a debug build of the app: about 6 lanes suit a 16-thread
# machine with 32 GB. More lanes than that run, but timing-sensitive cases get less reliable.
# Needs the venv that run.sh makes, so run ./run.sh suites/launch_and_window/ once first.
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$TEST_DIR/.venv"
LANES=6
if [ "${1:-}" = "-j" ]; then
    LANES="${2:?-j needs a number of lanes}"
    shift 2
fi
case "$LANES" in '' | *[!0-9]* | 0) echo "[run_parallel.sh] -j wants a positive number, not '$LANES'." >&2; exit 2 ;; esac
ROBOT_ARGS=("$@")

log() { echo "[run_parallel.sh] $*"; }

if [ ! -x "$VENV_DIR/bin/robot" ]; then
    log "There is no $VENV_DIR yet: run ./run.sh suites/launch_and_window/ once first; it creates it." >&2
    exit 1
fi

# -- the app, as run.sh finds it -------------------------------------------------------------
APP_DIR="${JQ_APP_DIR:-}"
if [ -z "$APP_DIR" ]; then
    for candidate in "$TEST_DIR/../jsonquery_gui" "$TEST_DIR/../jsonquery"; do
        if [ -f "$candidate/Cargo.toml" ]; then APP_DIR="$candidate"; break; fi
    done
fi
if [ -z "$APP_DIR" ] || [ ! -f "$APP_DIR/Cargo.toml" ]; then
    log "The app is not beside this repository (see run.sh); set JQ_APP_DIR." >&2
    exit 1
fi
APP_DIR="$(cd "$APP_DIR" && pwd)"
export JQ_APP_DIR="$APP_DIR"
if [ -z "${JQ_TEST_NO_BUILD:-}" ]; then
    log "Building jsonquery_gui..."
    (cd "$APP_DIR" && cargo build -p jsonquery_gui)
fi
BINARY="${JQ_TEST_BINARY:-$APP_DIR/target/debug/jsonquery_gui}"
[ -x "$BINARY" ] || { log "No binary at $BINARY." >&2; exit 1; }

RESULTS="${JQ_TEST_RESULTS:-$TEST_DIR/results/parallel}"
BASE="${JQ_PARALLEL_DISPLAY_BASE:-120}"
rm -rf "$RESULTS"
mkdir -p "$RESULTS/.bin"
FROZEN="$RESULTS/.bin/jsonquery_gui"
trap 'rm -rf "$RESULTS/.bin" "$RESULTS/tmp"' EXIT
cp --reflink=auto "$BINARY" "$FROZEN"

# -- split the suite files over the lanes: the biggest first, each to the emptiest lane -------
mapfile -t ASSIGNMENT < <("$VENV_DIR/bin/python" - "$TEST_DIR" "$LANES" <<'PY'
import pathlib, re, sys
root, lanes = pathlib.Path(sys.argv[1]), int(sys.argv[2])
weights = {}
for path in sorted((root / "suites").rglob("*.robot")):
    text = path.read_text(encoding="utf-8")
    weights[path.relative_to(root).as_posix()] = len(re.findall(r"^TC-", text, re.M))
load = [0] * lanes
files = [[] for _ in range(lanes)]
for path, weight in sorted(weights.items(), key=lambda item: (-item[1], item[0])):
    lane = load.index(min(load))
    load[lane] += weight
    files[lane].append(path)
for lane in range(lanes):
    if files[lane]:
        print(f"{lane + 1}\t{load[lane]}\t{' '.join(files[lane])}")
PY
)

# -- start the lanes ----------------------------------------------------------------------------
PIDS=()
NAMES=()
for line in "${ASSIGNMENT[@]}"; do
    IFS=$'\t' read -r lane weight files <<<"$line"
    display=":$((BASE + lane - 1))"
    if [ -e "/tmp/.X11-unix/X$((BASE + lane - 1))" ] && DISPLAY="$display" xdotool getdisplaygeometry >/dev/null 2>&1; then
        log "Display $display is in use; set JQ_PARALLEL_DISPLAY_BASE to a free range." >&2
        kill "${PIDS[@]}" 2>/dev/null || true
        exit 1
    fi
    read -r -a lane_files <<<"$files"
    log "Lane $lane on $display: $weight cases in ${#lane_files[@]} file(s)"
    mkdir -p "$RESULTS/tmp/lane$lane"
    (
        # Each lane's temporary files (the saved files, OCR images, the app's own) go to disk, under
        # the results: /tmp is often a small tmpfs, and a full one fails cases with "Disk quota exceeded".
        TMPDIR="$RESULTS/tmp/lane$lane" \
            JQ_TEST_DISPLAY="$display" JQ_TEST_RESULTS="$RESULTS/lane$lane" \
            JQ_TEST_NO_BUILD=1 JQ_TEST_BINARY="$FROZEN" \
            "$TEST_DIR/run.sh" "${lane_files[0]}" "${ROBOT_ARGS[@]}" --runemptysuite "${lane_files[@]:1}" \
            >"$RESULTS/lane$lane.log" 2>&1
    ) &
    PIDS+=($!)
    NAMES+=("$lane")
    sleep 2 # let each lane start its Xvfb before the next one looks for a free display
done

# -- wait, then merge ---------------------------------------------------------------------------
FAILED=0
for i in "${!PIDS[@]}"; do
    if wait "${PIDS[$i]}"; then
        log "Lane ${NAMES[$i]} passed."
    else
        log "Lane ${NAMES[$i]} did not pass (exit status $?): see $RESULTS/lane${NAMES[$i]}.log"
        FAILED=1
    fi
done

OUTPUTS=()
for lane in "${NAMES[@]}"; do
    [ -f "$RESULTS/lane$lane/output.xml" ] && OUTPUTS+=("$RESULTS/lane$lane/output.xml")
done
if [ ${#OUTPUTS[@]} -eq 0 ]; then
    log "No lane wrote any results." >&2
    exit 1
fi
mkdir -p "$RESULTS/screenshots"
for lane in "${NAMES[@]}"; do # the merged log looks for the images beside itself
    [ -d "$RESULTS/lane$lane/screenshots" ] && cp -r "$RESULTS/lane$lane/screenshots/." "$RESULTS/screenshots/"
done
set +e
"$VENV_DIR/bin/rebot" --outputdir "$RESULTS" --output output.xml --name "jsonquery GUI" --processemptysuite "${OUTPUTS[@]}" >/dev/null
set -e
"$VENV_DIR/bin/python" - "$RESULTS/output.xml" <<'PY'
import sys
from robot.api import ExecutionResult
result = ExecutionResult(sys.argv[1])
total = result.statistics.total
print(f"[run_parallel.sh] {total.total} tests, {total.passed} passed, {total.failed} failed")
def failures(suite):
    for test in suite.tests:
        if test.status == "FAIL":
            print(f"[run_parallel.sh]   FAIL {test.name}: {test.message[:160]!r}")
    for sub in suite.suites:
        failures(sub)
failures(result.suite)
PY
log "Merged results: $RESULTS/report.html (summary), $RESULTS/log.html (detail), $RESULTS/output.xml"
exit $FAILED
