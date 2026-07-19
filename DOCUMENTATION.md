# MS Minimap Menu 1.0.12 Documentation


### Overview

MS Minimap Menu was designed as a functional extension to **pfUI's minimap interface**. It adds a cleaner way to access minimap launcher buttons without replacing the minimap itself or modifying map content.

The addon:

- Removes accepted launcher buttons from around the minimap.
- Places one entry per launcher into an alphabetical list.
- Displays the original icon and a readable name when available.
- Forwards the selected row to the original addon's click or mouse handler.
- Restores original buttons when collection is disabled or a scan fails.
- Leaves quest pins, gathering nodes, tracking dots, the player arrow, pings, buffs, debuffs, action buttons, and unrelated interface controls in their original locations.

pfUI is not a hard dependency. When pfUI is present, MS Minimap Menu can use its active font, border, and background styling and can replace pfUI's existing addon-button collector with the list interface.

### Main features

- One movable **bar** or **icon** launcher.
- Left-click launcher action to open or close the list.
- Right-click launcher action to open configuration.
- Alphabetical sorting by display name.
- One button per row with optional source icons.
- Per-button inclusion or exclusion.
- Per-button custom display names.
- Configurable launcher text, width, scale, opacity, and lock state.
- Configurable menu width, row height, visible row count, and font size.
- Optional display of currently unavailable or conditional buttons.
- Optional automatic closing after selecting a row.
- Runtime pfUI theme synchronization.
- Suppression of pfUI and supported third-party minimap-button collectors.
- Event-driven discovery for addons loaded after login.
- Manual lightweight rescan and manual one-time deep scan.
- Strict minimap-only scope filtering.
- Fail-open restoration if a scan returns no usable entries or encounters an error.
- Early command bootstrap for startup diagnostics.
- Account-wide saved settings.

### Required companion addon

MS Minimap Menu requires this sibling addon folder:

```text
!MSMinimapMenuCapture
```

The capture companion loads before ordinary addons and records references to addon-created clickable frames. It does not hide, move, click, or recursively scan those frames while addons are loading. The main addon later applies strict minimap-only checks before accepting any candidate.

Both folders must be directly inside `Interface\AddOns`:

```text
World of Warcraft\Interface\AddOns\MSMinimapMenu\
World of Warcraft\Interface\AddOns\!MSMinimapMenuCapture\
```

### Discovery and safety model

Normal discovery is event-driven. It runs:

- Once after an eight-second login safety delay.
- After another addon loads.
- After relevant mail, tracking, and battleground events.
- When a likely late minimap launcher is created.
- When the user presses **RESCAN** or enters `/msminimap scan`.

The addon does **not** run recurring global-table scans. The manual deep scan is never automatic.

The scanner uses several forms of evidence before accepting a frame:

- Membership in a recognized minimap-button collector.
- A genuine minimap parent or anchor.
- A strong minimap-specific frame identity.
- A recognized stock or addon launcher name.
- Narrowly constrained addon ownership, icon, tooltip, or drag evidence near the minimap perimeter.

Before acceptance, parent lineage and frame names are checked to reject ordinary UI widgets, including buffs, debuffs, aura buttons, action buttons, bags, spell buttons, unit frames, raid frames, and map-content nodes.

Version 1.0.12 adds a separate, non-bypassable world-map-content gate. A frame is rejected before any positive launcher evidence is considered when its current or original parent chain belongs to the full world-map interface, its name identifies a `WorldMap*` object, or it exposes POI metadata. This rule also applies to frames already inside a minimap-button collector.

### Built-in and addon compatibility

The list supports common stock controls such as:

- Clock / Calendar
- World Map
- Zoom In
- Zoom Out
- Toggle Minimap
- Tracking
- New Mail
- Battleground status

Direct compatibility paths are included for:

- Looking For Turtles
- pfQuest
- Atlas-CFM
- Flight Tracker

For pfQuest, the actual launcher is collected while clickable quest markers such as `pfMiniMapPin*` remain on the minimap and are never added to the button list.

