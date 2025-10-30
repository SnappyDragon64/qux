extends Node


var _canvas_layers: Dictionary[StringName, CanvasLayer] = {}


func _ready() -> void:
	var all_layers: Array[LayerEntry] = Layers.get_all()

	for layer_entry in all_layers:
		var canvas_layer := CanvasLayer.new()
		canvas_layer.name = layer_entry.id
		canvas_layer.layer = layer_entry.layer
		_canvas_layers[layer_entry.id] = canvas_layer
		add_child(canvas_layer)


func get_layer(layer_entry: LayerEntry) -> CanvasLayer:
	if not _canvas_layers.has(layer_entry.id):
		push_error("LayerManager does not have a registered layer for: %s" % layer_entry.id)
		return null
	
	return _canvas_layers[layer_entry.id]
