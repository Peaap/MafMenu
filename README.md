# MafMenu

MafMenu is a World of Warcraft private-server addon for fast access to the Book of Maf services, server toggles, gear stats, and watched currencies.

This project is based on earlier Playerbots/MafMenu work by **#Likon69**. The current fork keeps that credit in the addon metadata and documents the rewrite work below.

## Compatibility

- Target client: WotLK-style private client using the `50400` addon interface declared by the existing addon.
- Loads through `xml.xml`, which includes `Settings_frame.lua` and `2panel.lua`.
- Uses saved variables:
  - `MafMenu_SavedVars`
  - `MafMenu_CharVars`

## Current Features

- Book of Maf shortcut menu using secure macro buttons.
- Delayed gossip selection to avoid racing `GOSSIP_SHOW`.
- Temporary fizzle/error sound suppression around menu actions.
- Favorites section for commonly used Book services.
- Per-button visibility controls.
- Separate movable/resizable currency watcher frame.
- Per-currency show/hide controls.
- Expand/collapse controls for the main menu and currency watcher.
- Mouse resize for menu width and row density.
- Persistent frame layout, collapsed state, favorites, hidden buttons, and currency choices.
- Expressway font support through `Fonts/expressway.ttf`, with WoW font fallback if missing.
- Command probe/debug helpers:
  - `/mafdebug`
  - `/mafprobe`
  - `/mafmenu`
  - `/mafcurrencies`

## Original To Current Changes

The original addon was a compact button panel. This fork changes it into a configurable Book of Maf interface:

- Replaced cramped multi-column buttons with a vertical service list.
- Added Book gossip automation for Vendor, Reset Combat, Bank, Auction House, Reset Instances, Teleporter, Reagent Bank, Buff Me, Trainer, Item Collector, and Legacy Vendor.
- Split Legacy Vendor from Gear Stats so the vendor opens the Book option and stats uses `.gear stats`.
- Added direct server command buttons for `.aoeloot on`, `.aoeloot off`, `.mythic enable`, and `.mythic trash`.
- Added a config frame for favorites, button visibility, currency watcher visibility, and individual currency visibility.
- Added a separate currency watcher frame instead of embedding currencies in the main menu.
- Added persistent drag positions, sizes, row density, collapse states, and user selections.
- Added custom resize behavior that changes both width and row density without protected UI sizing calls.
- Removed protected targeting/interact experiments after WoW blocked `TargetNearestFriend()`.
- Added delayed Book gossip selection to improve reliability.
- Added temporary sound/error suppression so failed-use fizzle feedback does not spam while using the menu.
- Added Expressway font support with a bundled-font path.

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
- Current fork: MafMenu modernization and Book of Maf workflow changes.

## License

No license has been assigned yet because the original upstream licensing terms were not included in this addon folder. Do not redistribute outside your own server/community workflow until the original licensing/permission status is confirmed.
