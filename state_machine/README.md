# State Machine

A Node-based state machine that dynamically registers its children as states.

## Usage
1. Add a `StateMachine` node to your scene.
2. Add `State` nodes (or scripts extending `State`) as children.
3. Override `enter()`, `exit()`, `state_process()`, etc., in your state scripts.
4. Call `Transitioned.emit("StateName")` from inside a state to switch states.
