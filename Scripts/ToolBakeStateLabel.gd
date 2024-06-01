extends RichTextLabel

@export var tool_mesh_bake_state: ToolMeshBakeState

const SDF_MESH_STATE_COLOUR_DATA = preload("res://Scripts/SdfMeshStateColourData.gd").SDF_MESH_STATE_COLOUR_DATA

func _process(_delta):
	text = ""
	if tool_mesh_bake_state.total_sdf_meshes() == 0:
		return
	
	var edit_mesh_state = tool_mesh_bake_state.get_selected_sdf_mesh_state()
	var colour = SDF_MESH_STATE_COLOUR_DATA[edit_mesh_state].colour
	var state_text = SDF_MESH_STATE_COLOUR_DATA[edit_mesh_state].text
	
	text = "State: [color=" + colour.to_html(false) + "]" + state_text + "[/color]"
