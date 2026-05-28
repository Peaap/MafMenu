# Changelog

## Unreleased

### Added

- Config frame for favorites, hidden buttons, currency watcher visibility, and per-currency visibility.
- Separate currency watcher frame with saved position, row density, width, and collapsed state.
- Expand/collapse buttons for the main menu and currency watcher.
- Mouse resize behavior for main menu and currency watcher.
- Expressway font support through `Fonts/Expressway.ttf` or `Fonts/expressway.ttf` on Windows.
- `/mafcurrencies` command to force-show the currency watcher.
- `/mafmenu` command to open configuration.
- `/mafdebug` and `/mafprobe` helpers for Book/gossip and command investigation.

### Changed

- Reworked the main menu from a compact grid into a vertical Book of Maf service list.
- Split Legacy Vendor and Gear Stats into separate controls.
- Changed Book service actions to use the Book item and delayed gossip selection.
- Moved currencies out of the main menu into their own frame.
- Replaced generic checkbox config controls with explicit state buttons.
- Increased Book gossip timing delay to reduce failed/raced service actions.
- Temporarily suppresses fizzle/error feedback during menu actions, then restores sound settings.

### Removed

- Removed protected auto-target/interact behavior after it triggered Blizzard protected-action blocking.
- Removed embedded currency rows from the main Book services frame.

### Notes

- Original author/editor credit remains **#Likon69**.
- License is intentionally not declared until original upstream terms are confirmed.
