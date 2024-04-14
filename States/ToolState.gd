class_name ToolState
extends Resource

# TODO: preferably this should store just data, and not sliders that store data, but then
# there are issues of dynamically creating signals and restricting valid values
var _parameter_sliders = {} # PRIVATE

func get_tool_parameter_value(edit_mode, parameter_name):
	if (_parameter_sliders.has(edit_mode)
		and _parameter_sliders[edit_mode].has(parameter_name)):
		return _parameter_sliders[edit_mode][parameter_name].get_value()
	
	return null

func set_tool_parameter_value(new_value, edit_mode, parameter_name):
	_parameter_sliders[edit_mode][parameter_name].set_value(new_value)
