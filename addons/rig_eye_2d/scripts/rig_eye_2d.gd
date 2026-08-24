@tool
@icon("res://addons/rig_eye_2d/assets/icons/rig_eye_2d.svg")
## Tool providing 2D eye movement and target tracking
class_name RigEye2D
extends Node2D

## Emits when eye movement is started
signal move_started()
## Emits when eye movement is finished
signal move_finished()
## Emits when the Node2D target of the eye is changed
signal target_changed(old_target: Node2D, new_target: Node2D)
## Emits when the active tracking mode changes
signal tracking_changed(mode: TrackingMode)

## Result of resolving an eye's own look target between paired eyes
class LookTargetCandidate:
	var has_target: bool
	var position: Vector2
	var priority: int

	func _init(p_has_target: bool, p_position: Vector2, p_priority: int) -> void:
		has_target = p_has_target
		position = p_position
		priority = p_priority

enum EyePart {
	WHITE,
	IRIS,
	PUPIL
}

enum TrackingMode {
	NONE,
	NODE,
	MOUSE,
	POINT
}

## Process animation in Godot editor
@export var process_in_editor: bool = false

@export_group('Tracking')
## Internal reference to current node as Node2D type (has to be separate, because only NodePath saves in animation keyframes)
var target: Node2D = null:
	set(value):
		var previous: Node2D = target
		target = value
		_target_property = &""
		_use_manual_look_target = false
		target_changed.emit(previous, value)
		_update_tracking_mode()
		if is_inside_tree():
			var new_path: NodePath = get_path_to(value) if value != null else NodePath("")
			if target_path != new_path:
				target_path = new_path
		_broadcast_tracking_to_pairs()
## Node2D that this eye tracks (also usable in AnimationPlayer keyframe tracks as NodePath)
@export_node_path("Node2D") var target_path: NodePath = NodePath(""):
	set(value):
		target_path = value
		if is_inside_tree():
			var resolved: Node2D = get_node_or_null(target_path) as Node2D
			if target != resolved:
				target = resolved
## Enable eye tracking mouse cursor position
@export var track_mouse: bool = false:
	set(value):
		track_mouse = value
		if value:
			_use_manual_look_target = false
		_update_tracking_mode()
		_broadcast_tracking_to_pairs()
## Pair the movement with other RigEye2D nodes
@export var paired_eyes: Array[RigEye2D] = []:
	set(value):
		var previous: Array[RigEye2D] = paired_eyes
		paired_eyes = value
		for eye in previous:
			if is_instance_valid(eye) and eye != self and !value.has(eye):
				eye._remove_paired_eye(self)
		for eye in value:
			if is_instance_valid(eye) and eye != self and !previous.has(eye):
				eye._add_paired_eye(self)
				eye._receive_synced_tracking(
					target, 
					_target_property, 
					track_mouse, 
					_use_manual_look_target, 
					_manual_look_target
				)

@export_group('Speed')
## Eye elements movement speed
@export_range(0.0, 200.00, 1.0) var smooth_speed: float = 8.0
## Enable low-FPS stylized animation
@export var limit_fps: bool = false:
	set(value):
		limit_fps = value
		notify_property_list_changed()
## FPS animation limiter
@export_range(1.0, 60.0, 1.0) var fps: float = 15.0:
	set(value):
		fps = value
		_fps_step = 1.0 / fps

@export_group('Bounds')
## Movement bounds of eye white
@export_custom(PROPERTY_HINT_LINK, "") var bounds_white: Vector2 = Vector2(0.0, 0.0)
## Movement bounds of iris
@export_custom(PROPERTY_HINT_LINK, "") var bounds_iris: Vector2 = Vector2(10.0, 10.0)
## Movement bounds of pupil
@export_custom(PROPERTY_HINT_LINK, "") var bounds_pupil: Vector2 = Vector2(0.0, 0.0)

const MOVEMENT_THRESHOLD: float = 0.01

var _tracking_mode: TrackingMode = TrackingMode.NONE
var _is_moving: bool = false
var _accumulator: float = 0.0
var _fps_step: float = 1.0 / 15.0
var _look_target: Vector2 = Vector2.ZERO
var _world_look_target: Vector2 = Vector2.ZERO
var _has_look_target: bool = false
var _last_driven_frame: int = -1
var _target_property: StringName = &""
var _in_editor: bool = false
var _use_manual_look_target: bool = false
var _manual_look_target: Vector2 = Vector2.ZERO
var _eye_white: Node2D = null
var _eye_iris: Node2D = null
var _eye_pupil: Node2D = null
var _sprite_white: Sprite2D = null
var _sprite_iris: Sprite2D = null
var _sprite_pupil: Sprite2D = null
var _skip_broadcast: bool = false


func _ready() -> void:
	_in_editor = Engine.is_editor_hint()
	_eye_white = get_node_or_null("EyeWhite") as Node2D
	_eye_iris = get_node_or_null("EyeWhite/EyeIris") as Node2D
	_eye_pupil = get_node_or_null("EyeWhite/EyeIris/EyePupil") as Node2D
	_sprite_white = get_node_or_null("EyeWhite/EyeWhiteSprite") as Sprite2D
	_sprite_iris = get_node_or_null("EyeWhite/EyeIris/EyeIrisSprite") as Sprite2D
	_sprite_pupil = get_node_or_null("EyeWhite/EyeIris/EyePupil/EyePupilSprite") as Sprite2D
	if !target_path.is_empty():
		target = get_node_or_null(target_path) as Node2D


