extends Node


signal paused
signal resumed

var pause_action_name: StringName = &"pause"

var is_paused: bool = false
var _can_pause: bool = false

var _action_exists_in_map: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_action_exists_in_map = InputMap.has_action(pause_action_name)

	if not _action_exists_in_map:
		push_warning("PauseManager: Input action '%s' not found in Input Map, falling back to Escape key. Add the action to enable remapping." % pause_action_name)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_pause:
		return

	var pause_requested: bool = false

	if _action_exists_in_map:
		if event.is_action_pressed(pause_action_name):
			pause_requested = true
	
	else:
		if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed() and not event.is_echo():
			pause_requested = true

	if pause_requested:
		set_pause_state(not is_paused)
		get_viewport().set_input_as_handled()


func set_pause_state(new_state: bool) -> void:
	if new_state == is_paused:
		return

	is_paused = new_state
	get_tree().paused = is_paused

	if is_paused:
		paused.emit()
	else:
		resumed.emit()


func pause() -> void:
	set_pause_state(true)


func resume() -> void:
	set_pause_state(false)


func set_pausable(can_be_paused: bool) -> void:
	_can_pause = can_be_paused
