# Node Array & Distribute Tool

An editor utility integrated into Godot's 3D and 2D viewport toolbars for quickly cloning node hierarchies and distributing object selections with precise center-to-center spacing.

## Features

- **Live Viewport Preview**: Shows real-time bounding box wireframes and span vectors in the 3D or 2D viewport before committing changes.
- **Full Node Tree Duplication**: When duplicating a single node or parent group, recursively clones the entire descendant tree and sets proper scene root ownership so all nodes are saved and visible in the Scene Tree dock.
- **Multi-Node Distribution**: When selecting multiple nodes, sorts them along the chosen axis and distributes them sequentially from the anchor position.
- **Context-Aware (3D & 2D)**:
  - **3D Viewport**: Uses the `VisualInstance3D` icon, supports $+X, -X, +Y, -Y, +Z, -Z$ axes, and measures in meters (`m`).
  - **2D Viewport**: Uses the `CanvasItem` icon, automatically hides the $Z$ axis ($+X, -X, +Y, -Y$), and measures in pixels (`px`).
- **Undo / Redo Integration**: All duplicate and distribute operations are fully registered with `EditorUndoRedoManager` (`Ctrl+Z` / `Ctrl+Y`).
- **DPI / Display Scale Responsive**: Automatically scales UI fonts and layouts according to the editor's display scale.

## Usage

1. Select either:
   - **One node** to duplicate into an array of $N$ copies.
   - **Multiple nodes** to distribute along an axis.
2. Click the Array Tool icon in the 3D or 2D viewport top menu bar.
3. Configure the **Axis**, **Spacing**, and **Copies** (if duplicating). Observe the live bounding box preview in the viewport.
4. Click **Duplicate & Array** or **Distribute**.
