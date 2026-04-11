#!/bin/bash
# aws_logs コマンドのエントリポイント
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .venv があれば自動で activate
if [[ -f "${SCRIPT_DIR}/.venv/bin/python" ]]; then
    exec "${SCRIPT_DIR}/.venv/bin/python" -m aws_logs "$@"
fi

exec python3 -m aws_logs "$@"
