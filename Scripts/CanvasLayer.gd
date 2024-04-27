extends CanvasLayer


func capture_mouse(value):
	# 'process_mode' disables pressing on UI elements, but still keeps mouse hover effect.
	# 'set_ui_element_mouse_filter' disables mouse hover effect.
	if value:
		# We need it to be "MOUSE_MODE_CAPTURED" instead of "MOUSE_MODE_CONFINED_HIDDEN",
		# otherwise relative mouse movement won't work properly
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		process_mode = Node.PROCESS_MODE_DISABLED
		set_ui_element_mouse_filter(self, false)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		process_mode = Node.PROCESS_MODE_INHERIT
		set_ui_element_mouse_filter(self, true)

# Since Godot doesn't provide a way to disable all GUI elements when mouse is hidden
# I have to manually crawl through UI elements and disable hover effect.
func set_ui_element_mouse_filter(element, enabled):
	for child in element.get_children():
		set_ui_element_mouse_filter(child, enabled)
	
	# Some UI elements have either stop or pass, so I have to manually
	# check the element type to know what mouse filter to revert it back to
	if enabled:
		if element is BaseButton or element is Range:
			element.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		if element is BaseButton or element is Range:
			element.mouse_filter = Control.MOUSE_FILTER_IGNORE
