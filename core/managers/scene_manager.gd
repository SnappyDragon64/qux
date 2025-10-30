extends Node


var _scenes: Dictionary[StringName, Node] = {}


func load_scene(scene_entry: SceneEntry) -> LoadSceneTask:
	var task = LoadSceneTask.new()
	task.scene_entry = scene_entry

	_load_scene(task)

	return task


func unload_scene(scene_entry: SceneEntry) -> UnloadSceneTask:
	var task = UnloadSceneTask.new()
	
	_unload_scene(task, scene_entry)
	
	return task


func get_scene(scene_entry: SceneEntry) -> Node:
	if not scene_entry: return null
	return _scenes.get(scene_entry.id, null)


func is_scene_loaded(scene_entry: SceneEntry) -> bool:
	if not scene_entry: return false
	return _scenes.has(scene_entry.id)


func _load_scene(task: LoadSceneTask) -> void:
	var entry = task.scene_entry
	if not entry or not entry.path:
		push_error("SceneManager: Cannot load scene. Invalid SceneEntry provided to task.")
		return
	if not entry.layer_entry:
		push_error("SceneManager: SceneEntry '%s' is missing a LayerEntry." % entry.id)
		return
		
	if _scenes.has(entry.id):
		task.result = _scenes[entry.id]
		task.completed.emit(task.result)
		return

	var canvas_layer: CanvasLayer = LayerManager.get_layer(entry.layer_entry)
	if not canvas_layer: return
	
	var packed_scene: PackedScene = load(entry.path)
	if not packed_scene:
		push_error("SceneManager: Failed to load scene resource at path: %s" % entry.path)
		return

	var scene_instance = packed_scene.instantiate()
	if not scene_instance:
		push_error("SceneManager: Failed to instantiate scene from path: %s" % entry.path)
		return

	canvas_layer.add_child.call_deferred(scene_instance)
	await scene_instance.ready

	_scenes[entry.id] = scene_instance
	
	task.result = scene_instance
	task.is_complete = true
	task.completed.emit(task.result)


func _unload_scene(task: UnloadSceneTask, scene_entry: SceneEntry) -> void:
	if not scene_entry:
		push_error("SceneManager: Cannot unload scene. The provided SceneEntry is invalid.")
		task.is_complete = true
		task.completed.emit()
		return
		
	if not _scenes.has(scene_entry.id):
		task.is_complete = true
		task.completed.emit()
		return

	var scene_instance = _scenes.get(scene_entry.id)
	_scenes.erase(scene_entry.id)

	if is_instance_valid(scene_instance):
		scene_instance.queue_free()
		await scene_instance.tree_exited
	
	task.is_complete = true
	task.completed.emit()
