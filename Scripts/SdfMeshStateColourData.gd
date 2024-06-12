const SDF_MESH_STATE = preload("res://Scripts/SdfMeshStateEnum.gd").SDF_MESH_STATE

const SDF_MESH_STATE_COLOUR_DATA = {
	SDF_MESH_STATE.READY: {
		"colour": Color(Color.WHITE, 0.5),
		"text": "Ready",
	},
	SDF_MESH_STATE.BAKING: {
		"colour": Color(Color.ORANGE, 0.5),
		"text": "Baking",
	},
	SDF_MESH_STATE.BAKING_PARAMETERS_CHANGED: {
		"colour": Color(Color.LIME_GREEN, 0.5),
		"text": "Baking parameters changed. Click 'Bake' to rebake the mesh.",
	},
	SDF_MESH_STATE.NOT_BAKED_ONCE: {
		"colour": Color(Color.RED, 0.5),
		"text": "Not baked once",
	},
}
