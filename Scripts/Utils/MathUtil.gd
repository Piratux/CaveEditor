extends RefCounted

# Returns scaled transform based on mesh's aabb, such that mesh fits in 1x1x1 cube
func get_unit_scaled_transform_from_mesh(mesh, transform):
	var aabb = mesh.get_aabb()
	var aabb_half_size = aabb.size / 2.0
	var max_aabb_half_size_axis = max(aabb_half_size.x, aabb_half_size.y, aabb_half_size.z)
	
	var inverse_max_axis = 1.0 / max_aabb_half_size_axis
	var scaled_vector = Vector3(inverse_max_axis, inverse_max_axis, inverse_max_axis)
	return transform.scaled_local(scaled_vector)