func _validate_property(property: Dictionary) -> void:
	if property.name == "fps" and !limit_fps:
		property.usage = PROPERTY_USAGE_STORAGE


func _process(delta: float) -> void:
	if !process_in_editor and _in_editor:
		return
	if _last_driven_frame == Engine.get_process_frames():
		return
	
	var lerp_weight: float = clampf(smooth_speed * delta, 0.0, 1.0)
	if limit_fps:
		_accumulator += delta
		while _accumulator >= _fps_step:
			_accumulator -= _fps_step
			_run_eye_tick(lerp_weight)
	else:
		_run_eye_tick(lerp_weight)


## Set the tracking target Node2D
func set_target(node: Node2D, property_name: StringName = &"") -> void:
	_skip_broadcast = true
	track_mouse = false
	target = node
	_target_property = property_name
	_skip_broadcast = false
	_broadcast_tracking_to_pairs()


## Clears the current tracking target for this eye and any paired eyes
func clear_target() -> void:
	target = null


func apply_look_offset(offset: Vector2, weight: float) -> void:
	_last_driven_frame = Engine.get_process_frames()
	_update_eye_movements(offset, weight)


## Returns Vector2 of current eye part position relative to RigEye2D
func get_eye_position(element: EyePart) -> Vector2:
	match element:
		EyePart.WHITE:
			return _eye_white.position
		EyePart.IRIS:
			return _eye_white.position + _eye_iris.position
		EyePart.PUPIL:
			return _eye_white.position + _eye_iris.position + _eye_pupil.position
	return Vector2.ZERO


## Returns the Sprite2D node for the given eye element
func get_eye_sprite(element: EyePart) -> Sprite2D:
	match element:
		EyePart.WHITE:
			return _sprite_white
		EyePart.IRIS:
			return _sprite_iris
		EyePart.PUPIL:
			return _sprite_pupil
	return null


## Returns the Node2D movement container for the given eye element
func get_eye_node(element: EyePart) -> Node2D:
	match element:
		EyePart.WHITE:
			return _eye_white
		EyePart.IRIS:
			return _eye_iris
		EyePart.PUPIL:
			return _eye_pupil
	return null


## Track a fixed world position
func look_at_point(world_position: Vector2) -> void:
	_use_manual_look_target = true
	_manual_look_target = world_position
	_update_tracking_mode()
	_broadcast_tracking_to_pairs()


## Instantly reset all eye elements to center without animating
func snap_to_center() -> void:
	if !_eye_white or !_eye_iris or !_eye_pupil:
		return
	_eye_white.position = Vector2.ZERO
	_eye_iris.position = Vector2.ZERO
	_eye_pupil.position = Vector2.ZERO
	_look_target = Vector2.ZERO
	_world_look_target = Vector2.ZERO
	_has_look_target = false
	_accumulator = 0.0
	if _is_moving:
		_is_moving = false
		move_finished.emit()


## Add an eye to paired_eyes, pairing is mutual so the other eye also gets this one added to its paired_eyes
func pair_eye(eye: RigEye2D) -> void:
	if eye == null or eye == self or paired_eyes.has(eye):
		return
	paired_eyes.append(eye)
	eye._add_paired_eye(self)
	eye._receive_synced_tracking(
		target, 
		_target_property, 
		track_mouse, 
		_use_manual_look_target, 
		_manual_look_target
	)


## Remove an eye from paired_eyes, also removing this eye from the other eye's paired_eyes
func unpair_eye(eye: RigEye2D) -> void:
	if eye == null:
		return
	paired_eyes.erase(eye)
	eye._remove_paired_eye(self)


## Remove all paired eyes from this instance, also removing this eye from each of their paired_eyes
func clear_pairs() -> void:
	for paired_eye in paired_eyes:
		if is_instance_valid(paired_eye):
			paired_eye._remove_paired_eye(self)
	paired_eyes.clear()


## Mutually pair every eye in the given list with every other eye in the list (including this one)
func pair_group(eyes: Array[RigEye2D]) -> void:
	var group: Array[RigEye2D] = eyes.duplicate()
	if !group.has(self):
		group.append(self)
	for i in range(group.size()):
		for j in range(i + 1, group.size()):
			group[i].pair_eye(group[j])


## Mutually unpair every eye in the given list from every other eye in the list (including this one)
func unpair_group(eyes: Array[RigEye2D]) -> void:
	var group: Array[RigEye2D] = eyes.duplicate()
	if !group.has(self):
		group.append(self)
	for i in range(group.size()):
		for j in range(i + 1, group.size()):
			group[i].unpair_eye(group[j])


## Animation-friendly wrapper for set_target using NodePath
func anim_set_target(node_path: NodePath, property_name: StringName = &"") -> void:
	set_target(get_node_or_null(node_path) as Node2D, property_name)


