# MS Minimap Menu 1.0.12 validation

## Source and compatibility

- Parsed the bootstrap, core, capture bridge, configuration UI, and early-capture helper with a Lua compiler.
- Confirmed `## Interface: 11200` and version 1.0.12 in both active TOCs.
- Confirmed the required load order: bootstrap, core, capture bridge, UI.
- Confirmed the required `!MSMinimapMenuCapture` dependency.
- Confirmed no new recurring scan, `UIParent` traversal, or full interface enumeration was added.
- Confirmed primary and legacy slash-command registrations remain unchanged.

## World-map scope regression tests

The mocked WoW 1.12.1 frame tests verified that:

- A named `WorldMapPOIFrame*` is rejected.
- An anonymous clickable frame beneath `WorldMapFrame` is rejected.
- A generic clickable child of `WorldMapDetailFrame` is rejected.
- A reparented frame carrying `mapPOI`/`poiID` metadata is rejected.
- Membership in `pfMinimapButtons` cannot bypass the world-map gate.
- An anchor to a `WorldMap*` object is not treated as minimap evidence.
- A real anchor to `Minimap` remains valid.
- The stock `MiniMapWorldMapButton` remains accepted.
- Atlas-CFM remains accepted even when its texture path is `Interface\WorldMap\WorldMap-Icon`.
- Early capture filters named and anonymous world-map descendants before registry insertion.
- Cached accepted candidates are revalidated and evicted when they resolve to world-map content.
- Separate world-map rejection diagnostics increase as expected.

## Archive checks

- Clean ZIP contains exactly `MSMinimapMenu` and `!MSMinimapMenuCapture` as top-level addon folders.
- Update ZIP additionally contains only the small legacy migration and capture-retirement stubs.
- Source ZIP contains the GitHub-ready repository tree without `.git` metadata or nested release archives.
- All ZIP entries pass CRC verification.
- No double-nested addon folders are present.

## Live-client status

The reported world-map POI bug was observed in the live client on version 1.0.11. Version 1.0.12 was validated with source analysis, Lua compilation, archive inspection, and mocked frame/capture tests; it has not yet been executed in the live client.
