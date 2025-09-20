@tool
class_name RegistryScanner
extends RefCounted


func scan_sources(config: MemokeeperConfig) -> Dictionary[String, RegistryData]:
	var scanned_data: Dictionary[String, RegistryData] = {}
	
	if not config:
		printerr("Memokeeper: Provided config is null.")
		return scanned_data

	for source in config.sources:
		var root_dir := DirAccess.open(source.root_path)
		if not root_dir:
			push_warning("Memokeeper: Could not open root path: %s" % source.root_path)
			continue

		for folder_name in root_dir.get_directories():
			var data = RegistryData.new()
			
			data.source_id = source.source_id
			data.registry_path = source.root_path.path_join(folder_name)
			data.target_path = source.target_path.path_join(folder_name.to_snake_case() + ".gd")
			data.registry_class = folder_name.to_pascal_case()

			data.files = _collect_files_recursively(data.registry_path)
			
			scanned_data[data.registry_path] = data
	
	return scanned_data


func _collect_files_recursively(path: String) -> Array[String]:
	var collected_files: Array[String] = []
	var dir := DirAccess.open(path)
	
	if not dir:
		printerr("Memokeeper: Failed to open directory for recursive scan: %s" % path)
		return collected_files

	for file_name in dir.get_files():
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			collected_files.append(path.path_join(file_name))

	for sub_dir_name in dir.get_directories():
		var sub_dir_path = path.path_join(sub_dir_name)
		collected_files.append_array(_collect_files_recursively(sub_dir_path))

	return collected_files


func diff_snapshots(old_snapshot: Dictionary[String, RegistryData], new_snapshot: Dictionary[String, RegistryData]) -> SnapshotDiff:
	var diff := SnapshotDiff.new()

	for old_path in old_snapshot:
		var old_data: RegistryData = old_snapshot[old_path]

		if not new_snapshot.has(old_path):
			diff.deleted_registries.append(old_data)
		else:
			var new_data: RegistryData = new_snapshot[old_path]
			
			var old_files_sorted := old_data.files.duplicate()
			old_files_sorted.sort()
			
			var new_files_sorted := new_data.files.duplicate()
			new_files_sorted.sort()
			
			if old_files_sorted != new_files_sorted:
				diff.edited_registries.append(new_data)

	for new_path in new_snapshot:
		if not old_snapshot.has(new_path):
			var new_data: RegistryData = new_snapshot[new_path]
			diff.new_registries.append(new_data)
			
	return diff
