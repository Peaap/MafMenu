# Changelog

## 2.1.0

### Changed

- Started the Ace3 redesign by embedding WotLK-compatible Ace3 core libraries under `Libs/`.
- Added `Core.lua` as the AceAddon bootstrap and moved `/mafmenu` and `/mafcurrencies` registration to AceConsole.
- Converted profile storage to AceDB-backed Global and Character profiles.
- Preserved legacy flat saved-variable settings through a one-time migration into the new AceDB Global profile.
- Split the legacy `2panel.lua` implementation into focused Ace3-era modules and replaced it with `Main.lua`.
- Replaced the custom config window with an AceConfigDialog options UI.
- Added MafMenu profile controls for existing profiles, copy-from, delete, reset, and new profile workflows.
- Moved Playerbots controls to the local `codex/playerbots-wip` branch for further iteration.
- Removed the legacy hidden bot farming settings frame from the main load path.
- Removed the unused AceDBOptions embed from the main branch.
- Added config sections for panel visibility/lock/size, currency watcher filters and layout, service groups, behavior, and appearance.
- Expanded the General config page into a dashboard with profile/menu/currency status, common toggles, and quick reset/probe actions.
- Added an About/Credits block with addon info, maintainer credit, original author credit, and GitHub link.
- Added Ace3-style skin helpers for shared panel, header, button, hover, and status styling.
- Added main-menu row favorite pins, per-section collapse headers, title-bar lock/config controls, and icon/text display modes.
- Improved the currency watcher with non-zero-first sorting, category headers, watched pins, dimmed zero values, and a visible summary footer.

### Fixed

- Added direct profile creation, selection, copy, delete, and reset controls so profile changes persist reliably through the MafMenu config window.
- Changed new/default profile selection to start on the current character profile instead of the shared Global profile.
- Aligned profile selection persistence with ElvUI's AceDB pattern by relying on AceDB `profileKeys` for created or selected profiles.
- Converted legacy flat saved variables into AceDB `profileKeys` and `profiles` before opening the database.
- Delayed profile initialization until `ADDON_LOADED` so AceDB sees the real SavedVariables table.

## 2.0.4

### Added

- Added a Config menu settings-scope toggle for Global or Character profiles.
- Character profiles now keep separate layout, collapse state, favorites, hidden services, currency watcher state, and hidden currency choices.

### Changed

- Started modularizing addon internals with `Modules/Profile.lua` for saved-variable profile handling.

## 2.0.3

### Fixed

- Closed Book gossip through the WotLK client close path instead of directly hiding `GossipFrame`, preventing Escape-key UI state from getting stuck after opening services such as Bank.
- Cleared pending Book service selections when gossip closes or times out.
- Updated the addon TOC interface to `30300` for WoW 3.3.5a compatibility.

## 2.0.2

### Fixed

- Added a defensive guard for invalid global `UIFrameFlash` entries that can be created by other addons and trigger `UIParent.lua` errors.

## 2.0.1

### Fixed

- Guarded saved frame positions so invalid layout values fall back cleanly instead of triggering UIParent comparison errors.

## 2.0.0

### Highlights

- Rebuilt the menu into a cleaner Book of Maf service list.
- Added favorites and visibility controls.
- Added a separate movable currency watcher with per-currency display controls.
- Added saved layout, resizing, and expand/collapse support.
- Added Expressway font support.

### Service Changes

- Split Legacy Vendor and Gear Stats into separate buttons.
- Improved Book service timing for more reliable menu actions.
- Reduced fizzle/error feedback while using menu buttons.

### Commands

- `/mafmenu` opens configuration.
- `/mafcurrencies` shows the currency watcher.

### Notes

- Original author/editor credit remains **#Likon69**.
