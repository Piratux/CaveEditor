extends Button

func _on_pressed():
	get_tree().get_first_node_in_group("HelpWindow").toggle_visibility()
