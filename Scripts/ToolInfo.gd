extends PanelContainer

var ParameterSlider = preload("res://Scenes/ParameterSlider.tscn")

@onready var container = get_node("MarginContainer/VBoxContainer")
@onready var world = get_node("/root/SmoothWorld")

var edit_scale_slider = null
var blend_ball_strength_slider = null
var surface_blend_extra_radius_slider = null
var edit_intensity_slider = null


func _ready():
	init_parameter_sliders()

func init_parameter_sliders():
	edit_scale_slider = add_parameter_slider("Edit Scale", world.edit_min_scale, world.edit_max_scale)
	blend_ball_strength_slider = add_parameter_slider("Strength", world.blend_ball_min_range, world.blend_ball_max_range)
	surface_blend_extra_radius_slider = add_parameter_slider("Blend Radius", world.surface_extra_radius_min_range, world.surface_extra_radius_max_range)
	edit_intensity_slider = add_parameter_slider("Intensity", world.edit_intensity_min, world.edit_intensity_max, world.edit_intensity_step)

func add_parameter_slider(_name, min_value, max_value, step = 1):
	var slider = ParameterSlider.instantiate()
	slider.get_node("Name").text = _name
	slider.get_node("Value").text = str(min_value)
	slider.get_node("HSlider").min_value = min_value
	slider.get_node("HSlider").max_value = max_value
	slider.get_node("HSlider").step = step
	if step != 1:
		slider.get_node("HSlider").rounded = false
	
	container.add_child(slider)
	return slider
