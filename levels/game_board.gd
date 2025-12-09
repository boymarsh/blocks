extends Node2D

@export var level_data: LevelData
#@onready var camera: Camera2D = $Camera2D

var pieces_layer: TileMapLayer
var background_layer: TileMapLayer
var highlight_layer: TileMapLayer
var outline_layer: TileMapLayer
var frozen_layer: TileMapLayer
var selection_layer: TileMapLayer
const BACKGROUND_SOURCE = 0
const PIECE_SOURCE = 1
const OUTLINE_SOURCE = 0
const FROZEN_SOURCE = 1
const HIGHLIGHT_SOURCE = 1
const SELECTION_SOURCE = 0
var active_piece: Piece
var outline_piece: Piece
var possible_pieces: Array[Piece]
var pieces: Array[Piece]
var frozen_blocks: Array[Vector2i]


func _ready() -> void:
	_initialise_board()
	
	#var test_piece: Piece = Piece.new(level_data.shapes[5], Vector2i(3, 3))
	var test_piece: Piece = possible_pieces[6]
	var test_piece_2: Piece = possible_pieces[4]
	test_piece.position = Vector2i(3, 3)
	test_piece_2.position = Vector2i(8, 8)
	print(test_piece.cells)
	pieces.append(test_piece)
	pieces.append(test_piece_2)
	place_pieces()
	outline_piece = Piece.blank_piece()
	active_piece = test_piece
	highlight_active_piece()

	# test frozen blocks by adding 3 frozen layers
	frozen_blocks = []
	for x in range(level_data.width):
		for y in range(level_data.height - 3, level_data.height):
			frozen_blocks.append(Vector2i(x, y))
	for cell in frozen_blocks:
		frozen_layer.set_cell(cell, FROZEN_SOURCE, Vector2i(0, 0), 0)

func place_pieces() -> void:
	for piece in pieces:
		place_piece(piece)

func _initialise_board() -> void:
	pieces_layer = $PiecesLayer
	background_layer = $BackgroundLayer
	highlight_layer = $HighlightLayer
	outline_layer = $OutlineLayer
	frozen_layer = $FrozenLayer
	selection_layer = $SelectionLayer

	for i in range(len(level_data.shapes)):
			possible_pieces.append(Piece.new(level_data.shapes[i], Vector2i(0, 0), i))
	place_background()

	
func place_background() -> void:
	for i in range(level_data.width):
		for j in range(level_data.height):
			background_layer.set_cell(Vector2i(i, j), BACKGROUND_SOURCE, Vector2i(0, 0), 0)

func place_piece(piece: Piece) -> void:
	place_cells(piece.get_board_position(), pieces_layer, PIECE_SOURCE, piece.id)

func place_cells(cells: Array[Vector2i], layer: TileMapLayer, source: int, tile_index: int) -> void:
	for cell in cells:
		layer.set_cell(cell, source, Vector2i(tile_index, 0), 0)


func place_outline(piece: Piece) -> bool:
	outline_layer.clear()
	var position_ok: bool = true
	# TODO: different array for valid/invalid cells
	# fill 2 arrays if either ok or blocked, with check_blocked function
	place_cells(piece.get_board_position(), outline_layer, OUTLINE_SOURCE, 1)

	return position_ok

func remove_piece(piece: Piece, layer: TileMapLayer) -> void:
	for cell in piece.get_board_position():
		layer.erase_cell(cell)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("rotate_left"):
		#rotate_piece(active_piece, Piece.Rotation.LEFT)
		rotate_outline_piece(Piece.Rotation.LEFT)
	if event.is_action_pressed("rotate_right"):
		#rotate_piece(active_piece, Piece.Rotation.RIGHT)
		rotate_outline_piece(Piece.Rotation.RIGHT)
	if event.is_action_pressed("move_right"):
		move_outline_piece(Piece.Direction.RIGHT)
	if event.is_action_pressed("move_left"):
		move_outline_piece(Piece.Direction.LEFT)
	if event.is_action_pressed("mouse_left_click"):
		handle_mouse_selection()


