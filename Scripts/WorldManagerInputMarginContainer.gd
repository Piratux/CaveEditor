extends MarginContainer

@onready var world_manager = get_node("../..")
@onready var line_edit = get_node("VBoxContainer/LineEdit")

enum EDIT_MODE {CREATE, RENAME}
var edit_mode = EDIT_MODE.CREATE

func _on_create_pressed():
	edit_mode = EDIT_MODE.CREATE
	line_edit.set_text("")
	visible = true

func _on_rename_pressed():
	var world_name = world_manager.get_currently_selected_world_name()
	if world_name == null:
		return
	
	edit_mode = EDIT_MODE.RENAME
	visible = true
	
	line_edit.set_text(world_name)
	
	line_edit.grab_focus()

func _on_confirm_pressed():
	var world_name = line_edit.get_text()
	if world_name.length() == 0:
		return
	
	if edit_mode == EDIT_MODE.CREATE:
		world_manager.add_new_world(world_name, true)
	elif edit_mode == EDIT_MODE.RENAME:
		world_manager.set_currently_selected_world_name(world_name)
	
	visible = false


func _on_cancel_pressed():
	visible = false
