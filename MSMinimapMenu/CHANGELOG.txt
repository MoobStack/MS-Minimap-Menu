# Changelog

## 1.0.12

- Fixed a bug that could classify clickable world-map POIs and other full world-map assets as minimap launcher buttons.
- Added a hard world-map scope gate before collector, frame-name, original-parent, position, icon, tooltip, or drag evidence can accept a candidate.
- Rejects current and original parent chains under `WorldMapFrame`, `WorldMapDetailFrame`, and other `WorldMap*` objects.
- Rejects named, anonymous, and reparented frames carrying world-map POI metadata.
- Updated `!MSMinimapMenuCapture` to discard world-map descendants before registry insertion.
- Revalidates cached early-capture candidates and removes any candidate that later resolves to world-map content.
- Purges stale world-map frames from the manual global-name registry and restores formerly hidden frames on the next scan.
- Added separate world-map rejection diagnostics to `/msminimap status`.
- Preserved the legitimate stock World Map minimap launcher and Atlas-CFM compatibility.
- Preserved all settings, custom names, exclusions, event-driven discovery, strict minimap-only filtering, and pfUI integration.

## 1.0.11

- Rebranded **OctoMinimapMenu** as **MS Minimap Menu** under the MoobStack publisher.
- Renamed the main addon folder, required early-capture companion, TOC files, Lua source files, addon namespace, frame names, saved-variable database, UI branding, messages, and documentation to MS-prefixed names.
- Added `/msminimap`, `/msmm`, and `/msminimapmenu` as the primary slash-command aliases.
- Retained `/omm`, `/octominimap`, and `/octomapmenu` as legacy aliases for existing macros and habits.
- Added settings-preserving migration from `OctoMinimapMenuDB` to `MSMinimapMenuDB`.
- Renamed the required capture companion to `!MSMinimapMenuCapture`.
- Added early command-bootstrap diagnostics.
- Preserved direct compatibility for Looking For Turtles, pfQuest, Atlas-CFM, and Flight Tracker.

## Legacy history

Versions **1.0.0 through 1.0.10** were published under the **OctoMinimapMenu** name.

- **1.0.10** fixed the Buttons-page rename editor on clients whose `EditBox` exposed `Disable()` without a matching `Enable()` method.
- **1.0.9** added exact pfQuest, Atlas-CFM, and Flight Tracker launcher handling while excluding pfQuest map pins.
- **1.0.8** replaced recurring scans with event-driven discovery and added direct Looking For Turtles activation.
- **1.0.7** introduced strict minimap-only scope filtering.
- **1.0.5–1.0.6** added early addon-button capture, anonymous launcher support, and safer icon handling.
- **1.0.0–1.0.4** established the movable launcher, alphabetical list, pfUI theming, collector suppression, and crash-safe discovery model.
