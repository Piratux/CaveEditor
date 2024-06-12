extends Button

@onready var mesh_import_dialog = get_node("../../../../../../MeshImportDialog")

func _on_pressed():
	mesh_import_dialog.visible = true
