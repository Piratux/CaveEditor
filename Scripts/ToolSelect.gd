extends OptionButton

const TOOL_DATA = preload("res://Scripts/ToolData.gd").TOOL_DATA

func _ready():
	for edit_mode_data in TOOL_DATA.values():
		add_item(edit_mode_data.name)

func _on_item_selected(index):
	get_node("/root/SmoothWorld").set_edit_mode(index)
