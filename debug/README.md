# Debug Controller

An extensible debug input controller for time-scaling and custom game cheats.

## Usage
1. Add `debug_controller.gd` as an Autoload (e.g., named `DebugController`).
2. Press `speed` action to fast-forward time.
3. Press `restart` to reload the scene.
4. From any game script, register custom cheats:
   ```gdscript
   DebugController.register_action("cash", _add_cash)
   ```
