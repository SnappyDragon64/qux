class_name LoadSceneTask extends RefCounted


@warning_ignore("unused_signal")
signal completed(result: Node)


var scene_entry: SceneEntry
var result: Node
var is_complete: bool = false