func move_outline_piece(direction: Piece.Direction, amount: int = 1, max_amount: int = 1) -> void:
	var current_offset: int = outline_piece.position[0] - active_piece.position[0]
	initialise_outline_piece() # resets any rotation
		
	var active_x: int = active_piece.position[0]

	var to_move: int
	if direction == Piece.Direction.LEFT:
		to_move = current_offset - amount
	else:
		to_move = current_offset + amount
	outline_piece.position[0] = clamp(outline_piece.position[0] + to_move, active_x - max_amount, active_x + max_amount)
	place_outline(outline_piece)
	highlight_pivot_cell()

func rotate_outline_piece(rotation_direction: Piece.Rotation) -> void:
	#initialise_outline_piece()
	outline_piece.position[0] = active_piece.position[0]
	highlight_pivot_cell()
	var new_cell_data = outline_piece.rotate_around_cell(outline_piece.pivot_cell, rotation_direction)
	var new_cells: Array[Vector2i] = new_cell_data[0]
	var new_position: Vector2i = new_cell_data[1]
	outline_piece.cells = new_cells.duplicate()
	outline_piece.position = new_position
	outline_layer.clear()
	place_outline(outline_piece)

func handle_mouse_selection() -> void:
	var world_position: Vector2 = get_global_mouse_position()
	print("world position", world_position)
	var local_position: Vector2 = background_layer.to_local(world_position)
	print("local position", local_position)
	var cell: Vector2i = background_layer.local_to_map(local_position)
	print("cell", cell)

	active_piece_selection(cell)

func active_piece_selection(cell: Vector2i) -> void:
	for piece in pieces:
		var cell_location: int = piece.get_board_position().find(cell)
		if cell_location != -1:
			print("PIECE CLICKED")
			active_piece = piece
			piece.pivot_cell = cell_location
			break

	highlight_active_piece()
	
	initialise_outline_piece()
	highlight_pivot_cell()
	print("PIVOT CELL", outline_piece.pivot_cell)


func highlight_active_piece() -> void:
	highlight_layer.clear()
	var active_board_cells: Array[Vector2i] = active_piece.get_board_position()
	place_cells(active_board_cells, highlight_layer, HIGHLIGHT_SOURCE, active_piece.id)
	
func highlight_pivot_cell() -> void:
	selection_layer.clear()
	var active_board_cells: Array[Vector2i] = active_piece.get_board_position()
	var pivot_cell_only: Array[Vector2i] = [active_board_cells[active_piece.pivot_cell]]
	place_cells(pivot_cell_only, selection_layer, SELECTION_SOURCE, 1) # green
	
	var outline_board_cells: Array[Vector2i] = outline_piece.get_board_position()
	if len(outline_board_cells) > 0:
		var outline_pivot_only: Array[Vector2i] = [outline_board_cells[outline_piece.pivot_cell]]
		place_cells(outline_pivot_only, selection_layer, SELECTION_SOURCE, 0) # red

func initialise_outline_piece() -> void:
	outline_layer.clear()
	outline_piece = active_piece.copy()
	outline_piece.position[1] += 1 # move down 1
	place_outline(outline_piece)

func rotate_piece(piece: Piece, rotation_direction: Piece.Rotation):
	remove_piece(outline_piece, outline_layer)
	var new_cell_data = piece.rotate_around_cell(0, rotation_direction)
	var new_cells: Array[Vector2i] = new_cell_data[0]
	var new_position: Vector2i = new_cell_data[1]
	new_position[1] += 1 # drop by 1
	outline_piece.cells = new_cells.duplicate()
	outline_piece.position = new_position
	place_outline(outline_piece)

# TO REMOVE ONCE ALL THE PROPOSED PIECE STUFF IS IN PLACE
func rotate_piece_old(piece: Piece, rotation_direction: Piece.Rotation):
	remove_piece(piece, pieces_layer)
	var new_cell_data = piece.rotate_around_cell(0, rotation_direction)
	var new_cells: Array[Vector2i] = new_cell_data[0]
	var new_position: Vector2i = new_cell_data[1]
	piece.cells = new_cells.duplicate()
	piece.position = new_position
	place_piece(piece)

func move_piece(piece: Piece, move_direction: Piece.Direction):
	var new_position = piece.move_piece(move_direction, 1)
	remove_piece(piece, pieces_layer)
	print("MOVE POS", piece.position)
	piece.position = new_position
	print("MOVE NEW POS", piece.position)
	place_piece(piece)
	highlight_pivot_cell() # re-do pivot cell
