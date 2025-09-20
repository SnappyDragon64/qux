@tool
class_name SnapshotDiff
extends RefCounted


var new_registries: Array[RegistryData]
var edited_registries: Array[RegistryData]
var deleted_registries: Array[RegistryData]


func has_changes() -> bool:
	return not (new_registries.is_empty() and edited_registries.is_empty() and deleted_registries.is_empty())
