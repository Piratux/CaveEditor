extends HSlider


@onready var name_label = get_node("../Name")
@onready var value_label = get_node("../Value")

func _on_value_changed(new_slider_value):
	var slider_name = name_label.text
	get_node('/root/SmoothWorld').parameter_slider_changed(slider_name, new_slider_value)

func value_changed(new_value):
	value = new_value
	value_label.text = str(new_value)
