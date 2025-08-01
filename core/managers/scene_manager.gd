extends Node


var _scenes: Dictionary[StringName, Node] = {}


func load_scene(scene_entry: SceneEntry) -> LoadSceneTask:
	var task = LoadSceneTask.new()
	task.scene_entry = scene_entry

	_load_scene(task)

	return task


func unload_scene(scene_entry: SceneEntry) -> void:
	if not scene_entry:
		push_error("SceneManager: Cannot unload scene. The provided SceneEntry is invalid.")
		return
	if not _scenes.has(scene_entry.resource_path):
		return

	var scene_instance = _scenes.get(scene_entry.resource_path)
	if is_instance_valid(scene_instance):
		scene_instance.queue_free()
	_scenes.erase(scene_entry.resource_path)


func get_scene(scene_entry: SceneEntry) -> Node:
	if not scene_entry: return null
	return _scenes.get(scene_entry.resource_path, null)


func is_scene_loaded(scene_entry: SceneEntry) -> bool:
	if not scene_entry: return false
	return _scenes.has(scene_entry.resource_path)


func _load_scene(task: LoadSceneTask) -> void:
	var entry = task.scene_entry
	if not entry or not entry.path:
		push_error("SceneManager: Cannot load scene. Invalid SceneEntry provided to task.")
		return
	if not entry.layer_entry:
		push_error("SceneManager: SceneEntry '%s' is missing a LayerEntry." % entry.resource_path)
		return
		
	if _scenes.has(entry.resource_path):
		task.result = _scenes[entry.resource_path]
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

	_scenes[entry.resource_path] = scene_instance
	
	task.result = scene_instance
	task.is_complete = true
	task.completed.emit(task.result)
