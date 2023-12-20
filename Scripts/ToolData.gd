const EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE

const TOOL_DATA = {
	EDIT_MODE.SPHERE: {
		"name": "Sphere",
		"parameters": {
			"scale": {
				"name": "Scale",
				"default_value": 10,
				"min": 2,
				"max": 100,
				"step": 1,
			},
		},
	},
	EDIT_MODE.CUBE: {
		"name": "Cube",
		"parameters": {
			"scale": {
				"name": "Scale",
				"default_value": 10,
				"min": 2,
				"max": 100,
				"step": 1,
			},
		},
	},
	EDIT_MODE.BLEND_BALL: {
		"name": "Blend ball",
		"parameters": {
			"scale": {
				"name": "Scale",
				"default_value": 10,
				"min": 2,
				"max": 100,
				"step": 1,
			},
			"strength": {
				"name": "Strength",
				"default_value": 2,
				"min": 1,
				"max": 5,
				"step": 1,
			},
		},
	},
	EDIT_MODE.SURFACE: {
		"name": "Surface",
		"parameters": {
			"scale": {
				"name": "Scale",
				"default_value": 10,
				"min": 2,
				"max": 100,
				"step": 1,
			},
			"strength": {
				"name": "Strength",
				"default_value": 0.2,
				"min": 0.1,
				"max": 1.0,
				"step": 0.05,
			},
		},
	},
}
