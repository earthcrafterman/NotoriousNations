class_name JSONTypeCraweler
extends RefCounted

# parses a folder, more
# folder is an array with a string in the fist index, and a class in the second index, and the s_type in the thrid
static func parse_folder(s_base_path: String, folder: Array) -> void:
	var imge_atlas : Image
	var a_imge_images : Array[Image] = []
	var a_dict_jsons : Array[Dictionary] = []
	var a_s_paths : Array[String] = []
	var a_s_valid_paths : Array[String] = []
	var imge_temp_image : Image
	var i_err : int
	var s_image_path : String
	const i_resolution : int = 32

	print(s_base_path, folder)

	# dictionary for temporary storage of json files
	var dict_json : Dictionary

	# buffer for temporary storage of newly created things
	var buffer

	var defaults = JSONReader.read_json(s_base_path + folder[0] + "/default.json")

	if defaults == null:
		push_warning("defaults not found")
		return

	# get all files in s_map_folder for iteration
	a_s_paths = FolderCrawler.a_s_crawl_folder(s_base_path + folder[0] + "/")

	print("folder crawel successful")

	# iterate through all paths in a_s_paths, except default.json
	for s_path in a_s_paths:
		print(s_path)

		if (not s_path.to_lower().ends_with(".json") or s_path.to_lower().ends_with("default.json")):
			continue
		# read the json markdown in the unit type .json at s_path as a dictionary for creating a new unit type from
		dict_json = JSONReader.read_json(s_path)

		print("Has name: ", dict_json .has("s_name"))

		# print(dict_json, s_path)

		if dict_json == null:
			push_warning("file at " + s_path + " is not a json file")
			continue


		# skip this file if it's not a valid json file
		if not JSONReader.dict_validate_json(dict_json, s_path, folder[2]):
			push_warning("file at " + s_path + " is not a json file")
			continue

		# create a new image
		imge_temp_image = Image.new()

		# generate the path to the .png file
		s_image_path = s_path.trim_suffix(".json")
		s_image_path += ".png"

		# load .png file
		i_err = imge_temp_image.load(s_image_path)

		# skip this file if its corresponding .png file is not a valid .png file
		if i_err != OK:
			push_warning("error parsing png file at " + s_path)
			continue

		# skip this file if its resolution is not the right size
		if  imge_temp_image.get_width()  != i_resolution or \
			imge_temp_image.get_height() != i_resolution:
			push_warning("image at " + s_image_path + "is not 32x32")
			continue

		# append image to the arrays
		a_imge_images.append(imge_temp_image)
		a_dict_jsons.append(dict_json)
		a_s_valid_paths.append(s_path)


	print("passed the for loop of the a_s_paths")

	var i_x : int
	var i_y : int
	var i_x_pos : int
	var i_y_pos : int

	if a_imge_images.size() != a_dict_jsons.size():
		push_warning("file image array and json array are not the same size")
		return

	var i_size = a_imge_images.size()

	var i_sqrt = sqrt(i_size)

	var i_ceil = int(ceil(i_sqrt))
	var i_floor = int(floor(i_sqrt))

	i_x = i_floor
	i_y = i_floor

	if i_ceil != i_floor:
		i_x += 1
		i_y += 1

	imge_atlas = Image.new()
	imge_atlas.create(i_resolution * i_x, i_resolution * i_y, false, a_imge_images[0].get_format())

	print("pruint")

	# iterate through all paths in a_s_paths
	var i_i : int = 0
	for dict_json in a_dict_jsons:

		i_x_pos = int(floor(i_i % i_x))
		i_y_pos = int(floor(i_i / i_x))

		var dict = {}

		print(dict_json)

		for name in dict_json:
			dict[name] = JSONReader.get_json_entry(dict_json, name, a_s_valid_paths[i_i], defaults[name])



		# dict["s_name"] = (JSONReader.get_json_entry(dict_json,Globals.s_name_key,a_s_valid_paths[i_i],Globals.s_missing_name)),
		# dict["s_type"] = folder[2]

		dict["_i_x"] = i_x_pos
		dict["_i_y"] = i_y_pos

		print("test")

		buffer = folder[1].new(dict)

		imge_atlas.blend_rect(a_imge_images[i_i], Rect2(0, 0, i_resolution, i_resolution), Vector2(i_x_pos * i_resolution, i_y_pos * i_resolution))

		# register with glob_globals as a new buffer type from s_path
		Globals.b_register_JSON_thing(buffer, folder[3], a_s_valid_paths[i_i])

		i_i += 1

	Globals.b_register_JSON_atlas(imge_atlas, folder[3], s_base_path)
