# MafMenu

MafMenu is a World of Warcraft private-server addon for fast access to the Book of Maf services, server toggles, gear stats, and watched currencies.

## Compatibility
- Loads through `xml.xml`, which includes `Settings_frame.lua` and `2panel.lua`.
- Uses saved variables:
  - `MafMenu_SavedVars`
  - `MafMenu_CharVars`
## Current Features
- Temporary fizzle/error sound suppression around menu actions.
- Favorites section for commonly used Book services.
- Per-button visibility controls.
- Separate movable/resizable currency watcher frame.
- Per-currency show/hide controls.
- Expand/collapse controls for the main menu and currency watcher.
- Mouse resize for menu width and row density.
- Persistent frame layout, collapsed state, favorites, hidden buttons, and currency choices.
- Expressway font support through `Fonts/expressway.ttf`, with WoW font fallback if missing.


## Installing

Place the folder at:

```text
Interface\AddOns\MafMenu
```

Then reload or restart the client.

## Font

The addon looks for:

```text
Interface\AddOns\MafMenu\Fonts\Expressway.ttf
```

The repository includes the local `Fonts/expressway.ttf` file if you choose to commit it. If the font is absent, the addon falls back to `Fonts\FRIZQT__.TTF`.

## Credits

- Original Playerbots/MafMenu author/editor credit: **#Likon69**
