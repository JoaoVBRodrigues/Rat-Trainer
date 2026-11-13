#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_GODOT_CONSOLE="/c/Users/João/Downloads/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe"
GODOT_CONSOLE="${GODOT_CONSOLE_EXE:-$DEFAULT_GODOT_CONSOLE}"

if [[ ! -x "$GODOT_CONSOLE" ]]; then
	if command -v godot >/dev/null 2>&1; then
		GODOT_CONSOLE="$(command -v godot)"
	else
		printf 'Godot console executable not found: %s\n' "$GODOT_CONSOLE" >&2
		printf 'Set GODOT_CONSOLE_EXE to its Git Bash path or add godot to PATH.\n' >&2
		exit 127
	fi
fi

cd "$PROJECT_ROOT"
exec "$GODOT_CONSOLE" "$@"
