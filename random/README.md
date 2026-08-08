# Random Utilities

A wrapper for `RandomNumberGenerator` to enforce a global, seedable RNG source for deterministic features.

## Usage
Add `rng.gd` as an Autoload (e.g., named `RNG`).

```gdscript
var value = RNG.randf_range(0, 10)
```
