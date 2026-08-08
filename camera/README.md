# Shakable Camera

A robust, trauma-based 2D camera shake implementation using 1D noise for smooth, natural movement.

## Usage
1. Replace your `Camera2D` script with `shakable_camera.gd`.
2. To trigger a shake, call `add_trauma(amount)` where amount is usually between 0.1 and 1.0.
   ```gdscript
   camera.add_trauma(0.5)
   ```
Trauma squares itself, meaning multiple small hits will stack naturally into a large shake.
