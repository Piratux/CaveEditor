extends PanelContainer

@export var tool_mesh_bake_state: ToolMeshBakeState
@export var edit_mode_state: EditModeState

@onready var parameter_container = get_node("MarginContainer/VBoxContainer/ParameterContainer")

const EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE

var ParameterSlider = preload("res://Scenes/ParameterSlider.tscn")

const MESH_BAKE_PARAMETERS = {
	"cell_count": {
		"name": "Cell count",
		"default_value": 64,
		"min": 16,
		"max": 256,
		"step": 16,
	},
	"partition_subdiv": {
		"name": "Partition subdiv",
		"default_value": 32,
		"min": 16,
		"max": 64,
		"step": 8,
	},
}

func _ready():
	create_parameter_sliders()

	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	edit_mode_updated(edit_mode_state.edit_mode)

func create_parameter_sliders():
	for parameter_name in MESH_BAKE_PARAMETERS.keys():
		add_parameter_slider(parameter_name, MESH_BAKE_PARAMETERS[parameter_name])

func add_parameter_slider(parameter_name, parameter_data):
	var slider = ParameterSlider.instantiate()
	parameter_container.add_child(slider)
	slider.init(parameter_data)
	
	tool_mesh_bake_state._parameter_sliders[parameter_name] = slider

func edit_mode_updated(new_edit_mode):
	visible = (new_edit_mode == EDIT_MODE.MESH)
