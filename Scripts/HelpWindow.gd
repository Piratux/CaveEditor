extends Control

# TODO: figure out why this doesn't work when 
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_H:
					visible = not visible

func _on_button_pressed():
	visible = not visible
