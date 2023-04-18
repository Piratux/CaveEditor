extends PanelContainer

var ParameterSlider = preload("res://Scenes/ParameterSlider.tscn")

@onready var container = get_node("MarginContainer/VBoxContainer")

var edit_scale_slider = null
var blend_ball_strength_slider = null


func _ready():
	init_parameter_sliders()

func init_parameter_sliders():
	var world = get_node("/root/SmoothWorld")
	edit_scale_slider = add_parameter_slider("Edit Scale", world.edit_min_scale, world.edit_max_scale)
	blend_ball_strength_slider = add_parameter_slider("Strength", world.blend_ball_min_range, world.blend_ball_max_range)

func add_parameter_slider(_name, min_value, max_value):
	var slider = ParameterSlider.instantiate()
	slider.get_node("Name").text = _name
	slider.get_node("Value").text = str(min_value)
	slider.get_node("HSlider").min_value = min_value
	slider.get_node("HSlider").max_value = max_value
	container.add_child(slider)
	return slider
