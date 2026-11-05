#!/bin/bash
set -euo pipefail
TASK_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
cd "$TASK_DIR/.."
export LC_ALL=C LC_CTYPE=C LANG=C
python3 "$TASK_DIR/verify_data.py"
if [ -z "${MATLAB_BIN:-}" ]; then
  MATLAB_BIN="$(command -v matlab || true)"
  if [ -z "$MATLAB_BIN" ]; then MATLAB_BIN=/Applications/MATLAB_R2023a.app/bin/matlab; fi
fi
"$MATLAB_BIN" -nodesktop -nosplash -singleCompThread -batch "addpath('paper_code');startup_paper;analyze_paper_data;plot_paper_figures;"
