extends PanelContainer

@onready var parameter_container = get_node("MarginContainer/VBoxContainer/ParameterContainer")

const EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE
const TOOL_DATA = preload("res://Scripts/ToolData.gd").TOOL_DATA
var ParameterSlider = preload("res://Scenes/ParameterSlider.tscn")

var parameter_sliders = {}

func _ready():
	create_parameter_sliders()
	set_edit_mode(EDIT_MODE.SPHERE)

func set_edit_mode(edit_mode):
	set_parameter_sliders(edit_mode)

func set_parameter_sliders(edit_mode):
	# hide all sliders
	for n in parameter_container.get_children():
		n.visible = false
	
	# show only current edit mode sliders
	for parameter_slider in parameter_sliders[edit_mode].values():
		parameter_slider.visible = true

func create_parameter_sliders():
	for edit_mode in TOOL_DATA.keys():
		var tool_parameters = TOOL_DATA[edit_mode].parameters
		for parameter_key in tool_parameters.keys():
			add_parameter_slider(edit_mode, parameter_key, tool_parameters[parameter_key])

func add_parameter_slider(edit_mode, parameter_key, parameter_data):
	var slider = ParameterSlider.instantiate()
	parameter_container.add_child(slider)
	slider.init(parameter_data)
	
	if not parameter_sliders.has(edit_mode):
		parameter_sliders[edit_mode] = {}
	
	parameter_sliders[edit_mode][parameter_key] = slider

func get_tool_parameter_value(edit_mode, parameter_name):
	if (parameter_sliders
		and parameter_sliders.has(edit_mode)
		and parameter_sliders[edit_mode].has(parameter_name)):
		return parameter_sliders[edit_mode][parameter_name].get_value()
	
	return null

func set_tool_parameter_value(edit_mode, parameter_name, new_value):
	parameter_sliders[edit_mode][parameter_name].set_value(new_value)
