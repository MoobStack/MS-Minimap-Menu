# MS Minimap Menu v1.0.12

MS Minimap Menu 1.0.12 is a scope-safety hotfix that prevents clickable world-map POIs and other full world-map assets from being scanned, hidden, or exposed as launcher rows.

## Changes

- Added a hard rejection gate for `WorldMap*` frames, descendants of the full world-map hierarchy, and frames carrying world-map POI metadata.
- Applies the gate before collector membership, original-parent evidence, minimap position, icon, tooltip, drag behavior, or generic `MapButton` naming can accept a frame.
- Updated the required early-capture companion to filter world-map descendants before registry insertion.
- Revalidates cached early-capture candidates on each scan, removing candidates that later resolve to world-map content.
- Purges stale world-map objects from the manual global-name registry.
- Restores any formerly hidden world-map frame when it is absent from the new scan.
- Adds separate world-map rejection counters to `/msminimap status`.
- Keeps the legitimate stock World Map minimap launcher.
- Keeps Atlas-CFM support even though its icon texture resides under `Interface\WorldMap`; texture paths alone are not treated as hierarchy evidence.
- Preserves all existing settings and commands.

## Installation

1. Completely exit World of Warcraft.
2. Extract the Clean ZIP directly into `World of Warcraft\Interface\AddOns\`.
3. Replace both existing folders when prompted.
4. Confirm:

   ```text
   Interface\AddOns\MSMinimapMenu\MSMinimapMenu.toc
   Interface\AddOns\!MSMinimapMenuCapture\!MSMinimapMenuCapture.toc
   ```

5. Enable **MS Minimap Menu** and **MS Minimap Menu Capture**.
6. Log in and run `/msminimap scan` followed by `/msminimap status`.

## Updating from 1.0.11

The Clean asset is also the normal 1.0.11 update. No saved-variable migration is required, and `MSMinimapMenuDB` must be retained.

The Update asset additionally contains the temporary legacy migration and retired-capture stubs for users moving directly from the former OctoMinimapMenu branding.

## Verification

The legitimate stock **World Map** row may appear. No POI, note, overlay, zone button, quest marker, or other asset belonging to the full world-map window should appear.

Useful diagnostics:

```text
/msminimap scan
/msminimap status
/msminimap list
```

## Compatibility

Designed for the World of Warcraft 1.12.1 client using Interface 11200. Compatibility may vary across community-maintained client modifications.

## Downloads

- `MoobStack-MSMinimapMenu-v1.0.12-Clean.zip` — clean installation and normal update from 1.0.11.
- `MoobStack-MSMinimapMenu-v1.0.12-Update.zip` — active addons plus legacy migration/retirement stubs.
- `MoobStack-MSMinimapMenu-v1.0.12-Source.zip` — GitHub-ready repository source and documentation.
