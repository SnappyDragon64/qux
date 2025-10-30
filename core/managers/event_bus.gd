extends Node


func subscribe(event_entry: EventEntry, callable: Callable) -> void:
	var signal_name = event_entry.id
	
	if not has_signal(signal_name):
		add_user_signal(signal_name)
	
	connect(event_entry.id, callable)


func unsubscribe(event_entry: EventEntry, callable: Callable) -> void:
	if is_connected(event_entry.id, callable):
		disconnect(event_entry.id, callable)


func publish(event_entry: EventEntry, data: Dictionary = {}) -> void:
	var signal_name = event_entry.id

	if not _validate_and_register_event(event_entry, data):
		return

	emit_signal(signal_name, data)


func wait_for(event_entry: EventEntry) -> Dictionary:
	var signal_name = event_entry.id

	if not has_signal(signal_name):
		add_user_signal(signal_name)

	var signal_args: Array = await Signal(self, signal_name)
	
	if signal_args.size() == 1 and signal_args[0] is Dictionary:
		return signal_args[0]
	else:
		push_error("EventBus: Unexpected signal arguments for event '%s'. Args: %s" % [signal_name, str(signal_args)])
		return {}


func _validate_and_register_event(event_entry: EventEntry, data: Dictionary) -> bool:
	var signal_name = event_entry.id
	
	if event_entry.data_schema:
		if not _validate_data(event_entry.data_schema, data):
			push_error("EventBus: Invalid payload for event '%s'. Event not published." % signal_name)
			return false
	elif not data.is_empty():
		push_error("EventBus: Event '%s' has no schema but received data. Event not published." % signal_name)
		return false
		
	if not has_signal(signal_name):
		add_user_signal(signal_name)
		
	return true


func _validate_data(schema: Dictionary, data: Dictionary) -> bool:
	if data.size() != schema.size():
		push_warning("EventBus: Validation failed: Data size does not match schema size for schema: %s" % schema.keys())
		return false
	
	for key in schema:
		if not data.has(key):
			push_warning("EventBus: Validation failed: Payload missing required key '%s'." % key)
			return false
		if typeof(data[key]) != schema[key]:
			var expected_type_str = type_string(schema[key])
			var actual_type_str = type_string(typeof(data[key]))
			push_warning("EventBus: Validation failed for key '%s': Expected type %s, got %s." % [key, expected_type_str, actual_type_str])
			return false
	
	return true