## Animation-friendly wrapper for pair_eye using NodePath
func anim_pair_eye(eye_path: NodePath) -> void:
	pair_eye(get_node_or_null(eye_path) as RigEye2D)


## Animation-friendly wrapper for unpair_eye using NodePath
func anim_unpair_eye(eye_path: NodePath) -> void:
	unpair_eye(get_node_or_null(eye_path) as RigEye2D)


func _group_midpoint_local(world_target: Vector2) -> Vector2:
	var group_center: Vector2 = global_position
	var count: int = 1
	for paired_eye in paired_eyes:
		if is_instance_valid(paired_eye):
			group_center += paired_eye.global_position
			count += 1
	group_center /= count
	return to_local(global_position + (world_target - group_center))


func _broadcast_tracking_to_pairs() -> void:
	if _skip_broadcast:
		return
	for paired_eye in paired_eyes:
		if is_instance_valid(paired_eye):
			paired_eye._receive_synced_tracking(
				target, 
				_target_property, 
				track_mouse, 
				_use_manual_look_target, 
				_manual_look_target
			)


func _receive_synced_tracking(
	t: Node2D, 
	t_prop: StringName, 
	mouse: bool, 
	manual: bool, 
	manual_pos: Vector2
) -> void:
	_skip_broadcast = true
	target = t
	_target_property = t_prop
	track_mouse = mouse
	_manual_look_target = manual_pos
	_use_manual_look_target = manual
	_skip_broadcast = false


func _add_paired_eye(eye: RigEye2D) -> void:
	if eye == null or eye == self or paired_eyes.has(eye):
		return
	paired_eyes.append(eye)


func _remove_paired_eye(eye: RigEye2D) -> void:
	paired_eyes.erase(eye)


func _own_look_target() -> LookTargetCandidate:
	if _use_manual_look_target:
		return LookTargetCandidate.new(true, _manual_look_target, 0)
	if is_instance_valid(target):
		var pos: Vector2 = target.global_position
		if !_target_property.is_empty():
			pos = target.to_global(target.get(_target_property))
		return LookTargetCandidate.new(true, pos, 1)
	if track_mouse:
		return LookTargetCandidate.new(true, get_global_mouse_position(), 2)
	return LookTargetCandidate.new(false, Vector2.ZERO, 3)


func _run_eye_tick(weight: float) -> void:
	var best: LookTargetCandidate = _own_look_target()
	for paired_eye in paired_eyes:
		if is_instance_valid(paired_eye):
			var candidate: LookTargetCandidate = paired_eye._own_look_target()
			if candidate.has_target and (!best.has_target or candidate.priority < best.priority):
				best = candidate
	
	_has_look_target = best.has_target
	_world_look_target = best.position
	if _has_look_target:
		_look_target = _group_midpoint_local(_world_look_target)
	else:
		_look_target = Vector2.ZERO
	
	_update_eye_movements(_look_target, weight)
	for paired_eye in paired_eyes:
		if is_instance_valid(paired_eye):
			paired_eye.apply_look_offset(_look_target, weight)


func _update_eye_movements(look_offset: Vector2, weight: float) -> void:
	if !_eye_white or !_eye_iris or !_eye_pupil:
		return
	var prev_white: Vector2 = _eye_white.position
	var prev_iris: Vector2 = _eye_iris.position
	var prev_pupil: Vector2 = _eye_pupil.position
	_eye_movement(_eye_white, look_offset, bounds_white, weight)
	_eye_movement(_eye_iris, look_offset, bounds_iris, weight)
	_eye_movement(_eye_pupil, look_offset, bounds_pupil, weight)
	
	var any_moved: bool = (
		_eye_white.position.distance_to(prev_white) > MOVEMENT_THRESHOLD or
		_eye_iris.position.distance_to(prev_iris) > MOVEMENT_THRESHOLD or
		_eye_pupil.position.distance_to(prev_pupil) > MOVEMENT_THRESHOLD
	)
	
	if any_moved and !_is_moving:
		_is_moving = true
		move_started.emit()
	elif !any_moved and _is_moving:
		_is_moving = false
		move_finished.emit()


func _eye_movement(
	element: Node2D,
	target: Vector2,
	bounds: Vector2,
	weight: float
) -> void:
	var scaled_x: float = target.x / bounds.x if bounds.x > 0.0 else 0.0
	var scaled_y: float = target.y / bounds.y if bounds.y > 0.0 else 0.0
	var clamped: Vector2 = Vector2(scaled_x, scaled_y).limit_length(1.0) * bounds
	element.position = element.position.lerp(clamped, weight)


func _compute_tracking_mode() -> TrackingMode:
	if _use_manual_look_target:
		return TrackingMode.POINT
	if is_instance_valid(target):
		return TrackingMode.NODE
	if track_mouse:
		return TrackingMode.MOUSE
	return TrackingMode.NONE


func _update_tracking_mode() -> void:
	var new_mode: TrackingMode = _compute_tracking_mode()
	if new_mode == _tracking_mode:
		return
	_tracking_mode = new_mode
	tracking_changed.emit(_tracking_mode)


