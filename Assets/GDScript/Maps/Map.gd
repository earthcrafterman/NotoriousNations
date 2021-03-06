class_name Map
extends Item

# String containing the Tile key
const s_tile_type_name : String = "Tile"

# int containing the width of this map
var _i_x: int = -1:
	get: return _i_x

# int containing the height of this map
var _i_y: int = -1:
	get: return _i_y

# Dictionary containing the tiles within this map
var _dict_tiles: Dictionary = {}:
	get: return _dict_tiles

# getter function for individual tiles in dict_tiles
# s_coordinates: a string formatted as [x],[y]
# returns the tile at the given coordinates
func dict_tiles_from_string(s_coordinates) -> Tile:
	if _dict_tiles.has(s_coordinates):
		return _dict_tiles[s_coordinates]
	else: return null

# getter function for individual tiles in dict_tiles
# x: integer containing the x coordinate of the tile to get
# y: integer containing the y coordinate of the tile to get
# returns the tile at the given coordinates
func dict_tiles_from_int(x: int, y: int) -> Tile:
	if _dict_tiles.has(str(x) + "," + str(y)):
		return _dict_tiles[str(x) + "," + str(y)]
	else: return null

# called upon initialization
# name: a string of the name of the map
# type: a string of the type of the map
# x: an integer of the width of the map
# y: an integer of the height of the map
# tiles: a dictionary of the tiles that comprise the map
# returns void
func _init(name: String,type: String,x: int,y: int,tiles: Dictionary) -> void:
	super(name,type)

	# set the map's width and height
	_i_x=x
	_i_y=y

	# generate the map's tiles
	_dict_tiles=dict_generate_tiles(tiles)

# generate tiles from a dict of tiles

# returns a Dictionary of the generated tiles
func dict_generate_tiles(tiles: Dictionary) -> Dictionary:
	var dict_temp_tiles = {}
	var a_dict_s_units = []
	var dict_temp_entry
	var s_coordinate = ""
	for x in range(_i_x):
		for y in range(_i_y):
			s_coordinate = str(x) + "," + str(y)

			if not tiles.has(s_coordinate):
				push_warning("tile at " + s_coordinate + "is missing from map")
				return {}

			dict_temp_entry = tiles[s_coordinate]

			if not JSONReader.dict_validate_json(dict_temp_entry,"map coordinate " + s_coordinate,s_tile_type_name):
				return {}

			dict_temp_tiles[s_coordinate] = Tile.new ({
				"s_name": JSONReader.get_json_entry(dict_temp_entry,Globals.s_name_key,"map coordinate " + s_coordinate,Globals.s_missing_name),
				"s_type": s_tile_type_name,
				"i_x": x,
				"i_y": y,
				"soil_cover_type": Globals._g_dict_soil_cover_types[JSONReader.get_json_entry(dict_temp_entry,"s_soil_cover","map coordinate " + s_coordinate,"Grassland")]
			})


			a_dict_s_units = JSONReader.get_json_entry(dict_temp_entry,"a_dict_s_units","map coordinate " + s_coordinate,[])

			if a_dict_s_units != []:
				for dict_s_unit in a_dict_s_units:
					Unit.new(JSONReader.get_json_entry(dict_s_unit,Globals.s_name_key,"map coordinate " + s_coordinate,"Unit"),
					"Unit",
					JSONReader.get_json_entry(dict_s_unit,"s_owner","map coordinate " + s_coordinate,"no owner"),
					Globals._g_dict_unit_types[JSONReader.get_json_entry(dict_s_unit,"s_unit_type","map coordinate " + s_coordinate,null)],
					dict_temp_tiles[s_coordinate])
	return dict_temp_tiles
