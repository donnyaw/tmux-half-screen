# tmux-half-screen

Regional column zoom for tmux — expand a stacked pane within its left or right column without affecting the other side. Press again to restore the exact layout.

## Demo

```
┌───────────────┬───────────────┐      ┌───────────────┬───────────────┐
│               │ right-top     │      │               │               │
│ left          ├───────────────┤  ->  │ left          │ focused right │
│               │ right-bottom  │      │               │               │
└───────────────┴───────────────┘      └───────────────┴───────────────┘
```

Works on either side — left or right columns.

## Requirements

- tmux ≥ 3.0
- bash

## Installation

### TPM (recommended)

```tmux
set -g @plugin 'donnyaw/tmux-half-screen'
```

Press `prefix + I` to install.

### Manual

1. Clone the repo:

```bash
git clone https://github.com/donnyaw/tmux-half-screen ~/.tmux/plugins/tmux-half-screen
```

2. Add to `.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-half-screen/half-screen-toggle.sh
bind Z run-shell -b "~/.tmux/plugins/tmux-half-screen/half-screen-toggle.sh '#{pane_id}'"
```

## Usage

1. Create your standard split layout (e.g. left pane + right stack).
2. Focus the pane you want to expand.
3. Press `Ctrl+Space` (your prefix), release it, then press `Z`.
4. Press `prefix + Z` again to restore the original layout.

`prefix + z` (lowercase) remains tmux's native full-screen zoom.

## Limitations

- tmux keeps one row for the sibling pane because a live pane cannot be resized to zero height.
- Requires at least two panes stacked vertically in the same column.
