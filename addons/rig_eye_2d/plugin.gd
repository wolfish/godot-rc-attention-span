@tool
extends EditorPlugin

const DEBUG_ITEM_TEXT: String = "Visible RigEye Pair Center"
const DEBUG_SEPARATOR_ID: int = 10085
const DEBUG_ITEM_ID: int = 10086
const MARKER_SIZE: float = 8.0
const MARKER_COLOR: Color = Color.YELLOW
const LINE_WIDTH: float = 2.0

var gizmo_node: Node2D = null
var debug_menu: PopupMenu = null
var gizmo_visible: bool = false


func _enter_tree() -> void:
	set_process(true)
	_setup_debug_menu_item()


func _exit_tree() -> void:
	set_process(false)
	_cleanup_gizmo_node()
	_cleanup_debug_menu_item()


func _process(_delta: float) -> void:
	if not gizmo_visible:
		return
	
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		_cleanup_gizmo_node()
		return
	
	if not is_instance_valid(gizmo_node) or gizmo_node.get_parent() != scene_root:
		_cleanup_gizmo_node()
		_create_gizmo_node(scene_root)
	_redraw_gizmos(scene_root)


func _create_gizmo_node(parent: Node) -> void:
	gizmo_node = Node2D.new()
	gizmo_node.z_as_relative = false
	gizmo_node.z_index = 4096
	parent.add_child(gizmo_node, false, Node.INTERNAL_MODE_BACK)


func _cleanup_gizmo_node() -> void:
	if is_instance_valid(gizmo_node):
		gizmo_node.queue_free()
	gizmo_node = null


func _setup_debug_menu_item() -> void:
	debug_menu = _find_debug_popup(EditorInterface.get_base_control())
	if debug_menu == null:
		return
	debug_menu.add_separator("", DEBUG_SEPARATOR_ID)
	debug_menu.add_check_item(DEBUG_ITEM_TEXT, DEBUG_ITEM_ID)
	debug_menu.id_pressed.connect(_on_debug_menu_id_pressed)


func _cleanup_debug_menu_item() -> void:
	if not is_instance_valid(debug_menu):
		return
	var item_idx: int = debug_menu.get_item_index(DEBUG_ITEM_ID)
	if item_idx != -1:
		debug_menu.remove_item(item_idx)
	var sep_idx: int = debug_menu.get_item_index(DEBUG_SEPARATOR_ID)
	if sep_idx != -1:
		debug_menu.remove_item(sep_idx)
	if debug_menu.id_pressed.is_connected(_on_debug_menu_id_pressed):
		debug_menu.id_pressed.disconnect(_on_debug_menu_id_pressed)
	debug_menu = null


func _on_debug_menu_id_pressed(id: int) -> void:
	if id != DEBUG_ITEM_ID:
		return
	gizmo_visible = not gizmo_visible
	var idx: int = debug_menu.get_item_index(DEBUG_ITEM_ID)
	debug_menu.set_item_checked(idx, gizmo_visible)
	if not gizmo_visible:
		_cleanup_gizmo_node()


func _find_debug_popup(node: Node) -> PopupMenu:
	if node is MenuBar:
		for i in range(node.get_menu_count()):
			if node.get_menu_title(i) == "Debug":
				return node.get_menu_popup(i)
	for child in node.get_children(true):
		var result: PopupMenu = _find_debug_popup(child)
		if result != null:
			return result
	return null


func _redraw_gizmos(scene_root: Node) -> void:
	if not is_instance_valid(gizmo_node):
		return
	
	var canvas_item: RID = gizmo_node.get_canvas_item()
	RenderingServer.canvas_item_clear(canvas_item)
	
	var all_eyes: Array = []
	_collect_rig_eyes(scene_root, all_eyes)
	
	var processed: Dictionary = {}
	for eye in all_eyes:
		if processed.has(eye):
			continue
		
		var pairs = eye.get("paired_eyes")
		if pairs == null or pairs.size() == 0:
			processed[eye] = true
			continue
		
		var group_center: Vector2 = eye.global_position
		var count: int = 1
		for paired_eye in pairs:
			if is_instance_valid(paired_eye):
				group_center += paired_eye.global_position
				count += 1
				processed[paired_eye] = true
		group_center /= count
		processed[eye] = true
		_add_x_marker(canvas_item, gizmo_node.to_local(group_center))


func _collect_rig_eyes(node: Node, result: Array) -> void:
	if node is RigEye2D:
		result.append(node)
	for child in node.get_children():
		_collect_rig_eyes(child, result)


func _add_x_marker(canvas_item: RID, center: Vector2) -> void:
	RenderingServer.canvas_item_add_line(canvas_item, center + Vector2(-MARKER_SIZE, -MARKER_SIZE), center + Vector2(MARKER_SIZE, MARKER_SIZE), MARKER_COLOR, LINE_WIDTH)
	RenderingServer.canvas_item_add_line(canvas_item, center + Vector2(MARKER_SIZE, -MARKER_SIZE), center + Vector2(-MARKER_SIZE, MARKER_SIZE), MARKER_COLOR, LINE_WIDTH)
