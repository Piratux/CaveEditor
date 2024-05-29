extends CheckBox

var EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE

@export var tool_state: ToolState
@export var edit_mode_state: EditModeState

func _ready():
	tool_state.mesh_preview_enabled_updated.connect(mesh_preview_enabled_updated)
	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	_on_toggled(button_pressed)
	edit_mode_updated(edit_mode_state.edit_mode)

func mesh_preview_enabled_updated(toggled_on):
	button_pressed = toggled_on

func edit_mode_updated(new_edit_mode):
	visible = (new_edit_mode == EDIT_MODE.MESH)

func _on_toggled(toggled_on):
	tool_state.mesh_preview_enabled = toggled_on