The stock **World Map** button listed above is the legitimate minimap control that opens the map. POIs, quest markers, zone buttons, overlays, notes, and all other controls belonging to the full world-map interface are never collected. Atlas-CFM remains supported even though its icon texture is stored under an `Interface\WorldMap` texture path, because texture paths are not used as world-map ownership evidence.

Most other addons work through their original `OnClick`, `OnMouseDown`, and `OnMouseUp` handlers. An unusual launcher may require a manual rescan, deep scan, custom display name, or a future compatibility rule.

---

### Updating from MS Minimap Menu 1.0.11

No saved-variable migration is required. The internal addon names and `MSMinimapMenuDB` remain unchanged.

1. Completely exit World of Warcraft.
2. Replace both current addon folders with the folders from the 1.0.12 Clean archive:

   ```text
   Interface\AddOns\MSMinimapMenu\
   Interface\AddOns\!MSMinimapMenuCapture\
   ```

3. Do not delete `MSMinimapMenuDB` or the `WTF` directory.
4. Log in, allow the normal safety-delayed scan to complete, and run:

   ```text
   /msminimap scan
   /msminimap status
   ```

5. Any world-map POI that an earlier session had hidden is restored automatically when the new scan omits it.

---

### Clean installation

1. Completely exit World of Warcraft.
2. Extract the clean release directly into:

   ```text
   World of Warcraft\Interface\AddOns\
   ```

3. Confirm both files exist:

   ```text
   World of Warcraft\Interface\AddOns\MSMinimapMenu\MSMinimapMenu.toc
   World of Warcraft\Interface\AddOns\!MSMinimapMenuCapture\!MSMinimapMenuCapture.toc
   ```

4. Enable both AddOns-screen entries:

   ```text
   MS Minimap Menu
   MS Minimap Menu Capture
   ```

5. Log in and allow approximately eight seconds for the initial scan.
6. Verify the installation:

   ```text
   /msminimap status
   /msminimap list
   ```

Avoid double-nested folders:

```text
Incorrect:
Interface\AddOns\MSMinimapMenu\MSMinimapMenu\MSMinimapMenu.toc
```

### Updating from OctoMinimapMenu 1.0.10

Use the settings-preserving update archive. It contains three sibling folders:

```text
!MSMinimapMenuCapture\
MSMinimapMenu\
OctoMinimapMenu\
```

The temporary `OctoMinimapMenu` folder is only a saved-variable migration bridge. It loads `OctoMinimapMenuDB` before MS Minimap Menu initializes. It does not run the previous minimap collector.

1. Completely exit World of Warcraft.
2. Delete the old addon-code folders:

   ```text
   Interface\AddOns\OctoMinimapMenu
   Interface\AddOns\!OctoMinimapMenuCapture
   ```

   This does not delete settings stored under the `WTF` directory.

3. Extract the update archive directly into:

   ```text
   World of Warcraft\Interface\AddOns\
   ```

4. Confirm these files exist:

   ```text
   Interface\AddOns\MSMinimapMenu\MSMinimapMenu.toc
   Interface\AddOns\!MSMinimapMenuCapture\!MSMinimapMenuCapture.toc
   Interface\AddOns\OctoMinimapMenu\OctoMinimapMenu.toc
   ```

5. Enable all three AddOns-screen entries:

   ```text
   MS Minimap Menu
   MS Minimap Menu Capture
   MS Minimap Menu Legacy Migration
   ```

6. Log in and enter:

   ```text
   /msminimap status
   ```

7. Confirm the saved-data line reports either:

   ```text
   Saved data: legacy settings imported this session
   ```

   or:

   ```text
   Saved data: legacy migration complete
   ```

8. Confirm launcher position, appearance, custom row names, and exclusions are preserved.
9. Exit the client normally so `MSMinimapMenuDB` is written.
10. Log in once more and verify the settings.
11. The temporary `OctoMinimapMenu` migration folder may then be disabled or removed.

The migration never erases or modifies `OctoMinimapMenuDB`.

### Initial setup

After the initial safety delay, a launcher labeled `ADDONS` appears near the upper-right portion of the screen.

