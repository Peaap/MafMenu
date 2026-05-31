<img width="247" height="544" alt="image" src="https://github.com/user-attachments/assets/7f190c67-e213-4bee-b176-e87df3ab2854" />  <img width="248" height="661" alt="image" src="https://github.com/user-attachments/assets/81458cdd-3577-464a-b398-033761f30224" />  <img width="417" height="557" alt="image" src="https://github.com/user-attachments/assets/b2771d85-0535-4bd3-b9d5-bffb8b6f2772" />







# MafMenu

MafMenu is a World of Warcraft private-server addon for fast access to the Book of Maf services, server toggles, gear stats, Playerbots controls, profiles, layout tools, and watched currencies.

Maintained by @peaps. Original Playerbots/MafMenu work credited to #Likon69.

GitHub: https://github.com/Peaap/MafMenu

## Layout
- `Libs/` embeds the WotLK-compatible Ace3 core used by MafMenu.
- `Core.lua` creates the AceAddon object and owns AceConsole slash commands.
- `Main.lua` initializes profiles, installs guards, and starts the panel.
- `Modules/Profile.lua` owns saved-variable profile scope and normalization.
- `Modules/Config.lua` registers the AceConfig options UI and AceDB profile manager.
- `Modules/Panel.lua`, `Modules/Services.lua`, `Modules/Currency.lua`, `Modules/Playerbots.lua`, and `Modules/Minimap.lua` own the visible feature areas.
- `Settings_frame.lua` keeps the legacy settings frame.

## Compatibility
- Built for the MafWoW WotLK 3.3.5a client with `## Interface: 30300`.
- Loads through `xml.xml`, which includes the embedded Ace3 libraries, modules, `Settings_frame.lua`, and `Main.lua`.
- Uses saved variables:
  - `MafMenu_SavedVars`
  - `MafMenu_CharVars`
- Uses AceDB-backed profiles with MafMenu profile management controls.
## Current Features
- Temporary fizzle/error sound suppression around menu actions.
- Book service selection closes gossip through the 3.3.5a client close path so Escape-key UI state stays clean after services such as Bank.
- Ace3-backed profile management for layouts, favorites, hidden services, and currency watcher choices.
- AceConfig options window with panel, service, Playerbots, currency, behavior, appearance, and profile controls.
- Playerbots quick controls for adding bots, party/raid commands, whisper-target commands, disperse, and custom commands.
- Ace3-style skin treatment shared by the menu, currency watcher, title bars, buttons, hover states, and status buttons.
- Main menu favorites, per-section collapse headers, lock/config title controls, and normal/text-only/icon-only display modes.
- Currency watcher sorting, category headers, watched pins, dimmed zero values, and summary footer.
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
