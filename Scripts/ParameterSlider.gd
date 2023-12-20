extends HBoxContainer

@onready var name_label = get_node("Name")
@onready var value_label = get_node("Value")
@onready var slider = get_node("HSlider")

func init(parameter_data):
	name_label.text = parameter_data.name
	slider.min_value = parameter_data.min
	slider.max_value = parameter_data.max
	slider.step = parameter_data.step
	
	_on_slider_changed(parameter_data.default_value)
	slider.connect("value_changed", _on_slider_changed)

func _on_slider_changed(new_value):
	set_value(new_value)

func get_value():
	return slider.get_value()

func set_value(new_value):
	slider.set_value_no_signal(new_value)
	value_label.text = str(slider.get_value())