- **Left-click** the launcher to open or close the alphabetical list.
- **Right-click** the launcher to open configuration.

To move it:

```text
/msminimap unlock
```

Drag it with the left mouse button, then lock it:

```text
/msminimap lock
```

To center it:

```text
/msminimap center
```

### Configuration

Open configuration with:

```text
/msminimap config
```

#### Appearance page

The Appearance page controls:

- Bar or icon launcher style.
- Custom bar text, up to 18 characters.
- Launcher lock state.
- Launcher scale from `0.50` to `2.00`.
- Launcher opacity from `15%` to `100%`.
- Bar width from `50` to `240` pixels.
- Menu width from `150` to `420` pixels.
- Row height from `18` to `44` pixels.
- Visible rows from `4` to `24`.
- Menu font size from `8` to `18`.
- Source-icon visibility.
- Display of currently unavailable buttons.
- Automatic menu closing after activation.
- Active pfUI colors and font.
- Suppression of pfUI and supported third-party collectors.

Action buttons provide **Open List**, **Rescan**, **Center**, **Enable/Disable**, and **Defaults**.

#### Buttons page

The Buttons page allows the user to:

- Review detected launchers alphabetically.
- Include or exclude individual entries.
- Restore an excluded button to its original minimap position.
- Assign a custom display name.
- Reset a custom name.
- Include every detected button again.
- Run a lightweight rescan.

Resetting general appearance preserves custom names and exclusions. Use **Include All** to clear exclusions.

---

### Commands

All subcommands work with any primary or legacy alias.

#### Primary aliases

```text
/msminimap
/msmm
/msminimapmenu
```

#### Legacy aliases

```text
/omm
/octominimap
/octomapmenu
```

#### Menu and configuration

| Command | Description |
|---|---|
| `/msminimap` | Open or close the alphabetical button list. |
| `/msminimap toggle` | Alias for opening or closing the list. |
| `/msminimap menu` | Alias for opening or closing the list. |
| `/msminimap config` | Open or close configuration. |
| `/msminimap options` | Alias for configuration. |
| `/msminimap settings` | Alias for configuration. |

#### Scanning

| Command | Description |
|---|---|
| `/msminimap scan` | Perform a lightweight refresh of captured minimap launchers. |
| `/msminimap refresh` | Alias for the lightweight scan. |
| `/msminimap deep` | Perform a manual one-time global-name scan; it may briefly pause on large addon installations. |
| `/msminimap fullscan` | Alias for the manual deep scan. |

#### Position and state

| Command | Description |
|---|---|
| `/msminimap lock` | Lock the launcher position. |
| `/msminimap unlock` | Unlock the launcher for dragging. |
| `/msminimap move` | Alias for unlocking the launcher. |
| `/msminimap center` | Center and unlock the launcher. |
| `/msminimap enable` | Enable collection and suppress accepted original launchers. |
| `/msminimap show` | Alias for enabling collection. |
| `/msminimap disable` | Disable collection and restore original minimap launchers. |
| `/msminimap restore` | Alias for disabling collection. |

#### Lists, diagnostics, and reset

| Command | Description |
|---|---|
| `/msminimap list` | Print every detected entry and internal frame key. |
| `/msminimap buttons` | Alias for the detected list. |
| `/msminimap status` | Print version, migration, scanner, capture, collector, icon, rejection, and performance diagnostics. |
| `/msminimap bootstrap` | Print early command-bootstrap and core load state. |
| `/msminimap loadstatus` | Alias for bootstrap diagnostics. |
| `/msminimap reset` | Reset appearance and launcher position while preserving custom names and exclusions. |
| `/msminimap help` | Print command help. |

### Saved variables and migration

The new account-wide saved-variable database is:

```text
MSMinimapMenuDB
```

It stores:

- Enabled state.
- Launcher position and lock state.
- Launcher style, text, size, scale, and opacity.
- Menu dimensions and font size.
- Icon, availability, and auto-close preferences.
- pfUI theme and collector-suppression preferences.
- Per-button custom names.
- Per-button exclusions.
- One-time migration status.

