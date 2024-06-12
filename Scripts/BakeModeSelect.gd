extends OptionButton

@export var tool_mesh_bake_state: ToolMeshBakeState

func _ready():
	tool_mesh_bake_state.bake_mode_updated.connect(bake_mode_updated)
	_on_item_selected(tool_mesh_bake_state.bake_mode)

func bake_mode_updated(index):
	selected = index

func _on_item_selected(index):
	tool_mesh_bake_state.bake_mode = index
	select(index)
