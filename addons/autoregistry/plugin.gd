@tool
extends EditorPlugin


const Generator = preload("res://addons/autoregistry/generator.gd")

var regenerate_button
var debounce_timer
var filesystem
var generator

const DB_SCAN_PATH = "res://data/registry/"


func _enter_tree():
	regenerate_button = Button.new()
	regenerate_button.flat = true
	regenerate_button.text = "AutoRegistry"
	regenerate_button.tooltip_text = "Forces regeneration of registries."
	regenerate_button.icon = get_editor_interface().get_base_control().get_theme_icon("Reload", "EditorIcons")
	regenerate_button.pressed.connect(_trigger_regeneration)
	add_control_to_container(CONTAINER_TOOLBAR, regenerate_button)
	
	var toolbar = regenerate_button.get_parent()
	toolbar.move_child(regenerate_button, 4)
	regenerate_button.set_visible(false)
	
	debounce_timer = Timer.new()
	debounce_timer.wait_time = 0.5
	debounce_timer.one_shot = true
	debounce_timer.timeout.connect(_on_debounce_timer_timeout)
	add_child(debounce_timer)
	
	filesystem = get_editor_interface().get_resource_filesystem()
	filesystem.filesystem_changed.connect(_on_filesystem_changed)
	
	generator = Generator.new()


func _exit_tree():
	filesystem.filesystem_changed.disconnect(_on_filesystem_changed)
	remove_control_from_container(CONTAINER_TOOLBAR, regenerate_button)
	regenerate_button.queue_free()
	debounce_timer.queue_free()


func _on_filesystem_changed():
	debounce_timer.start()


func _on_debounce_timer_timeout():
	_trigger_regeneration()


func _trigger_regeneration():
	print("AutoRegistry: Regenerating registries...")
	generator.generate()
	print("AutoRegistry: Regeneration complete.")
