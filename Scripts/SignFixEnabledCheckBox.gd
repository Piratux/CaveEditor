extends CheckBox

@export var tool_mesh_bake_state: ToolMeshBakeState

func _ready():
	tool_mesh_bake_state.boundary_sign_fix_enabled_updated.connect(boundary_sign_fix_enabled_updated)
	_on_toggled(button_pressed)

func boundary_sign_fix_enabled_updated(toggled_on):
	button_pressed = toggled_on

func _on_toggled(toggled_on):
	tool_mesh_bake_state.boundary_sign_fix_enabled = toggled_on
