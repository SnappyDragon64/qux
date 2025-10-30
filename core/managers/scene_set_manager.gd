extends Node

signal scene_set_initialized(context: SceneSetContext)

var _current_set: SceneSetEntry
var _is_transitioning: bool = false


func change_set(new_set_entry: SceneSetEntry) -> void:
	if not new_set_entry:
		push_error("SceneSetManager: Cannot change_set to a null SceneSetEntry.")
		return

	if _is_transitioning:
		push_warning("SceneSetManager: Transition already in progress. Ignoring change set request.")
		return
		
	if _current_set and new_set_entry.id == _current_set.resource_path:
		push_warning("SceneSetManager: Scene set '%s' is already loaded." % _current_set.resource_path)
		return
		
	_execute_transition(new_set_entry)


func reload_current_set() -> void:
	if _is_transitioning:
		push_warning("SceneSetManager: Transition already in progress. Ignoring reload request.")
		return

	if not _current_set:
		push_error("SceneSetManager: Cannot reload, no scene set is currently loaded.")
		return

	_execute_transition(_current_set)


func _execute_transition(target_set: SceneSetEntry) -> void:
	_is_transitioning = true
	
	PauseManager.set_pause_state(false)
	
	if _current_set:
		await TransitionManager.play_intro()
		
		var unload_tasks: Array[UnloadSceneTask] = []
		for scene_entry in _current_set.scenes:
			var unload_task: UnloadSceneTask = SceneManager.unload_scene(scene_entry)
			unload_tasks.append(unload_task)
		
		for task in unload_tasks:
			if not task.is_complete:
				await task.completed
	
	var context = SceneSetContext.new()
	context.entry = target_set

	var load_tasks: Array[LoadSceneTask] = []
	for scene_entry in target_set.scenes:
		var load_task: LoadSceneTask = SceneManager.load_scene(scene_entry) 
		load_tasks.append(load_task)
		
	for task in load_tasks:
		if not task.is_complete:
			await task.completed
		
		if task.result and task.scene_entry:
			context.scenes[task.scene_entry] = task.result
	
	_current_set = target_set
	PauseManager.set_pausable(_current_set.is_pausable)
	
	scene_set_initialized.emit(context)
	
	await TransitionManager.play_outro()

	_is_transitioning = false
