extends RefCounted

# Note: When project is exported, only ".import" files are in res:// directory.
# However, loading say ".png", instead of ".png.import" still works

var external_obj_folder = ".editor/Objects"
var internal_obj_folder = "res://Objects"
var obj_file_extension = "obj"

func _get_external_file_paths(folder, file_extension):
	var path_list = []
	var dir = DirAccess.open(folder)
	if !dir:
		print("INFO: Could not open folder: ", folder)
		return path_list
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		print("file name found: " + file_name)
		
		if !dir.current_is_dir() and file_name.ends_with("." + file_extension):
			path_list.push_back(DirAccess.open(".").get_current_dir() + "/" + folder + "/" + file_name)
			print("Adding file: " + file_name)
		file_name = dir.get_next()
	
	return path_list

func _get_internal_file_paths(folder, file_extension):
	var path_list = []
	var dir = DirAccess.open(folder)
	if !dir:
		print("INFO: Could not open folder: ", folder)
		return path_list
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		print("file name found: " + file_name)
		# When project is exported, only ".import" files are in res:// directory.
		# However, loading say ".obj", instead of ".obj.import" still works
		if !dir.current_is_dir() and file_name.ends_with("." + file_extension + ".import"):
			file_name = file_name.replace(".import", "")
			path_list.push_back(folder + "/" + file_name)
			print("Adding file: " + file_name)
		file_name = dir.get_next()
	
	return path_list

func get_external_obj_file_paths():
	return _get_external_file_paths(external_obj_folder, obj_file_extension)

func get_internal_obj_file_paths():
	return _get_internal_file_paths(internal_obj_folder, obj_file_extension) # we add internal objs for demo purposes
