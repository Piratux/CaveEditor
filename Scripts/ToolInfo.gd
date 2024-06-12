extends PanelContainer

@export var edit_mode_state: EditModeState
@export var tool_state: ToolState

@onready var parameter_container = get_node("MarginContainer/VBoxContainer/ParameterContainer")

const EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE
const TOOL_DATA = preload("res://Scripts/ToolData.gd").TOOL_DATA
var ParameterSlider = preload("res://Scenes/ParameterSlider.tscn")

func _ready():
	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	create_parameter_sliders()
	edit_mode_updated(edit_mode_state.edit_mode)

func edit_mode_updated(edit_mode):
	set_parameter_sliders(edit_mode)

func set_parameter_sliders(edit_mode):
	# hide all sliders
	for n in parameter_container.get_children():
		n.visible = false
	
	# show only current edit mode sliders
	for parameter_slider in tool_state._parameter_sliders[edit_mode].values():
		parameter_slider.visible = true

func create_parameter_sliders():
	for edit_mode in TOOL_DATA.keys():
		var tool_parameters = TOOL_DATA[edit_mode].parameters
		tool_state._parameter_sliders[edit_mode] = {}
		
		for parameter_name in tool_parameters.keys():
			add_parameter_slider(edit_mode, parameter_name, tool_parameters[parameter_name])

func add_parameter_slider(edit_mode, parameter_name, parameter_data):
	var slider = ParameterSlider.instantiate()
	parameter_container.add_child(slider)
	slider.init(parameter_data)
	
	tool_state._parameter_sliders[edit_mode][parameter_name] = slider
