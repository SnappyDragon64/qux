extends Node

var _loaded_transition_nodes: Dictionary[TransitionEntry, Transition] = {}
var _current_transition_entry: TransitionEntry
var _current_transition: Transition


func _ready() -> void:
	_load_all_transition_scenes()


func _load_all_transition_scenes() -> void:
	var all_transition_entries: Array[TransitionEntry] = Transitions.get_all()
	for entry: TransitionEntry in all_transition_entries:
		if entry.scene_entry and entry.scene_entry is SceneEntry:
			if not SceneManager.is_scene_loaded(entry.scene_entry):
				SceneManager.load_scene(entry.scene_entry)
			
			await get_tree().process_frame 
			
			var scene_instance = SceneManager.get_scene(entry.scene_entry)
			if scene_instance is Transition:
				_loaded_transition_nodes[entry] = scene_instance
			elif scene_instance:
				push_error("TransitionManager: Scene for TransitionEntry '%s' is not a Transition." % entry.resource_path)
			else:
				push_error("TransitionManager: Failed to get scene instance for TransitionEntry '%s'." % entry.resource_path)
		else:
			push_warning("TransitionManager: TransitionEntry '%s' has no valid SceneEntry defined." % entry.resource_path)


func set_current_transition(transition_entry: TransitionEntry) -> void:
	_current_transition_entry = transition_entry
	if _current_transition_entry and _loaded_transition_nodes.has(_current_transition_entry):
		_current_transition = _loaded_transition_nodes[_current_transition_entry]
	elif _current_transition_entry:
		push_warning("TransitionManager: TransitionEntry '%s' was not found among preloaded transitions." % _current_transition_entry.resource_path)
		_current_transition = null
	else:
		_current_transition = null


func play_intro() -> void:
	if _current_transition:
		await _current_transition.play_intro()


func play_outro() -> void:
	if _current_transition:
		await _current_transition.play_outro()
