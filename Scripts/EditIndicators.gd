extends Node3D

@export var edit_mode_state: EditModeState

func _ready():
	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	edit_mode_updated(edit_mode_state.edit_mode)

func edit_mode_updated(edit_mode):
	assert(edit_mode >= 0 and edit_mode < get_child_count())
	
	for c in get_children():
		c.visible = false
	
	get_child(edit_mode).visible = true
