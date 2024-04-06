extends Node

var debug_draw_stats_enabled = false

var process_stats = {}
var displayed_process_stats = {}
var time_before_display_process_stats = 1.0

const process_stat_names = [
]

var voxel_terrain = null
var voxel_tool = null
var camera = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if debug_draw_stats_enabled:
		draw_debug_voxel_stats(delta)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_P:
					debug_draw_stats_enabled = !debug_draw_stats_enabled

func draw_debug_voxel_stats(delta):
	if not voxel_terrain:
		return
	
	var stats = voxel_terrain.get_statistics()
	
	DDD.set_text("FPS", Engine.get_frames_per_second())
	DDD.set_text("Static memory", _format_memory(OS.get_static_memory_usage()))
	
	var global_stats = VoxelEngine.get_stats()
	for p in global_stats:
		var pool_stats = global_stats[p]
		for k in pool_stats:
			DDD.set_text(str(p, "_", k), pool_stats[k])
	
	for k in process_stat_names:
		var v = stats[k]
		if k in process_stats:
			process_stats[k] = max(process_stats[k], v)
		else:
			process_stats[k] = v
	
	time_before_display_process_stats -= delta
	if time_before_display_process_stats < 0:
		time_before_display_process_stats = 1.0
		displayed_process_stats = process_stats
		process_stats = {}
	
	for k in displayed_process_stats:
		DDD.set_text(k, displayed_process_stats[k])
	
	DDD.set_text("POS", Vector3i(camera.position))
	DDD.set_text("SDF", voxel_tool.get_voxel_f(camera.position))
	DDD.set_text("LOD count", voxel_terrain.lod_count) # TODO: make it work for VoxelTerrain too
#	_terrain.debug_set_draw_enabled(true)
#	_terrain.debug_set_draw_flag(VoxelLodTerrain.DEBUG_DRAW_MESH_UPDATES, true)

func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")
