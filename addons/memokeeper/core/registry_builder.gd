@tool
class_name RegistryBuilder
extends RefCounted


const REGISTRY_HEADER = """# Auto-generated Memokeeper Registry - %s (%s)

"""


func build(registries_to_build: Array[RegistryData]):
	for data in registries_to_build:
		if data.files.is_empty():
			continue
		
		var content: String = _generate_registry_content(data)
		_write_content_to_file(data.target_path, content)


func delete(registries_to_delete: Array[RegistryData]):
	for data in registries_to_delete:
		if FileAccess.file_exists(data.target_path):
			var err := DirAccess.remove_absolute(data.target_path)
			if err != OK:
				printerr("Memokeeper: Failed to delete file at path: %s" % data.target_path)


func _generate_registry_content(data: RegistryData) -> String:
	var entry_type: String = _infer_entry_type(data.files)

	var content = REGISTRY_HEADER % [data.registry_class, data.source_id]
	content += "class_name %s\n\n" % data.registry_class

	var consts: Array[String] = []
	for file_path in data.files:
		var relative_path = file_path.trim_prefix(data.registry_path)
		relative_path = relative_path.trim_prefix("/")
		
		var path_without_extension = relative_path.get_basename()
		var const_name = path_without_extension.replace("/", "_").to_upper()
		
		consts.append(const_name)
		content += "const %s: %s = preload(\"%s\")\n" % [const_name, entry_type, file_path]
	
	content += "\nstatic var ALL: Array[%s] = [%s]\n" % [entry_type, (", ".join(consts))]
	content += "\nstatic func get_all() -> Array[%s]:\n" % entry_type
	content += "    return ALL\n"
	
	return content


func _write_content_to_file(path: String, content: String):
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
	else:
		printerr("Memokeeper: Failed to open or write to file: %s" % path)


func _infer_entry_type(file_paths: Array[String]) -> String:
	for file_path in file_paths:
		var resource = load(file_path)
		if not is_instance_valid(resource):
			continue

		var script = resource.get_script()
		if is_instance_valid(script):
			var script_resource: GDScript = script
			var entry_class_name = script_resource.get_global_name()
			if not entry_class_name.is_empty():
				return entry_class_name
				
		return resource.get_class()

	return "Resource"
