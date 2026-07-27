#!/usr/bin/env bash
# Toggle a stacked pane between its full column height and its saved layout.
set -euo pipefail

pane_id=${1:?pane id is required}
window_id=$(tmux display-message -p -t "$pane_id" '#{window_id}')
saved_layout=$(tmux show-window-options -v -t "$window_id" @half_screen_saved_layout 2>/dev/null || true)
saved_panes=$(tmux show-window-options -v -t "$window_id" @half_screen_saved_panes 2>/dev/null || true)
current_panes=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | LC_ALL=C sort | paste -sd, -)

if [[ -n $saved_layout ]]; then
  if [[ -n $saved_panes && $saved_panes == "$current_panes" ]] && tmux select-layout -t "$window_id" "$saved_layout"; then
    tmux set-window-option -u -t "$window_id" @half_screen_saved_layout
    tmux set-window-option -u -t "$window_id" @half_screen_saved_panes
    tmux display-message 'Half-screen layout restored'
    exit 0
  fi

  # Pane creation, removal, or movement invalidates tmux's saved layout string.
  tmux set-window-option -u -t "$window_id" @half_screen_saved_layout
  tmux set-window-option -u -t "$window_id" @half_screen_saved_panes 2>/dev/null || true
fi

layout=$(tmux display-message -p -t "$pane_id" '#{window_layout}')
read -r pane_left pane_width <<<"$(
  tmux display-message -p -t "$pane_id" '#{pane_left} #{pane_width}'
)"

# Only panes with the same horizontal bounds belong to the same column. This
# preserves the window's left/right split while maximizing within that column.
has_stacked_sibling=0
while read -r other_id other_left other_width; do
  if [[ $other_id != "$pane_id" && $other_left == "$pane_left" && $other_width == "$pane_width" ]]; then
    has_stacked_sibling=1
    break
  fi
done < <(tmux list-panes -t "$window_id" -F '#{pane_id} #{pane_left} #{pane_width}')

if (( ! has_stacked_sibling )); then
  tmux display-message 'Regional zoom needs a pane above or below the active pane'
  exit 0
fi

# tmux keeps one row for each sibling pane; the focused pane receives all
# remaining height in its existing left or right column.
tmux resize-pane -t "$pane_id" -y 9999

tmux set-window-option -t "$window_id" @half_screen_saved_layout "$layout"
tmux set-window-option -t "$window_id" @half_screen_saved_panes "$current_panes"
tmux display-message 'Pane maximized within its column; press prefix + M-z to restore'
