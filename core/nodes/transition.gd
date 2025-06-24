@tool
class_name Transition
extends Control


var animation_player: AnimationPlayer

const INTRO_ANIM_NAME := "intro"
const OUTRO_ANIM_NAME := "outro"


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var found_anim_player := false
	
	for i in get_child_count():
		var child = get_child(i)
		if child is AnimationPlayer:
			animation_player = child
			found_anim_player = true
			break
	
	if not found_anim_player:
		warnings.append("Transition requires an AnimationPlayer child.")
	else:
		if not animation_player.has_animation(INTRO_ANIM_NAME):
			warnings.append("AnimationPlayer is missing the '%s' animation." % INTRO_ANIM_NAME)
		if not animation_player.has_animation(OUTRO_ANIM_NAME):
			warnings.append("AnimationPlayer is missing the '%s' animation." % OUTRO_ANIM_NAME)
	return warnings


func _ready():
	visible = false
	
	for child in get_children():
		if child is AnimationPlayer:
			animation_player = child
			break

	if not animation_player:
		push_error("Transition on '%s': AnimationPlayer child not found!" % get_path())


func play_intro() -> void:
	if animation_player and animation_player.has_animation(INTRO_ANIM_NAME):
		visible = true
		animation_player.play(INTRO_ANIM_NAME)
		await animation_player.animation_finished
	else:
		push_warning("'%s': '%s' animation not found or AnimationPlayer missing." % [get_path(), INTRO_ANIM_NAME])


func play_outro() -> void:
	if animation_player and animation_player.has_animation(OUTRO_ANIM_NAME):
		animation_player.play(OUTRO_ANIM_NAME)
		await animation_player.animation_finished
		visible = false
	else:
		push_warning("'%s': '%s' animation not found or AnimationPlayer missing." % [get_path(), OUTRO_ANIM_NAME])
