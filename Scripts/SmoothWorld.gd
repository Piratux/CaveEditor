extends Node

var base_terraform_distance = 1000
var terraform_distance = base_terraform_distance

var edit_min_scale = 2
var edit_max_scale = 40
var edit_scale = 10 # default scale

var blend_ball_min_range = 1
var blend_ball_max_range = 15
var blend_ball_range = 3 # default range

var edit_indicator_is_visible = true

var left_mouse_button_held = false
var right_mouse_button_held = false

var draw_speed = (2.0 / 60.0); # how often edits can be made for terrain in seconds
var draw_speed_accumulate_delta = 0.0;
var can_edit_terrain = true;

var mouse_captured = false
var just_started_capturing_mouse = false

enum EDIT_MODE {SPHERE, CUBE, BLEND_BALL}
var edit_mode = EDIT_MODE.SPHERE

@onready var voxel_tool = get_node("VoxelTerrain").get_voxel_tool()
@onready var camera = get_node("Camera3D")
@onready var edit_indicators = get_node("EditIndicators")
@onready var sphere_edit_indicator = get_node("EditIndicators/SphereEdit")
@onready var cube_edit_indicator = get_node("EditIndicators/CubeEdit")

@onready var tool_info = get_node("CanvasLayer/ToolInfo")
@onready var tool_select = get_node("CanvasLayer/ToolInfo/MarginContainer/VBoxContainer/ToolSelect")

func _ready():
	voxel_tool.sdf_scale = 0.3
	
	set_edit_mode(EDIT_MODE.SPHERE)
	set_edit_scale(edit_scale)
	set_blend_ball_strength(blend_ball_range)

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()

func _unhandled_input(event):
	if (event is InputEventMouseButton and 
		(event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and
		!mouse_captured):
		
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
		just_started_capturing_mouse = true

func _input(event):
	if not mouse_captured:
		return
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if just_started_capturing_mouse:
					if event.pressed == false:
						just_started_capturing_mouse = false
				else:
					if event.button_index == MOUSE_BUTTON_LEFT:
						left_mouse_button_held = event.pressed
					else:
						right_mouse_button_held = event.pressed
					
					if event.pressed and Input.is_action_pressed("CTRL"):
						update_terraforming()
			
			MOUSE_BUTTON_WHEEL_UP:
				if not Input.is_action_pressed("ALT"):
					set_edit_scale(edit_scale + 1)
			
			MOUSE_BUTTON_WHEEL_DOWN:
				if not Input.is_action_pressed("ALT"):
					set_edit_scale(edit_scale - 1)
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					mouse_captured = false
				KEY_SPACE:
					edit_indicator_is_visible = not edit_indicator_is_visible
					edit_indicators.visible = edit_indicator_is_visible
				KEY_1:
					set_edit_mode(EDIT_MODE.SPHERE)
				KEY_2:
					set_edit_mode(EDIT_MODE.CUBE)
				KEY_3:
					set_edit_mode(EDIT_MODE.BLEND_BALL)
	
	update_edit_sphere()

func parameter_slider_changed(_name, value):
	if _name == "Edit Scale":
		set_edit_scale(value)
	elif _name == "Strength":
		set_blend_ball_strength(value)

func set_edit_scale(value):
	edit_scale = clamp(value, edit_min_scale, edit_max_scale)
	tool_info.edit_scale_slider.get_node("HSlider").value_changed(edit_scale)
	update_edit_sphere()

func set_blend_ball_strength(value):
	blend_ball_range = clamp(value, blend_ball_min_range, blend_ball_max_range)
	tool_info.blend_ball_strength_slider.get_node("HSlider").value_changed(blend_ball_range)

func set_edit_mode(new_edit_mode):
	var edit_mesh = edit_indicators.get_child(new_edit_mode)
	if edit_mesh:
		edit_mode = new_edit_mode
		for c in edit_indicators.get_children():
			c.visible = false
		edit_mesh.visible = true
		
		tool_select.selected = new_edit_mode
		
		tool_info.blend_ball_strength_slider.visible = (new_edit_mode == EDIT_MODE.BLEND_BALL)

func update_draw_timer(delta):
	if draw_speed_accumulate_delta > draw_speed:
		can_edit_terrain = true;
	else:
		draw_speed_accumulate_delta += delta;

func update_terraforming():
	if not can_edit_terrain:
		return
	
	if left_mouse_button_held:
		can_edit_terrain = false
		draw_speed_accumulate_delta = 0.0
		try_place_block()
	elif right_mouse_button_held:
		can_edit_terrain = false
		draw_speed_accumulate_delta = 0.0
		try_break_block()

func get_pointed_voxel():
	var origin = camera.get_global_transform().origin
	var forward = -camera.get_transform().basis.z.normalized()
	var hit = voxel_tool.raycast(origin, forward, terraform_distance)
	return hit

func update_edit_sphere():
	if not edit_indicator_is_visible:
		return
	
	terraform_distance = base_terraform_distance * edit_scale
	
	var hit = get_pointed_voxel()
	if hit:
		var pos = Vector3(hit.position)
		edit_indicators.visible = true
		edit_indicators.global_position = pos
		edit_indicators.scale = Vector3(edit_scale, edit_scale, edit_scale)
	else:
		edit_indicators.visible = false

func try_break_block():
	var hit = get_pointed_voxel()
	if hit:
		var hit_pos = Vector3(hit.position)
		
		if edit_mode == EDIT_MODE.SPHERE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos -= forward * (edit_scale - 2)
			voxel_tool.value = 0
			voxel_tool.mode = VoxelTool.MODE_REMOVE
			voxel_tool.do_sphere(hit_pos, edit_scale)
		
		elif edit_mode == EDIT_MODE.CUBE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos -= forward * (edit_scale - 2)
			voxel_tool.value = 0
			voxel_tool.mode = VoxelTool.MODE_REMOVE
			var offset = Vector3(edit_scale, edit_scale, edit_scale)
			voxel_tool.do_box(hit_pos - offset, hit_pos + offset)
		
		elif edit_mode == EDIT_MODE.BLEND_BALL:
			voxel_tool.smooth_sphere(hit_pos, edit_scale, blend_ball_range)
		
		update_edit_sphere()

func try_place_block():
	var hit = get_pointed_voxel()
	if hit:
		var hit_pos = Vector3(hit.position)
		
		if edit_mode == EDIT_MODE.SPHERE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos += forward * (edit_scale - 2)
			voxel_tool.value = 1
			voxel_tool.mode = VoxelTool.MODE_ADD
			voxel_tool.do_sphere(hit_pos, edit_scale)
		
		elif edit_mode == EDIT_MODE.CUBE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos += forward * (edit_scale - 2)
			voxel_tool.value = 1
			voxel_tool.mode = VoxelTool.MODE_ADD
			var offset = Vector3(edit_scale, edit_scale, edit_scale)
			voxel_tool.do_box(hit_pos - offset, hit_pos + offset)
		
		elif edit_mode == EDIT_MODE.BLEND_BALL:
			voxel_tool.smooth_sphere(hit_pos, edit_scale, blend_ball_range)
		
		update_edit_sphere()
