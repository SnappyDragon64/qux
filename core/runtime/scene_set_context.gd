class_name SceneSetContext
extends RefCounted

var entry: SceneSetEntry
var scenes: Dictionary[SceneEntry, Node] = {}


func get_scene(scene_entry: SceneEntry) -> Node:
	return scenes.get(scene_entry, null)
