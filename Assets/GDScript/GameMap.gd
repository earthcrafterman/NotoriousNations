class_name GameMap
extends Node

@export var npth_soil_cover_map: NodePath
var scmp_soil_cover_map: SoilCoverMap

@export var npth_unit_map: NodePath
var unmp_unit_map: UnitMap

@export var npth_hmenu: NodePath
var hmnu_hmenu: HMenu

const S_EXPORT_PATH = "res://Assets/JSON/Maps/Exported Map/map.json"

func _ready() -> void:
	scmp_soil_cover_map = get_node(npth_soil_cover_map)
	unmp_unit_map = get_node(npth_unit_map)
	hmnu_hmenu = get_node(npth_hmenu)
	
	Globals.unit_position_update.connect(on_unit_position_update)

	print("hello world")

	for folder in [
		[
			"SoilCovers",
			preload("res://Assets/GDScript/Tiles/SoilCoverType.gd"),
			"SoilCover",
			"soil_cover"
		],
		[
			"UnitTypes",
			preload("res://Assets/GDScript/Units/UnitType.gd"),
			"UnitType",
			"unit"
		]
		# [
		# 	"Religions"
		#
		# ],
	]:
		JSONTypeCraweler.parse_folder("res://Assets/JSON/", folder)

	# SoilCoverJSON.parse_folder()
	# UnitTypeJSON.parse_folder()

	MapJSON.a_map_parse_folder()

	scmp_soil_cover_map.on_new_soilcover_atlas()
	unmp_unit_map.on_new_unit_atlas()

	# temporary implemenetation, to later be replaced with a Map Selector
	# set map_map to Test Map 1 from globals
	Globals.map_map = Globals._g_dict_maps["Test Map 1"]
	
	# load map_map
	load_map()
	Globals.tile_cursor_update.emit()

func on_unit_position_update(to : Tile, from : Tile):
	populate_tile(to.i_x,to.i_y)
	populate_tile(from.i_x,from.i_y)

# function called after _input if the input event that caused it to be called has yet to be flagged as handled
func _unhandled_input(event):
	# if the left mouse button is pressed
	if event is InputEventMouseButton and event.pressed and \
			event.get_button_index() == MOUSE_BUTTON_LEFT :
		
		# get the local position of the mouse position
		var v_event_pos = scmp_soil_cover_map.to_local(scmp_soil_cover_map.get_global_mouse_position())

		# convert the local position of the mouse position to the map coordinates
		var v_tile_pos = scmp_soil_cover_map.world_to_map(v_event_pos)
		
		if (Globals.map_map._dict_tiles.has(str(v_tile_pos.x) + "," + str(v_tile_pos.y))):
			Globals.vc2i_tile_cursor = v_tile_pos
			Globals.tile_cursor_update.emit()
		
		# set cell at v_tile_pos to the next index in the cycle
		#scmp_soil_cover_map.set_cell(0,v_tile_pos,0,vc2i_cycle(scmp_soil_cover_map.get_cell_atlas_coords(0,v_tile_pos,false)),0)
		
		
	# if the right mouse button is pressed
	if event is InputEventMouseButton and event.pressed and \
			event.get_button_index() == MOUSE_BUTTON_RIGHT :
		# get the local position of the mouse position
		var v_event_pos = scmp_soil_cover_map.to_local(scmp_soil_cover_map.get_global_mouse_position())
		
		# convert the local position of the mouse position to the map coordinates
		var v_tile_pos = scmp_soil_cover_map.world_to_map(v_event_pos)
		
		hmnu_hmenu.move_selected_unit(v_tile_pos)

# cycle cell index
# v_coords vector2i representing the current cell coordinates
func vc2i_cycle(v_index: Vector2i) -> Vector2i:
	if v_index.x < scmp_soil_cover_map.get_tileset().get_source(0).get_atlas_grid_size().x:
		return Vector2i(v_index.x+1,v_index.y)
	else:
		if (v_index.y < scmp_soil_cover_map.get_tileset().get_source(0).get_atlas_grid_size().y):
			return Vector2i(0,v_index.y+1)
		else:
			return Vector2i(0,0)

# function called upon input event
func _input(event: InputEvent) -> void:
	# if the save button defined in Project->Project Settings->Input Map is pressed down
	if event.is_action_pressed("save"):
		# save map_map
		save_map()

