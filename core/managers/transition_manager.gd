extends Node


var _current_transition_entry: TransitionEntry
var _current_transition: Transition


func set_current_transition(transition_entry: TransitionEntry) -> bool:
	_current_transition = null
	_current_transition_entry = null

	if not transition_entry:
		return true

	if not transition_entry.scene_entry:
		push_error("TransitionManager: Cannot set transition. The provided TransitionEntry '%s' has no SceneEntry defined." % transition_entry.resource_path)
		return false

	if not SceneManager.is_scene_loaded(transition_entry.scene_entry):
		push_error("TransitionManager: Cannot set transition '%s'. Its scene has not been loaded by SceneManager." % transition_entry.resource_path)
		return false

	var scene_instance = SceneManager.get_scene(transition_entry.scene_entry)
	if not scene_instance is Transition:
		var type_str = "null" if not scene_instance else scene_instance.get_class()
		push_error("TransitionManager: Cannot set transition '%s'. Its scene node is a '%s', not a 'Transition'." % [transition_entry.resource_path, type_str])
		return false

	_current_transition = scene_instance
	_current_transition_entry = transition_entry
	return true


func play_intro() -> void:
	if _current_transition:
		await _current_transition.play_intro()


func play_outro() -> void:
	if _current_transition:
		await _current_transition.play_outro()
