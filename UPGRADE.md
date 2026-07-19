# Upgrading to MS Minimap Menu 1.0.12

## From MS Minimap Menu 1.0.11

1. Completely exit World of Warcraft.
2. Replace both addon folders with the folders from the Clean archive:

   ```text
   Interface\AddOns\MSMinimapMenu\
   Interface\AddOns\!MSMinimapMenuCapture\
   ```

3. Preserve `MSMinimapMenuDB` and the `WTF` directory.
4. Enable both addon entries.
5. Log in and run:

   ```text
   /msminimap scan
   /msminimap status
   ```

No migration bridge is required for a 1.0.11 update.

## Directly from OctoMinimapMenu 1.0.10

Use the 1.0.12 Update archive. It contains these four sibling folders:

```text
MSMinimapMenu
!MSMinimapMenuCapture
OctoMinimapMenu
!OctoMinimapMenuCapture
```

The former-name folders contain only a saved-variable bridge and an inert capture-retirement stub. Enable all four entries for the first migration login, verify `/msminimap status`, log out normally, and then remove the two former-name folders after the migrated settings survive another login.

## Expected result

The stock minimap World Map launcher remains valid. No world-map POI or other asset belonging to the full map interface is collected.
