@tool
class_name FileSystemWatcher
extends Node


signal scan_requested


var _debounce_timer: Timer


func _init() -> void:
	_debounce_timer = Timer.new()
	_debounce_timer.wait_time = 0.75
	_debounce_timer.one_shot = true
	_debounce_timer.timeout.connect(_on_debounce_timer_timeout)
	add_child(_debounce_timer)


func start(filesystem: EditorFileSystem) -> void:
	filesystem.filesystem_changed.connect(_on_filesystem_changed)


func _on_filesystem_changed() -> void:
	_debounce_timer.start()


func _on_debounce_timer_timeout() -> void:
	scan_requested.emit()
