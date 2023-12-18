extends Control

@onready var item_list = get_node("VBoxContainer/ScrollContainer/MarginContainer/ItemList")
@onready var world_container = get_node("VBoxContainer/ScrollContainer/MarginContainer/VBoxContainer")
@onready var saver = get_node("../../Saver")
@onready var export_dialog = get_node("MeshExportDialog")
@onready var delete_error_dialog = get_node("DeleteErrorDialog")

# TODO: remove this (and vboxcontainer), and use world_idx directly from item list
var selected_world_idx = null


func _on_manage_worlds_button_pressed():
	visible = !visible

func add_new_world(world_name, add_to_saver = false):
	world_name = make_world_name_unique(world_name)
	
	item_list.add_item(world_name)
	
	if add_to_saver:
		saver.add_new_world(world_name)

func is_selected_world_idx_valid():
	if not item_list.is_anything_selected():
		return false
	
	if selected_world_idx == null:
		return false
	
	if selected_world_idx < 0:
		return false
	
	if selected_world_idx >= item_list.get_item_count():
		return false
	
	return true

func get_currently_selected_world_name():
	if not is_selected_world_idx_valid():
		return null
	
	return item_list.get_item_text(selected_world_idx)

func set_currently_selected_world_name(new_name):
	if not is_selected_world_idx_valid():
		return
	
	new_name = make_world_name_unique(new_name)
	
	var old_name = item_list.get_item_text(selected_world_idx)
	item_list.set_item_text(selected_world_idx, new_name)
	saver.rename_world(old_name, new_name)

func make_world_name_unique(world_name):
	var name_list = []
	for i in item_list.get_item_count():
		name_list.push_back(item_list.get_item_text(i))
	
	var new_name = world_name
	
	# Check if the string is in the array
	if name_list.find(world_name) != -1:
		var suffix_number = 2
		
		# Keep incrementing the suffix until a unique string is found
		while name_list.find(new_name) != -1:
			new_name = world_name + str(suffix_number)
			suffix_number += 1
	
	return new_name

func _on_item_list_item_selected(index):
	selected_world_idx = index


# TODO: add are you sure confirmation
func _on_delete_pressed():
	if not is_selected_world_idx_valid():
		return
	
	if item_list.get_item_count() == 1:
		delete_error_dialog.visible = true
		return
	
	var old_name = item_list.get_item_text(selected_world_idx)
	item_list.remove_item(selected_world_idx)
	selected_world_idx = null
	saver.delete_world(old_name)


func _on_close_pressed():
	visible = false


func _on_load_pressed():
	if not is_selected_world_idx_valid():
		return
	
	var world_name = item_list.get_item_text(selected_world_idx)
	saver.load_world_by_name(world_name)


func _on_mesh_export_dialog_file_selected(path):
	if not is_selected_world_idx_valid():
		return
	
	saver.export_world_mesh(path)


func _on_export_mesh_pressed():
	if export_dialog.visible == false:
		if not is_selected_world_idx_valid():
			return
		
		# Needed because mesh is constructed from loaded chunks only
		var world_name = item_list.get_item_text(selected_world_idx)
		saver.load_world_by_name(world_name)
	
	export_dialog.visible = !export_dialog.visible
