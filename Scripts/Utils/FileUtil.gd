extends RefCounted

# Note: When project is exported, only ".import" files are in res:// directory.
# However, loading say ".png", instead of ".png.import" still works

var root_obj_folder = ".editor/Objects"
var obj_file_extension = "obj"

func _get_file_paths(folder, file_extension):
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

func get_obj_file_paths():
	return _get_file_paths(root_obj_folder, obj_file_extension)
