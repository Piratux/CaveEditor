class_name EditModeState
extends Resource

const EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE

signal edit_mode_updated(new_edit_mode)

var edit_mode = EDIT_MODE.SPHERE : set = set_edit_mode

func set_edit_mode(value):
	# TODO: enforce valid value through enums
	var total_tools = EDIT_MODE.keys().size()
	if not (value >= 0 && value < total_tools):
		print("Invalid edit mode selected")
		return
		
	edit_mode = value
	edit_mode_updated.emit(edit_mode)
