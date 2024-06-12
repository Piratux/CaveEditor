# In the future consider having a gizmo at least for mesh indicator.
# Potential implementations:
# - https://github.com/nishlumi/transform_ctrl_gizmo/tree/main/addons/transform_ctrl_gizmo
# - https://github.com/sevonj/sr2_chonker/tree/0.0.7/scenes/editor/gizmo

extends Node3D

@export var edit_mode_state: EditModeState
@export var tool_state: ToolState

@onready var mesh_indicator = get_node("Mesh")

var EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE

func _ready():
	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	edit_mode_updated(edit_mode_state.edit_mode)
	
	tool_state.mesh_preview_enabled_updated.connect(mesh_preview_enabled_updated)
	mesh_preview_enabled_updated(tool_state.mesh_preview_enabled)

func edit_mode_updated(edit_mode):
	assert(edit_mode >= 0 and edit_mode < get_child_count())
	
	for c in get_children():
		c.visible = false
	
	get_child(edit_mode).visible = true
	
	if edit_mode == EDIT_MODE.MESH:
		mesh_preview_enabled_updated(tool_state.mesh_preview_enabled)

func mesh_preview_enabled_updated(new_value):
	mesh_indicator.visible = not new_value
