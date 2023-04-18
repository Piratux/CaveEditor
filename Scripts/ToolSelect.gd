extends OptionButton


func _on_item_selected(index):
	get_node("/root/SmoothWorld").set_edit_mode(index)
