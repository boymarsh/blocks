extends Node2D

@export var level_data: LevelData
@onready var camera: Camera2D = $Camera2D

var pieces_layer: TileMapLayer
var background_layer: TileMapLayer
var highlight_layer: TileMapLayer
const BACKGROUND_SOURCE = 0
const PIECE_SOURCE = 1
const OUTLINE_SOURCE = 0
@export var zoom_modifier = 0.9
var active_piece: Piece
var possible_pieces: Array[Piece]
var pieces: Array[Piece]


func _ready() -> void:
	camera.make_current()
	_initialise_board()
	_fit_camera_to_board()
	
	#var test_piece: Piece = Piece.new(level_data.shapes[5], Vector2i(3, 3))
	var test_piece: Piece = possible_pieces[6]
	test_piece.position = Vector2i(3, 3)
	print(test_piece.cells)
	place_piece(test_piece)

	active_piece = test_piece

func _initialise_board() -> void:
	pieces_layer = $PiecesLayer
	background_layer = $BackgroundLayer
	highlight_layer = $HighlightLayer
	for i in range(len(level_data.shapes)):
			possible_pieces.append(Piece.new(level_data.shapes[i], Vector2i(0, 0), i))
	place_background()

func _fit_camera_to_board() -> void:
	# Tile size in pixels
	var tile_size: Vector2 = Vector2(pieces_layer.tile_set.tile_size)

	# Board size in pixels
	var board_px_size := Vector2(
		level_data.width * tile_size.x,
		level_data.height * tile_size.y
	)

	# Center the camera on the board
	camera.position = board_px_size / 2.0

	# Viewport size in pixels
	var viewport_size: Vector2 = get_viewport_rect().size

	var zoom_factor: float = min(
		viewport_size.x / board_px_size.x,
		viewport_size.y / board_px_size.y
	)
	zoom_factor *= zoom_modifier
	camera.zoom = Vector2(zoom_factor, zoom_factor)
	
	
func place_background() -> void:
	for i in range(level_data.width):
		for j in range(level_data.height):
			background_layer.set_cell(Vector2i(i, j), BACKGROUND_SOURCE, Vector2i(0, 0), 0)

func place_piece(piece: Piece) -> void:
	print("POS", piece.position)
	print("CELL", piece.cells)
	print("BOARD", piece.get_board_position())
	for cell in piece.get_board_position():
		# var y_offset = piece.position[0]
		# var x_offset = piece.position[1]
		pieces_layer.set_cell(cell, PIECE_SOURCE, Vector2i(piece.id, 0), 0)
	
func remove_piece(piece: Piece) -> void:
	for cell in piece.get_board_position():
		pieces_layer.erase_cell(cell)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("rotate_left"):
		rotate_piece(active_piece, Piece.Rotation.LEFT)
	if event.is_action_pressed("rotate_right"):
		rotate_piece(active_piece, Piece.Rotation.RIGHT)
	if event.is_action_pressed("move_down"):
		move_piece(active_piece, Piece.Direction.DOWN)
	if event.is_action_pressed("move_right"):
		move_piece(active_piece, Piece.Direction.RIGHT)
	if event.is_action_pressed("move_left"):
		move_piece(active_piece, Piece.Direction.LEFT)
	if event.is_action_pressed("move_up"):
		move_piece(active_piece, Piece.Direction.UP)

func rotate_piece(piece: Piece, rotation_direction: Piece.Rotation):
	remove_piece(piece)
	#print("OLD", piece.cells)
	
	var new_cell_data = piece.rotate_around_cell(1, rotation_direction)
	var new_cells: Array[Vector2i] = new_cell_data[0]
	var new_position: Vector2i = new_cell_data[1]
	piece.cells = new_cells.duplicate()
	piece.position = new_position
	
	place_piece(piece)

func move_piece(piece: Piece, move_direction: Piece.Direction):
	var new_position = piece.move_piece(move_direction, 1)
	remove_piece(piece)
	print("MOVE POS", piece.position)
	piece.position = new_position
	print("MOVE NEW POS", piece.position)
	place_piece(piece)
