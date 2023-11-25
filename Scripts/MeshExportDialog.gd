extends FileDialog


func _on_export_pressed():
	visible = !visible


func _on_file_selected(_path):
	visible = false
