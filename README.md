# tmux-half-screen

Regional column zoom for tmux — expand a stacked pane within its left or right column without affecting the opposite side. Press the binding again to restore the exact previous layout.

Halfway between a 50/50 split and full-screen zoom (`prefix + z`).

## Visual

```
Before                              After (prefix + Z)
┌───────────────┬───────────────┐   ┌───────────────┬───────────────┐
│               │ right-top     │   │               │               │
│ left          ├───────────────┤   │ left          │ focused right │
│               │ right-bottom  │   │               │ (maximized)   │
└───────────────┴───────────────┘   └───────────────┴───────────────┘
                                        unchanged      expanded to
                                                       full height
```

Works on either side:

```
┌───────────────┬───────────────┐   ┌───────────────┬───────────────┐
│ left-top      │               │   │               │               │
├───────────────┤ right          │   │ focused left  │ right          │
│ left-bottom   │               │   │ (maximized)   │               │
└───────────────┴───────────────┘   └───────────────┴───────────────┘
```

## Requirements

- tmux ≥ 3.0
- bash

## Installation

### TPM

```tmux
set -g @plugin 'donnyaw/tmux-half-screen'
```

Press `prefix + I` to install.

### Manual

```bash
git clone https://github.com/donnyaw/tmux-half-screen ~/.tmux/plugins/tmux-half-screen
```

Add to `.tmux.conf`:

```tmux
bind Z run-shell -b "~/.tmux/plugins/tmux-half-screen/half-screen-toggle.sh '#{pane_id}'"
```

Reload:

```bash
tmux source-file ~/.tmux.conf
```

## Configuration

### Key binding

The recommended binding is `prefix + Z`:

```tmux
bind Z run-shell -b "~/.tmux/plugins/tmux-half-screen/half-screen-toggle.sh '#{pane_id}'"
```

Alternative binding options:

| Binding | Command |
|---------|---------|
| `prefix + Z` | Recommended — uppercase `Z` complements `prefix + z` fullscreen zoom |
| `prefix + M-z` | Alt+z variant if uppercase interferes with your terminal |
| `prefix + v` | Short mnemonic for vertical |

### Avoid conflicts

If you use `Alt+z` as a no-prefix binding (e.g. `bind -n M-z resize-pane -Z`), unbind it first:

```tmux
unbind -T root M-z
bind Z run-shell -b "~/.tmux/plugins/tmux-half-screen/half-screen-toggle.sh '#{pane_id}'"
```

Without unbinding, pressing `Alt+z` after the prefix may fire the full-screen zoom instead.

## Usage

1. Create a layout with a split column — one full-height pane on one side and two stacked panes on the other.
2. Focus the pane you want to expand.
3. Press `prefix + Z` (or your configured key).
4. The pane fills its column. The opposite side stays untouched.
5. Press the binding again to restore the exact layout.

### How to create the target layout

```
# Start with one pane
tmux split-window -h        # left/right split

# Focus the right pane, then stack
tmux select-pane -t :.+
tmux split-window -v        # right side now has top/bottom split
```

### What qualifies as "stacked"

The script detects stacked panes by matching their `pane_left` and `pane_width` values. Two panes are considered stacked when they share the same horizontal position and width — meaning they are siblings in a vertical arrangement within the same column. This works whether the column is on the left or right side of the window.

Example with three panes where the right column is split vertically:

```
Pane A (left):   pane_left=0   pane_width=75
Pane C (right-top):    pane_left=76  pane_width=74
Pane D (right-bottom): pane_left=76  pane_width=74
```

Panels C and D share `pane_left=76` and `pane_width=74`, so they are recognized as stacked. Focusing either one and pressing `prefix + Z` expands it within the right column.

## How it works

1. The script must be invoked via `tmux run-shell` with `#{pane_id}` as the argument. The key binding uses `run-shell -b` which executes the script inside the tmux session, making `$TMUX` available so bare `tmux` commands resolve to the correct server socket. Calling the script directly from a shell prompt will fail because no `$TMUX` socket context exists.

2. On first activation, the script saves the window's full layout string to a tmux window option (`@half_screen_saved_layout`) along with the current set of pane IDs (`@half_screen_saved_panes`).

3. It identifies whether the focused pane has a stacked sibling by comparing `pane_left` and `pane_width` across all panes in the window.

4. If a stacked sibling exists, it runs `tmux resize-pane -y 9999` to give the focused pane as much height as possible. tmux keeps one row for the sibling since a live pane cannot be hidden.

5. On the next activation, it restores the saved layout exactly — not a best-effort approximation.

### State invalidation

If panes are added, removed, or moved between activations, the saved layout becomes stale. The script detects this by comparing the current pane set against the saved set. If they differ, the stale state is silently discarded and the script proceeds to save the current layout fresh.

## Limitations

| Limitation | Explanation |
|------------|-------------|
| One-row sibling | tmux cannot resize a live pane to zero height. The sibling is retained as a single row or column. |
| Requires stacked sibling | The script exits with a message if the focused pane has no vertical sibling in its column. |
| Per-window state | Saved layouts are stored per tmux window, not per session. Different windows with the same binding work independently. |
| 2-pane minimum | At least two panes must exist in the window. |

## Comparison with built-in tmux zoom

| Feature | `prefix + z` | `prefix + Z` (this plugin) |
|---------|-------------|---------------------------|
| Scope | Full window | Single column |
| Opposite panes | Fully hidden | Remain visible |
| Restore | Same key | Same key |
| Use case | Focus on one task | Compare two files side by column |

## Troubleshooting

### Nothing happens when I press the binding

- Verify the key is registered: `tmux list-keys -T prefix Z`
- Ensure the script path is correct: `ls -la ~/.tmux/plugins/tmux-half-screen/half-screen-toggle.sh`
- Reload tmux config: `tmux source-file ~/.tmux.conf`

### It triggers full-screen zoom instead

You have a conflicting `Alt+z` or `M-z` binding. Add `unbind -T root M-z` before the `bind Z` line in `.tmux.conf` and reload.

### The first pane disappeared after restore

The saved layout became stale because panes changed between activations. The script automatically detects this and clears the stale state. Press the binding again to save the current layout fresh.

### Status line shows no output

The half-screen toggle does not modify the tmux status line. If you want a status indicator for hidden panes, use `tmux-hidden-panes`:

```tmux
set -g status-right '"#{=21:pane_title}#(~/.tmux/plugins/tmux-hidden-panes/scripts/hidden-count.sh)"'
```

## Related projects

- [tmux-hidden-panes](https://github.com/donnyaw/tmux-hidden-panes) — hide and restore individual panes with persistence and Resurrect integration
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — persist tmux sessions across restarts
