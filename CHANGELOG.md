# Changelog

## 1.0.11

- Rebranded **OctoMinimapMenu** as **MS Minimap Menu** under the MoobStack publisher.
- Renamed the main addon folder, required early-capture companion, TOC files, Lua source files, addon namespace, frame names, saved-variable database, UI branding, messages, and documentation to MS-prefixed names.
- Added `/msminimap`, `/msmm`, and `/msminimapmenu` as the primary slash-command aliases.
- Retained `/omm`, `/octominimap`, and `/octomapmenu` as legacy aliases for existing macros and habits.
- Added a settings-preserving migration from `OctoMinimapMenuDB` to `MSMinimapMenuDB` without deleting or modifying the former database.
- Added a minimal temporary `OctoMinimapMenu` migration bridge for update installations; the previous full addon implementation is not loaded.
- Renamed the required capture companion from `!OctoMinimapMenuCapture` to `!MSMinimapMenuCapture`.
- Added an early command bootstrap so primary and legacy commands can report load diagnostics even when the main core does not complete initialization.
- Updated public compatibility wording to World of Warcraft 1.12.1 and Interface 11200 without tying the addon to a particular community server.
- Preserved the strict minimap-only scope filters, pfUI-aware styling, event-driven discovery, manual deep scan, alphabetical list, per-button names and exclusions, original-button restoration, and addon-specific activation behavior from version 1.0.10.
- Preserved direct compatibility for Looking For Turtles, pfQuest, Atlas-CFM, and Flight Tracker.
- Preserved the version 1.0.10 old-client configuration-field compatibility fix and the version 1.0.8 performance change that removed recurring deep scans.

## Legacy history

Versions **1.0.0 through 1.0.10** were published under the **OctoMinimapMenu** name.

- **1.0.10** fixed the Buttons-page rename editor on clients whose `EditBox` exposed `Disable()` without a matching `Enable()` method.
- **1.0.9** added exact pfQuest, Atlas-CFM, and Flight Tracker launcher handling while excluding pfQuest map pins.
- **1.0.8** replaced recurring scans with event-driven discovery and added direct Looking For Turtles activation.
- **1.0.7** introduced strict minimap-only scope filtering to prevent buffs, action buttons, and other unrelated UI controls from being collected.
- **1.0.5–1.0.6** added early addon-button capture, anonymous launcher support, and safer icon handling.
- **1.0.0–1.0.4** established the movable launcher, alphabetical list, pfUI theming, collector suppression, and crash-safe discovery model.
