extends Node


var _scenes: Dictionary[StringName, Node] = {}


func load_scene(scene_entry: SceneEntry) -> void:
	if not scene_entry.layer_entry:
		push_error("SceneManager: Cannot load scene. SceneEntry is missing LayerEntry for: %s" % scene_entry.resource_path)
		return

	if _scenes.has(scene_entry.resource_path):
		push_warning("SceneManager: Scene '%s' is already loaded. Skipping duplicate load." % scene_entry.path)
		return

	var canvas_layer: CanvasLayer = LayerManager.get_layer(scene_entry.layer_entry)
	
	var packed_scene: PackedScene = load(scene_entry.path)
	if not packed_scene:
		push_error("SceneManager: Failed to load scene resource at path: %s" % scene_entry.path)
		return

	var scene_instance = packed_scene.instantiate()
	if not scene_instance:
		push_error("SceneManager: Failed to instantiate scene at path: %s" % scene_entry.path)
		return

	canvas_layer.add_child.call_deferred(scene_instance)
	_scenes[scene_entry.resource_path] = scene_instance


func unload_scene(scene_entry: SceneEntry) -> void:
	if not scene_entry.layer_entry:
		push_error("SceneManager: Cannot unload scene. SceneEntry is missing LayerEntry for: %s" % scene_entry.resource_path)
		return

	var canvas_layer: CanvasLayer = LayerManager.get_layer(scene_entry.layer_entry)

	if _scenes.has(scene_entry.resource_path):
		var scene_instance = _scenes[scene_entry.resource_path]
		_scenes.erase(scene_entry.resource_path)
		
		if scene_instance and canvas_layer.is_a_parent_of(scene_instance):
			canvas_layer.remove_child(scene_instance)
			scene_instance.queue_free()
		else:
			push_warning("SceneManager: Attempted to unload scene '%s', but it was not found as a child of its designated layer '%s', or was not tracked correctly." % [scene_entry.path, scene_entry.layer_entry.name])
	else:
		push_warning("SceneManager: Attempted to unload scene '%s', but it was not tracked as loaded by SceneManager." % scene_entry.path)


func get_scene(scene_entry: SceneEntry) -> Node:
	var scene_instance = _scenes.get(scene_entry.resource_path, null)

	if not scene_instance:
		push_warning("SceneManager: No scene instance found for SceneEntry '%s'. It might not be loaded or the SceneEntry is incorrect." % scene_entry.resource_path)

	return scene_instance


func is_scene_loaded(scene_entry: SceneEntry) -> bool:
	return _scenes.has(scene_entry.resource_path)
