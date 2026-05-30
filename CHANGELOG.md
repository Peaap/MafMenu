# Changelog

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
