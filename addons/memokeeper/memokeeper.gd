@tool
extends EditorPlugin

const CONFIG_PATH = "res://addons/memokeeper/config.tres"

var config: MemokeeperConfig

var watcher: FileSystemWatcher
var scanner: RegistryScanner
var builder: RegistryBuilder

var _current_snapshot: Dictionary = {}


func _enter_tree() -> void:
	config = load(CONFIG_PATH)
	if not config:
		push_warning("Memokeeper: Config file not found at '%s'. Plugin will be disabled." % CONFIG_PATH)
		return

	scanner = RegistryScanner.new()
	watcher = FileSystemWatcher.new()
	builder = RegistryBuilder.new()
	
	add_child(watcher)
	
	var filesystem: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	watcher.start(filesystem)
	watcher.scan_requested.connect(_on_scan_requested)

	_current_snapshot = scanner.scan_sources(config)


func _on_scan_requested() -> void:
	var new_snapshot: Dictionary[String, RegistryData] = scanner.scan_sources(config)
	var diff: SnapshotDiff = scanner.diff_snapshots(_current_snapshot, new_snapshot)

	if diff.has_changes():
		print("Memokeeper: Rebuilding registries...")

		if not diff.new_registries.is_empty():
			var names = diff.new_registries.map(func(r): return r.registry_class)
			print("  - New: %s" % ", ".join(names))
		
		if not diff.edited_registries.is_empty():
			var names = diff.edited_registries.map(func(r): return r.registry_class)
			print("  - Edited: %s" % ", ".join(names))
			
		if not diff.deleted_registries.is_empty():
			var names = diff.deleted_registries.map(func(r): return r.registry_class)
			print("  - Deleted: %s" % ", ".join(names))

		builder.build(diff.new_registries)
		builder.build(diff.edited_registries)
		builder.delete(diff.deleted_registries)

		_current_snapshot = new_snapshot
