extends CanvasLayer


func capture_mouse(value):
	# Setting process_mode to PROCESS_MODE_DISABLED is needed to prevent
	# GUI from stealing input when mouse is hidden.
	# This is noticable when opening worlds menu
	
	# 'process_mode' disables pressing on UI elements, but still keeps mouse hover effect.
	# 'set_ui_element_mouse_filter' disables mouse hover effect.
	if value:
		# We need it to be "MOUSE_MODE_CAPTURED" instead of "MOUSE_MODE_CONFINED_HIDDEN",
		# otherwise relative mouse movement won't work properly
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_tree().get_first_node_in_group("WorldManagerWindow").process_mode = Node.PROCESS_MODE_DISABLED
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().get_first_node_in_group("WorldManagerWindow").process_mode = Node.PROCESS_MODE_INHERIT