func populate_tile(x : int, y : int):
	var a_unit_units : Array[Unit] = Globals.map_map.dict_tiles_from_int(x,y).a_unit_units
	var i_i : int = 0
	var i_x_offset : int 
	var i_y_offset : int 
	var i_atlas_x : int
	var i_atlas_y : int
	
	for i_x in range(0,8,1):
		for i_y in range(0,4,1):
			unmp_unit_map.set_cell(0,Vector2i(x*8+i_x,y*8+4+i_y),-1,Vector2i(-1,-1),-1)
	
	for unit_unit in a_unit_units:
		if i_i>32:
			break
		i_x_offset = i_i / 8
		i_y_offset = i_i % 4
		i_atlas_x = unit_unit.untp_unit_type.i_x
		i_atlas_y = unit_unit.untp_unit_type.i_y
		unmp_unit_map.set_cell(0,Vector2i(x*8+i_x_offset,y*8+4+i_y_offset),0,Vector2i(i_atlas_x,i_atlas_y),0)
		i_i+=1

# function to load map_map into this tilemap
func load_map() -> void:
	# for every column(?) in map_map
	for x in range(Globals.map_map._i_x):
		# for every row(?) in map_map
		for y in range(Globals.map_map._i_y):
			# set the cell at (x,y) to the index of this node's tileset with the same name as s_soil_cover_name
			var scvr_soil_cover : SoilCoverType = Globals.map_map.dict_tiles_from_int(x,y)._scvr_soil_cover_type
			var i_atlas_x : int = scvr_soil_cover.i_x
			var i_atlas_y : int = scvr_soil_cover.i_y
			
			scmp_soil_cover_map.set_cell(0,Vector2i(x,y),0,Vector2i(i_atlas_x,i_atlas_y),0)

			populate_tile(x,y)

# save map
func save_map() -> void:
	# dictionary for storing the current map's contents in
	var dict_map = {}
	var tempdict : Dictionary = {}
	
	# string for temporary storage of coordinates
	var s_coordinates

	# temporary implementation, to be replaced with a prompt to enter a name later
	# set the s_name key/value pair of the map to be exported
	dict_map["s_name"] = "Exported Map"

	# set the s_type key/value pair of the map to be exported
	dict_map["s_type"] = "Map"

	# gets the rect within which all non-null tiles exist
	var rect_map = scmp_soil_cover_map.get_used_rect()

	# get the length of rect_map
	var i_x = rect_map.size.x

	# get the height of rect_map
	var i_y = rect_map.size.y

	# set the i_x key/value pair of the map to be exported
	dict_map["i_x"]=i_x

	# set the i_y key/value pair of the map to be exported to an empty dictionary
	dict_map["i_y"]=i_y

	# set the dict_tiles key/value pair of the map to be exported to an empty dictionary
	dict_map["dict_tiles"]={}

	# for each column(?) in rect_map
	for x in range(i_x):
	# for each row(?) in rect_map
		for y in range(i_y):
			# create a string containing the coordinate of the current tile
			s_coordinates = str(x) + "," + str(y)
			# set the s_coordinates key/value pair of the dict_tiles key/value pair to an empty dictionary
			dict_map["dict_tiles"][s_coordinates] = {}
			# temporary implementation, to be replaced with the ingame name of the tile
			# set the s_name key/value pair of the s_coordinates key/value pair to Barcelona
			dict_map["dict_tiles"][s_coordinates]["s_name"] = "Barcelona"
			# set the s_type of the s_coordinates key/value pair to Tile
			dict_map["dict_tiles"][s_coordinates]["s_type"] = "Tile"
			
			# set the s_soil_cover of the s_coordinates key/value pair to the name of the index of (x,y)'s tile in this node's tileset
			var s_soil_cover_name : String = Globals.map_map.dict_tiles_from_int(x,y)._scvr_soil_cover_type.s_name

			dict_map["dict_tiles"][s_coordinates]["s_soil_cover"] = s_soil_cover_name
			
			for unit_unit in Globals.map_map.dict_tiles_from_int(x,y).a_unit_units:
				tempdict = {}
				tempdict[Globals.s_name_key] = unit_unit.s_name
				tempdict["s_owner"] = unit_unit.s_owner
				tempdict["s_unit_type"] = unit_unit.untp_unit_type.s_name
				if not tempdict == {}:
					if not dict_map["dict_tiles"][s_coordinates].has("a_dict_s_units"):
						dict_map["dict_tiles"][s_coordinates]["a_dict_s_units"] = []
					dict_map["dict_tiles"][s_coordinates]["a_dict_s_units"].append(tempdict)

	# write dict_map to a json file at s_export_path
	JSONWriter.write_json(S_EXPORT_PATH,dict_map)
