extends OptionButton

@export var edit_mode_state: EditModeState

const TOOL_DATA = preload("res://Scripts/ToolData.gd").TOOL_DATA

func _ready():
	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	
	for edit_mode_data in TOOL_DATA.values():
		add_item(edit_mode_data.name)

func edit_mode_updated(index):
	selected = index

func _on_item_selected(index):
	edit_mode_state.edit_mode = index
