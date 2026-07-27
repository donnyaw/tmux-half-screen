#!/usr/bin/env bash
set -euo pipefail

current_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
key=$(tmux show-option -gqv @half-screen-key || true)
key=${key:-Z}

tmux bind-key "$key" run-shell -b "$current_dir/half-screen-toggle.sh '#{pane_id}'"
tmux set-hook -g pane-died "run-shell '$current_dir/half-screen-toggle.sh #{pane_id} auto'"
