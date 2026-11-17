#!/usr/bin/env bash
# AISTVM: best-effort idle-timeout keepalive.
# Prints a line to a pseudo-terminal so GitHub counts it as terminal activity.
set -uo pipefail

SESSION="aistvm-keepalive"
INTERVAL=180
STATUS_DIR=".aistvm"
LOG_FILE="${STATUS_DIR}/keepalive.log"
mkdir -p "${STATUS_DIR}"

# Inner mode: this branch runs inside the pty and is the only thing that emits
# output. It is started below, never executed directly by the app.
if [ "${1:-}" = "--loop" ]; then
  while true; do
    printf '[%s] aistvm keepalive\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    sleep "${INTERVAL}"
  done
fi

SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
QUOTED_SELF="$(printf '%q' "${SELF}")"
INNER="bash ${QUOTED_SELF} --loop"

# Clear any keepalive left over from a previous start so they do not stack up.
tmux kill-session -t "${SESSION}" >/dev/null 2>&1 || true
pkill -f "${SELF} --loop" >/dev/null 2>&1 || true

if command -v tmux >/dev/null 2>&1; then
  tmux new-session -d -s "${SESSION}" "${INNER}" \
    >>"${LOG_FILE}" 2>&1 && exit 0
fi

# Fallback: script(1) also allocates a pty for the loop.
if command -v script >/dev/null 2>&1; then
  nohup script -qfc "${INNER}" /dev/null \
    >>"${LOG_FILE}" 2>&1 &
  exit 0
fi

exit 1
