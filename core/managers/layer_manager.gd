extends Node


var _canvas_layers: Dictionary[StringName, CanvasLayer] = {}


func _ready() -> void:
	var all_layers: Array[LayerEntry] = Layers.get_all()

	for layer_entry in all_layers:
		var canvas_layer := CanvasLayer.new()
		canvas_layer.name = layer_entry.name
		canvas_layer.layer = layer_entry.layer
		_canvas_layers[layer_entry.resource_path] = canvas_layer
		add_child(canvas_layer)


func get_layer(layer_entry: LayerEntry) -> CanvasLayer:
	if not _canvas_layers.has(layer_entry.resource_path):
		push_error("LayerManager does not have a registered layer for: %s" % layer_entry.resource_path)
		return null
	
	return _canvas_layers[layer_entry.resource_path]
