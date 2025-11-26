extends Node2D

@export var level_data: LevelData

var pieces_layer: TileMapLayer
var background_layer: TileMapLayer
var highlight_layer: TileMapLayer
const BACKGROUND_SOURCE = 0
const PIECE_SOURCE = 1
var active_piece: Piece


func _ready() -> void:
	# test code	
	#var source_id: int = 1
	pieces_layer = $PiecesLayer
	background_layer = $BackgroundLayer
	highlight_layer = $HighlightLayer

	#var pieces_ts: TileSet = pieces_layer.tile_set
	#var pieces_source := pieces_ts.get_source(source_id) as TileSetAtlasSource
	#var tile_count: int = pieces_source.get_tiles_count()
	#print("tile_count =", tile_count)
	# for i in tile_count:
	# 	var pieces_atlas_coords: Vector2i = pieces_source.get_tile_id(i)
	# 	print("tile", i, "atlas coords:", pieces_atlas_coords)

	# 	pieces_layer.set_cell(Vector2i(i, 0), source_id, pieces_atlas_coords, 0)

	# var h_ts: TileSet = highlight_layer.tile_set
	# var h_source := h_ts.get_source(source_id) as TileSetAtlasSource
	# var h_tile_count: int = h_source.get_tiles_count()
	# print("h_tile_count =", h_tile_count)
	# for i in h_tile_count:
	# 	var h_atlas_coords: Vector2i = h_source.get_tile_id(i)
	# 	print("tile", i, "atlas coords:", h_atlas_coords)

	# 	highlight_layer.set_cell(Vector2i(i, 4), source_id, h_atlas_coords, 0)
	
	# for i in range(level_data.width):
	# 	for j in range(level_data.height):
	# 		background_layer.set_cell(Vector2i(i, j), BACKGROUND_SOURCE, Vector2i(0, 0), 0)

	var test_piece: Piece = Piece.new(level_data.shapes[5], Vector2i(3, 3))
	print(test_piece.cells)
	place_background()
	place_piece(test_piece)

	active_piece = test_piece

func place_background() -> void:
	for i in range(level_data.width):
		for j in range(level_data.height):
			background_layer.set_cell(Vector2i(i, j), BACKGROUND_SOURCE, Vector2i(0, 0), 0)

func place_piece(piece: Piece) -> void:
	for cell in piece.cells:
		var y_offset = piece.position[0]
		var x_offset = piece.position[1]
		pieces_layer.set_cell(Vector2i(cell[0] + y_offset, cell[1] + x_offset), PIECE_SOURCE, Vector2i(0, 0), 0)
	
func remove_piece(piece: Piece) -> void:
	var y_offset = piece.position[0]
	var x_offset = piece.position[1]
	for cell in piece.cells:
		pieces_layer.erase_cell(Vector2i(cell[0] + y_offset, cell[1] + x_offset))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("rotate_left"):
		rotate_piece(active_piece, Piece.Rotation.LEFT)
	if event.is_action_pressed("rotate_right"):
		rotate_piece(active_piece, Piece.Rotation.RIGHT)

func rotate_piece(piece: Piece, rotation_direction: Piece.Rotation):
	remove_piece(piece)
	print("OLD", piece.cells)
	
	var new_cell_data = piece.rotate_around_cell(1, rotation_direction)
	var new_cells: Array[Vector2i] = new_cell_data[0]
	var new_position: Vector2i = new_cell_data[1]
	piece.cells = new_cells.duplicate()
	piece.position = new_position
	
	place_piece(piece)
	print("NEW", piece.cells)
	place_piece(piece)
