extends Control

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_H:
					visible = not visible

func toggle_visibility():
	visible = not visible
