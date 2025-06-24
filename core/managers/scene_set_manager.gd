extends Node

var _current_set: SceneSetEntry


func change_set(new_set_entry: SceneSetEntry) -> void:
	if _current_set:
		if new_set_entry.resource_path == _current_set.resource_path:
			print("SceneSetManager: Scene set '%s' is already loaded." % _current_set)
			return
		
		await TransitionManager.play_intro()
	
		for scene_entry in _current_set.scenes:
			SceneManager.unload_scene(scene_entry)
	
	for scene_entry in new_set_entry.scenes:
		SceneManager.load_scene(scene_entry)

	_current_set = new_set_entry
	
	await TransitionManager.play_outro()
