# MS Minimap Menu 1.0.11 validation

## Source and compatibility

- Parsed all active Lua files and both transition-stub Lua files successfully with `luaparser`.
- Confirmed `## Interface: 11200` in every TOC.
- Confirmed the active main TOC loads the bootstrap before the core, capture bridge, and UI.
- Confirmed the main addon requires `!MSMinimapMenuCapture` and lists the optional legacy migration bridge before initialization.
- Confirmed no `string.gmatch` dependency, unsupported vararg forwarding, modern widget template, or modern timer API was introduced.
- Confirmed the existing WoW 1.12.1 compatibility guards for optional frame methods and unsupported scripts remain present.

## Branding and identifiers

- Confirmed display name: **MS Minimap Menu**.
- Confirmed internal name: `MSMinimapMenu`.
- Confirmed version: `1.0.11`.
- Confirmed author and publisher: MoobStack.
- Confirmed active saved variable: `MSMinimapMenuDB`.
- Confirmed active companion: `!MSMinimapMenuCapture`.
- Confirmed MS-prefixed Lua files, globals, frames, UI titles, and chat prefix.
- Confirmed former branding remains only for migration, runtime aliases, legacy commands, owner filtering, and changelog history.

## Mocked runtime tests

Executed the packaged Lua in a mocked frame and API environment and verified:

- Required capture helper hooks `CreateFrame` and exposes `MSMinimapMenuCaptureRegistry`.
- Former capture-registry alias points to the active registry.
- Legacy `OctoMinimapMenuDB` values are deep-copied into `MSMinimapMenuDB`.
- Former data remains unchanged.
- Launcher width, position, custom names, and exclusions survive migration.
- Migration marker is created.
- Existing MS-prefixed values take precedence while missing legacy values are merged.
- A clean installation initializes without a legacy database or migration marker.
- Existing settings reset preserves custom names, exclusions, and migration marker.
- Main namespace and former runtime alias point to the same addon table.
- `/msminimap`, `/msmm`, and legacy aliases are registered.
- Configuration window builds successfully.
- The Buttons-page editor works when an EditBox has `Disable()` but no `Enable()` method.
- Lock, unlock, and center commands execute.
- A captured addon minimap button is admitted, labeled from migrated data, and activated exactly once.
- Status and bootstrap diagnostics execute successfully.

## Documentation

- Extracted command aliases and subcommands from the actual command parser.
- Confirmed README command tables include every implemented subcommand and alias.
- Confirmed README changelog matches `CHANGELOG.md` for version 1.0.11.
- Confirmed clean and update installation paths match the release archives.
- Confirmed companion and migration requirements are documented.

## Archive validation

- Clean archive contains only `MSMinimapMenu` and `!MSMinimapMenuCapture` as top-level addon folders.
- Update archive contains the two active folders and the temporary saved-variable migration bridge.
- Clean archive contains no legacy migration bridge.
- Source archive contains repository-ready source and Markdown documentation without release ZIPs nested inside it.
- Confirmed no double-nested addon folders.
- Confirmed ZIP integrity through extraction and CRC testing.

## Verification boundary

These checks cover syntax, static WoW 1.12.1 compatibility, mocked runtime behavior, saved-data migration, documentation consistency, and archive structure. This packaging step did **not** execute the addon inside the live World of Warcraft client.
