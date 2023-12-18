extends FileDialog


func _on_file_selected(_path):
	visible = false


func _on_export_mesh_pressed():
	visible = !visible
