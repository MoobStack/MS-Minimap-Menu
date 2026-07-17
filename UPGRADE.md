# Upgrading to MS Minimap Menu 1.0.11

1. Completely exit World of Warcraft.
2. Delete the former full-code folders:

   ```text
   Interface\AddOns\OctoMinimapMenu
   Interface\AddOns\!OctoMinimapMenuCapture
   ```

3. Extract `MoobStack-MSMinimapMenu-v1.0.11-Update.zip` into `Interface\AddOns`.
4. Confirm these sibling folders exist:

   ```text
   !MSMinimapMenuCapture
   MSMinimapMenu
   OctoMinimapMenu
   ```

5. Enable **MS Minimap Menu**, **MS Minimap Menu Capture**, and **MS Minimap Menu Legacy Migration**.
6. Log in and run:

   ```text
   /msminimap status
   ```

7. Verify that the saved-data line reports `legacy settings imported this session` or `legacy migration complete`.
8. Verify launcher position, appearance, custom names, and exclusions.
9. Exit normally to save `MSMinimapMenuDB`.
10. Verify the settings on a later login, then remove the temporary `OctoMinimapMenu` migration bridge if desired.

The old `OctoMinimapMenuDB` data is never erased automatically.
