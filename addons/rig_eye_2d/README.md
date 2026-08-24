# RigEye2D Godot Plugin

## What is this?
Tool scene for Godot Engine that helps with making moving animatable eyes in 2D. Usable in games, animations, etc.



Features:
- Tracking any Node2D position
- Tracking mouse cursor
- Tracking fixed Vector2 position
- Pairing multiple RigEye2D nodes so they track target together
- Controlling speed of movement animation
- Controlling FPS of animation to make stylized movement
- Preview movement in Godot editor
- Providing signals
- Providing API of different methods
- Simple to extend
- Simple to modify

## Supported Godot versions
- 4.7
- 4.6

## Check tutorial with examples on YouTube!
*coming soon*

## Quick Start
1. Download this plugin inside Godot Engine from Asset Store (AssetLib in 4.6), or download latest release from GitHub and place it in "addons" dir of your project
2. Enable the plugin in `Project -> Project Settings -> Plugins`
3. Make "New Inherited Scene" from rig_eye_2d.tscn in the plugin `scenes` dir
4. Set textures for Sprite2D nodes of eye parts White/Iris/Pupil, only those you require (plugin includes example AtlasTexture for all parts)
5. Enable `Process In Editor` and `Tracking -> Track Mouse` to see movement
6. Play with options to configure behaviour to your needs
7. Save as your own scene and instantiate as many instances as you require

**More info and examples in video: coming soon**

# API DOC

## Targeting priority

Each eye can resolve its own look target from one of three sources: a manual point (`look_at_point()`), a tracked Node2D (`target_path` / `set_target()`), or the mouse cursor (`track_mouse`). When several of these are active at once on the *same* eye, or across a group of paired eyes, the eye that ends up driving the whole group's movement is decided by priority:

1. **Manual point** (`look_at_point()`) - highest priority.
2. **Node target** (`target` / `set_target()`)
3. **Mouse cursor** (`track_mouse`) - lowest priority.

This matters most for paired eyes: the entire group looks at whichever active mode has the highest priority among *any* eye in the group, not just its own. For example, if `eye_a` is paired with `eye_b`, and `eye_a.track_mouse = true` while `eye_b.set_target(some_node)` is called, the whole pair will track `some_node` - the node target on `eye_b` outranks the mouse tracking on `eye_a`. If no eye in the group has an active target, they rest at center.

## Signals

### `move_started()`
Emits when an eye element starts moving away from its resting position.

### `move_finished()`
Emits when all eye elements settle and stop moving.

### `target_changed(old_target: Node2D, new_target: Node2D)`

Emits whenever the tracked `target` node changes. Useful for reacting when character switches to look on a new object.

### `tracking_changed(mode: TrackingMode)`
Emits whenever the active `TrackingMode` (`NONE`, `NODE`, `MOUSE`, `POINT`) changes.

## Methods

### `set_target(node: Node2D, property_name: StringName = &"") -> void`
Sets a `Node2D` for the eye to track, following its `global_position` or an optional custom property. If this eye is paired, the target is shared with all paired eyes.

**Arguments**
- `node` - the `Node2D` to look at.
- `property_name` - optional `Vector2` property on `node` to track instead of `global_position`.

### `look_at_point(world_position: Vector2) -> void`
Like `set_target()`, but tracks a fixed `Vector2` world position instead of a node. If this eye is paired, the point is shared with all paired eyes.

**Arguments**
- `world_position` - the world-space point to look at.

### `clear_target() -> void`
Clears the current tracking target for this eye and any paired eyes.

### `snap_to_center() -> void`
Instantly resets all eye elements to center without animating.

### `pair_eye(eye: RigEye2D) -> void`
Mutually pairs this eye with another `RigEye2D`, adding each to the other's `paired_eyes` so both track the same target and move in sync.

**Arguments**
- `eye` - the other `RigEye2D` instance to pair with.

> **Pairing 3+ eyes:** `pair_eye()` only creates a direct link between the two eyes you call it on - it does not chain through to eyes they're already paired with. For a group of 3+ eyes to move in sync, pair every eye with every other eye in the group using `pair_group()`

> Skipping pairing `eye_a` with `eye_c` can cause jittery movement, since each eye only computes the synced look target from its own `paired_eyes` list!

### `unpair_eye(eye: RigEye2D) -> void`
Mutually unpairs this eye from another `RigEye2D`, removing each from the other's `paired_eyes`.

**Arguments**
- `eye` - the previously paired `RigEye2D` instance to detach.

> **Unpairing from a group of 3+:** `unpair_eye()` only removes single link to the given `eye` - if this eye is still paired with other RigEye2D instances, it will keep moving together with them!
> If you want this eye fully detached from whole group it's in, use `clear_pairs()` instead.

### `clear_pairs() -> void`
Mutually removes this eye from all of its `paired_eyes`, fully detaching it from the group.

### `pair_group(eyes: Array[RigEye2D]) -> void`
Pairs every eye in the given list with every other eye in the list, a shortcut for manually pairing every combination in a group of 3+ eyes.

**Arguments**
- `eyes` - the other `RigEye2D` instances to pair into one group together with this eye.

### `unpair_group(eyes: Array[RigEye2D]) -> void`
Unpairs every eye in the given list from every other eye in the list, a shortcut for manually unpairing combination in a group. To clear eye from all groups faster, use `clear_pairs()`

**Arguments**
- `eyes` - the other `RigEye2D` instances to unpair from this eye and from each other.

### `get_eye_position(element: EyePart) -> Vector2`
Returns the current local-space position of the given eye element. Can be used for projectile targeting, etc.

**Arguments**
- `element` - which part to query: `EyePart.WHITE`, `EyePart.IRIS`, or `EyePart.PUPIL`.

### `get_eye_sprite(element: EyePart) -> Sprite2D`
Returns `Sprite2D` node for the given eye element.

**Arguments**
- `element` - which part's sprite to retrieve: `EyePart.WHITE`, `EyePart.IRIS`, or `EyePart.PUPIL`.

### `get_eye_node(element: EyePart) -> Node2D`
Returns the `Node2D` movement container for the given eye element. Useful when you need a reference to the node being moved by the plugin, e.g. to attach children to it at runtime.

**Arguments**
- `element` - which part's container to retrieve: `EyePart.WHITE`, `EyePart.IRIS`, or `EyePart.PUPIL`.

### `anim_set_target(node_path: NodePath, property_name: StringName = &"") -> void`
Animation-friendly wrapper for `set_target()` that takes a `NodePath`, since `AnimationPlayer` tracks can't store live node references.

**Arguments**
- `node_path` - path to the `Node2D` to look at.
- `property_name` - same as `set_target()`.

### `anim_pair_eye(eye_path: NodePath) -> void`
Animation-friendly wrapper for `pair_eye()` for use in `AnimationPlayer` Call Method tracks.

**Arguments**
- `eye_path` - path to the `RigEye2D` node to pair with.

### `anim_unpair_eye(eye_path: NodePath) -> void`
Animation-friendly wrapper for `unpair_eye()` for use in `AnimationPlayer` Call Method tracks.

**Arguments**
- `eye_path` - path to the `RigEye2D` node to unpair.

