#!/usr/bin/env bash
# Toggle a pane between its full left/right region and its saved layout.
set -euo pipefail

pane_id=${1:?pane id is required}
window_id=$(tmux display-message -p -t "$pane_id" '#{window_id}')
saved_layout=$(tmux show-window-options -v -t "$window_id" @half_screen_saved_layout 2>/dev/null || true)
saved_panes=$(tmux show-window-options -v -t "$window_id" @half_screen_saved_panes 2>/dev/null || true)
saved_pane_id=$(tmux show-window-options -v -t "$window_id" @half_screen_saved_pane_id 2>/dev/null || true)
current_panes=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | LC_ALL=C sort | paste -sd, -)

if [[ -n $saved_layout ]]; then
  if [[ -n $saved_pane_id && $pane_id != "$saved_pane_id" ]]; then
    # A pane exited that is not the zoomed pane — do not auto-restore.
    exit 0
  elif [[ -n $saved_panes && $saved_panes == "$current_panes" ]] && tmux select-layout -t "$window_id" "$saved_layout"; then
    tmux set-window-option -u -t "$window_id" @half_screen_saved_layout
    tmux set-window-option -u -t "$window_id" @half_screen_saved_panes
    tmux set-window-option -u -t "$window_id" @half_screen_saved_pane_id
    tmux set-window-option -u -t "$window_id" remain-on-exit
    tmux display-message 'Half-screen layout restored'
    exit 0
  fi

  # Pane creation, removal, or movement invalidates tmux's saved layout string.
  tmux set-window-option -u -t "$window_id" @half_screen_saved_layout
  tmux set-window-option -u -t "$window_id" @half_screen_saved_panes 2>/dev/null || true
  tmux set-window-option -u -t "$window_id" @half_screen_saved_pane_id 2>/dev/null || true
  tmux set-window-option -u -t "$window_id" remain-on-exit 2>/dev/null || true
fi

layout=$(tmux display-message -p -t "$pane_id" '#{window_layout}')
read -r pane_left pane_width window_width window_height <<<"$(
  tmux display-message -p -t "$pane_id" '#{pane_left} #{pane_width} #{window_width} #{window_height}'
)"

# A full-height pane on the opposite side identifies the boundary of the
# focused pane's top-level region. This also works when that region contains
# additional nested horizontal and vertical splits.
pane_right=$((pane_left + pane_width))
region_left=$pane_left
region_width=$pane_width
found_region=0

while read -r other_id other_left other_width other_height; do
  (( other_height == window_height )) || continue
  other_right=$((other_left + other_width))

  if (( other_right < pane_left )); then
    region_left=$((other_right + 1))
    region_width=$((window_width - region_left))
    found_region=1
  elif (( pane_right < other_left )); then
    region_left=0
    region_width=$((other_left - 1))
    found_region=1
  fi
done < <(tmux list-panes -t "$window_id" -F '#{pane_id} #{pane_left} #{pane_width} #{pane_height}')

# If both top-level regions are split, fall back to an exact stacked sibling.
if (( ! found_region )); then
  while read -r other_id other_left other_width; do
    if [[ $other_id != "$pane_id" && $other_left == "$pane_left" && $other_width == "$pane_width" ]]; then
      found_region=1
      break
    fi
  done < <(tmux list-panes -t "$window_id" -F '#{pane_id} #{pane_left} #{pane_width}')
fi

if (( ! found_region )); then
  tmux display-message 'Regional zoom needs another pane in the same left/right region'
  exit 0
fi

# Maximize through nested splits while keeping the opposite top-level region at
# its original width. tmux retains one row or column for each live sibling.
tmux resize-pane -t "$pane_id" -y 9999
tmux resize-pane -t "$pane_id" -x "$region_width"

# Keep pane after process exit so pane-died hook can restore the layout.
tmux set-window-option -t "$window_id" remain-on-exit on

tmux set-window-option -t "$window_id" @half_screen_saved_layout "$layout"
tmux set-window-option -t "$window_id" @half_screen_saved_panes "$current_panes"
tmux set-window-option -t "$window_id" @half_screen_saved_pane_id "$pane_id"
tmux display-message 'Pane maximized within its region; press prefix + Z to restore'