The update package copies:

```text
OctoMinimapMenuDB
    → MSMinimapMenuDB
```

Existing MS-prefixed values take precedence. Missing legacy values are imported through a deep copy. The former database remains intact.

After migration has been verified and a backup has been made, the old account-wide saved-variable file may be removed manually:

```text
WTF\Account\<Account>\SavedVariables\OctoMinimapMenu.lua
```

### Troubleshooting

#### The addon is enabled, but commands are not recognized

Confirm both primary files exist:

```text
Interface\AddOns\MSMinimapMenu\MSMinimapMenu.toc
Interface\AddOns\!MSMinimapMenuCapture\!MSMinimapMenuCapture.toc
```

Then verify that **MS Minimap Menu** and **MS Minimap Menu Capture** are enabled.

Use the early bootstrap diagnostic:

```text
/msminimap bootstrap
```

When needed, expose the underlying Lua error:

```text
/console scriptErrors 1
/reload
```

#### The launcher says `ADDONS 0`

Wait for the eight-second initial safety delay, then run:

```text
/msminimap scan
/msminimap status
/msminimap list
```

If an unusual legacy launcher remains missing, run the manual deep scan once:

```text
/msminimap deep
```

#### An addon button remains around the minimap

Run:

```text
/msminimap scan
/msminimap list
```

The button may be excluded, outside strict minimap scope, or created only after a load-on-demand feature opens. The status output reports capture and rejection counts.

#### A row does not activate its addon

Most rows forward the original frame's click or mouse handlers. Print the internal key:

```text
/msminimap list
```

Try left-click and right-click where appropriate. A highly unusual launcher may require an addon-specific compatibility path.

#### Quest markers, world-map POIs, or unrelated UI controls appear in the list

Version 1.0.12 explicitly excludes the full world-map hierarchy as well as minimap quest and gathering nodes. First refresh the current candidate set:

```text
/msminimap scan
/msminimap status
/msminimap list
```

The status output includes separate **world-map assets rejected** and **other map content rejected** counters. To restore every collected launcher immediately while gathering diagnostics, use:

```text
/msminimap disable
```

The legitimate stock **World Map** launcher may remain in the list; content displayed inside the full world map must not.

#### Settings did not migrate

For the first migration login, confirm that the temporary bridge exists and is enabled:

```text
Interface\AddOns\OctoMinimapMenu\OctoMinimapMenu.toc
```

Then run:

```text
/msminimap status
```

Log out normally after migration so the new database is written.

### Known limitations

- Some addon buttons use unconventional anonymous frames, custom click routing, or textures that cannot be identified automatically.
- The manual deep scan may briefly pause on an installation with many globals; it is never run automatically.
- Conditional status buttons may be absent while inactive unless **Show currently unavailable buttons** is enabled.
- Two addons with their own aggressive button collectors may attempt to reparent or reveal the same launcher repeatedly. MS Minimap Menu maintains accepted hidden states, but disabling the other collector is the cleanest solution.
- Minimap pins and content nodes are intentionally excluded even when they are clickable and parented to the minimap.
- Full world-map POIs, notes, overlays, zone controls, and descendants of `WorldMap*` frames are always excluded. The stock minimap World Map launcher is the only intentional map-opening control in the list.

### Temporary legacy identifiers

The following former identifiers remain intentionally for migration and compatibility:

```text
OctoMinimapMenu
OctoMinimapMenu_CommandDispatch
OctoMinimapMenuCaptureRegistry
OctoMinimapMenuDB
/omm
/octominimap
/octomapmenu
```

The runtime table, command dispatcher, and capture registry aliases support integrations that referenced the former names. `OctoMinimapMenuDB` is read only through the update-only migration bridge. The legacy slash aliases remain available for existing macros and habits.

### License

MS Minimap Menu is distributed under the MIT License included in this repository and the release package.

### Publisher disclaimer

> MoobStack is an independent community addon publisher. These addons are not affiliated with, authorized by, or endorsed by Blizzard Entertainment or any community server project. World of Warcraft and related marks are the property of their respective owners.
