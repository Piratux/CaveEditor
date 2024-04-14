extends Button

@export var tool_mesh_bake_state: ToolMeshBakeState

func _on_pressed():
	tool_mesh_bake_state.bake_selected_sdf_mesh()
