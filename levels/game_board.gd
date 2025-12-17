extends Node2D

@export var level_data: LevelData

# --- rules for this level / piece ---
@export var max_rotations: int = 1 # -1 for unlimited
@export var max_translations: int = 1 # -1 for unlimited
@export var exclusive_rot_or_trans: bool = false
# if true: using a rotation forbids translations, and vice versa

# --- current plan state for the active outline ---
var plan_rotation_steps: int = 0 # in 90-degree steps, +ve = right, -ve = left
var plan_translation_x: int = 0 # relative to active_piece.position.x


var pieces_layer: TileMapLayer
var background_layer: TileMapLayer
var highlight_layer: TileMapLayer
var outline_layer: TileMapLayer
var frozen_layer: TileMapLayer
var inactive_outline_layer: TileMapLayer
const BACKGROUND_SOURCE = 0
const PIECE_SOURCE = 1
const OUTLINE_SOURCE = 0
const FROZEN_SOURCE = 1
const HIGHLIGHT_SOURCE = 1
const INACTIVE_SOURCE = 0
const CARDINAL_DIRS: Array[Vector2i] = [
	Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN
]
var active_piece: Piece
var outline_piece: Piece
var possible_pieces: Array[Piece]
var pieces: Array[Piece]
var frozen_blocks: Dictionary[Vector2i, bool] = {} # using Dict as a proxy for a Set


func _ready() -> void:
	_initialise_board()
	
	#var test_piece: Piece = Piece.new(level_data.shapes[5], Vector2i(3, 3))
	var test_piece: Piece = possible_pieces[6]
	var test_piece_2: Piece = possible_pieces[4]
	test_piece.position = Vector2i(3, 3)
	test_piece_2.position = Vector2i(6, 4)
	print(test_piece.cells)
	pieces.append(test_piece)
	pieces.append(test_piece_2)
	place_pieces()
	outline_piece = Piece.blank_piece()
	active_piece = test_piece
	intialise_pieces()
	

	# test frozen blocks by adding 3 frozen layers
	for x in range(level_data.width):
		for y in range(level_data.height - 1, level_data.height):
			frozen_blocks[Vector2i(x, y)] = true
	place_frozen_blocks()
	# for cell in frozen_blocks:
	# 	frozen_layer.set_cell(cell, FROZEN_SOURCE, Vector2i(0, 0), 0)

	# test interfering cell
	#frozen_layer.set_cell(Vector2i(3, 5), FROZEN_SOURCE, Vector2i(0, 0), 0)


func place_pieces() -> void:
	for piece in pieces:
		place_piece(piece)

func _initialise_board() -> void:
	pieces_layer = $PiecesLayer
	background_layer = $BackgroundLayer
	highlight_layer = $HighlightLayer
	outline_layer = $OutlineLayer
	frozen_layer = $FrozenLayer
	inactive_outline_layer = $InactiveOutlineLayer
	collect_possible_pieces()
	place_background()

func intialise_pieces():
	highlight_active_piece()
	inactive_piece_outlines()
	initialise_outline_piece()
	#highlight_pivot_cell()

func collect_possible_pieces() -> void:
	for i in range(len(level_data.shapes)):
			possible_pieces.append(Piece.new(level_data.shapes[i], Vector2i(0, 0), i))

func place_background() -> void:
	for i in range(level_data.width):
		for j in range(level_data.height):
			background_layer.set_cell(Vector2i(i, j), BACKGROUND_SOURCE, Vector2i(0, 0), 0)

func place_frozen_blocks() -> void:
	place_cells(frozen_blocks.keys(), frozen_layer, FROZEN_SOURCE, 0)

func place_piece(piece: Piece) -> void:
	place_cells(piece.get_board_position(), pieces_layer, PIECE_SOURCE, piece.id)

func place_cells(cells: Array[Vector2i], layer: TileMapLayer, source: int, tile_index: int) -> void:
	for cell in cells:
		layer.set_cell(cell, source, Vector2i(tile_index, 0), 0)


func place_outline(piece: Piece) -> void:
	outline_layer.clear()
	var unblocked_pieces: Array[Vector2i] = []
	var blocked_pieces: Array[Vector2i] = []
	
	for cell: Vector2i in piece.get_board_position():
		if are_cells_legal([cell]):
			unblocked_pieces.append(cell)
		else:
			blocked_pieces.append(cell)

	place_cells(unblocked_pieces, outline_layer, OUTLINE_SOURCE, 1) # green outline
	place_cells(blocked_pieces, outline_layer, OUTLINE_SOURCE, 0) # red outline


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("rotate_left"):
		rotate_outline_piece(Piece.Rotation.LEFT)
	if event.is_action_pressed("rotate_right"):
		rotate_outline_piece(Piece.Rotation.RIGHT)
	if event.is_action_pressed("move_right"):
		move_outline_piece(Piece.Direction.RIGHT)
	if event.is_action_pressed("move_left"):
		move_outline_piece(Piece.Direction.LEFT)
	if event.is_action_pressed("mouse_left_click"):
		handle_mouse_selection()
	if event.is_action_pressed("commit"):
		commit_move()

func commit_move():
	# 1. Is move allowed?
	if not validate_piece_position(outline_piece):
		print("not allowed (replace with effect later)")
		return

	# 2. Update the *data model*

	# Update active piece in place
	active_piece.cells = outline_piece.cells.duplicate()
	active_piece.position = outline_piece.position
	active_piece.rotation_state = outline_piece.rotation_state


	# Move inactive pieces down by 1
	for piece in get_inactive_pieces():
		piece.position.y += 1

	# Freeze anything touching frozen
	update_frozen_pieces()

	# 3. Redraw all board layers

	pieces_layer.clear()
	outline_layer.clear()
	inactive_outline_layer.clear()

	place_pieces() # <- draws active + all inactive pieces
	intialise_pieces() # highlight, inactive outlines, active outline
	place_frozen_blocks()

func update_frozen_pieces() -> void:
	var to_freeze: Array[Piece] = []
	for piece in pieces:
		if is_piece_touching_frozen_layer(piece):
			to_freeze.append(piece)
	var active_frozen := false
	for piece in to_freeze:
		if freeze_and_remove_piece(piece):
			active_frozen = true
	if active_frozen:
		select_new_active_piece()

func select_new_active_piece() -> void:
	if pieces.is_empty():
		active_piece = null
		handle_no_pieces_remaining()
		return

	active_piece = pieces[0] # simplest rule
	reset_rotation_translation_plan()
	intialise_pieces()

func handle_no_pieces_remaining() -> void:
	print("No pieces remaining")
	# temporary random piece selection
	var new_piece: Piece = possible_pieces.pick_random().copy()
	new_piece.position = Vector2i(0, 0)
	pieces.append(new_piece)
	active_piece = new_piece


func freeze_and_remove_piece(piece: Piece) -> bool:
	for cell in piece.get_board_position():
		freeze_cell(cell)
	pieces.erase(piece)

	return piece == active_piece

func is_piece_touching_frozen_layer(piece: Piece) -> bool:
	for cell in piece.get_board_position():
		# for dir in CARDINAL_DIRS:
		# 	if is_frozen(cell + dir):
		# 		return true
		if is_frozen(cell + Vector2i.DOWN):
			return true

	return false

func can_translate(dx: int, max_amount: int) -> bool:
	# proposed new displacement from original column
	var new_plan_translation := plan_translation_x + dx

	# limit by max_translations, if configured
	if max_translations >= 0 and abs(new_plan_translation) > max_translations:
		return false

	# also respect the per-call clamp (how far from active piece)
	if abs(new_plan_translation) > max_amount:
		return false

	return true


func move_outline_piece(direction: Piece.Direction, amount: int = 1, max_amount: int = 2) -> void:
	var dx := 0
	if direction == Piece.Direction.LEFT:
		dx = - amount
	elif direction == Piece.Direction.RIGHT:
		dx = amount
	else:
		return

	if not can_translate(dx, max_amount):
		return

	# --- exclusivity behaviour ---
	# If exclusive, choosing translation clears any rotation state.
	if exclusive_rot_or_trans and plan_rotation_steps != 0:
		plan_rotation_steps = 0

	# update translation plan
	plan_translation_x += dx

	rebuild_outline_from_plan()

func can_rotate(rotation_direction: Piece.Rotation) -> bool:
	var delta_steps := 0
	match rotation_direction:
		Piece.Rotation.RIGHT:
			delta_steps = 1
		Piece.Rotation.LEFT:
			delta_steps = -1
		Piece.Rotation.TWICE:
			delta_steps = 2

	var new_steps := plan_rotation_steps + delta_steps

	# limit by max_rotations as *displacement* from original orientation
	if max_rotations >= 0 and abs(new_steps) > max_rotations:
		return false

	return true


func rotate_outline_piece(rotation_direction: Piece.Rotation) -> void:
	if not can_rotate(rotation_direction):
		return

	# --- exclusivity behaviour ---
	# If exclusive, choosing rotation clears any translation state.
	if exclusive_rot_or_trans and plan_translation_x != 0:
		plan_translation_x = 0

	match rotation_direction:
		Piece.Rotation.RIGHT:
			plan_rotation_steps += 1
		Piece.Rotation.LEFT:
			plan_rotation_steps -= 1
		Piece.Rotation.TWICE:
			plan_rotation_steps += 2

	rebuild_outline_from_plan()


func handle_mouse_selection() -> void:
	var world_position: Vector2 = get_global_mouse_position()
	print("world position", world_position)
	var local_position: Vector2 = background_layer.to_local(world_position)
	print("local position", local_position)
	var cell: Vector2i = background_layer.local_to_map(local_position)
	print("cell", cell)

	active_piece_selection(cell)

func active_piece_selection(cell: Vector2i) -> void:
	var found_cell: bool = false
	for piece in pieces:
		var cell_location: int = piece.get_board_position().find(cell)
		if cell_location != -1:
			print("PIECE CLICKED")
			active_piece = piece
			#piece.pivot_cell = cell_location
			found_cell = true
			break
	
	if not found_cell:
		return

	reset_rotation_translation_plan()
	intialise_pieces()


func reset_rotation_translation_plan():
	plan_rotation_steps = 0
	plan_translation_x = 0

func highlight_active_piece() -> void:
	highlight_layer.clear()
	var active_board_cells: Array[Vector2i] = active_piece.get_board_position()
	place_cells(active_board_cells, highlight_layer, HIGHLIGHT_SOURCE, active_piece.id)
	

func initialise_outline_piece() -> void:
	outline_layer.clear()
	outline_piece = active_piece.copy()
	outline_piece.position[1] += 1 # move down 1
	reset_rotation_translation_plan()
	place_outline(outline_piece)

func rebuild_outline_from_plan() -> void:
	outline_layer.clear()

	# Start from a fresh copy of the active piece, one row below
	outline_piece = active_piece.copy()
	outline_piece.position.y += 1

	# Apply horizontal translation plan
	outline_piece.position.x += plan_translation_x

	# Apply rotation plan using SRS (pivot + kicks)
	var rotation_steps_to_apply: int = plan_rotation_steps

	if rotation_steps_to_apply > 0:
		for step_index: int in range(rotation_steps_to_apply):
			var rotation_succeeded: bool = outline_piece.try_rotate_srs(
				Piece.Rotation.RIGHT,
				Callable(self, "are_cells_legal")
			)
			if not rotation_succeeded:
				break
	elif rotation_steps_to_apply < 0:
		for step_index: int in range(-rotation_steps_to_apply):
			var rotation_succeeded: bool = outline_piece.try_rotate_srs(
				Piece.Rotation.LEFT,
				Callable(self, "are_cells_legal")
			)
			if not rotation_succeeded:
				break

	place_outline(outline_piece)
	#highlight_pivot_cell()

func validate_piece_position(piece: Piece) -> bool:
	var piece_world_cells: Array[Vector2i] = piece.get_board_position()
	return are_cells_legal(piece_world_cells)

func cell_occupied(cell: Vector2i, layers: Array[TileMapLayer] = []) -> bool:
	if layers.is_empty():
		layers = [inactive_outline_layer, frozen_layer]
	

	for layer in layers:
		if layer.get_cell_source_id(cell) != -1:
			return true
	return false

func get_inactive_pieces() -> Array[Piece]:
	var result: Array[Piece] = []
	for p in pieces:
		if p != active_piece:
			result.append(p)
	return result

func get_inactive_board_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for p in pieces:
		if p == active_piece:
			continue
		cells.append_array(p.get_board_position())
	return cells

func inactive_piece_outlines():
	inactive_outline_layer.clear()
	var cells_below: Array[Vector2i] = []
	for cell in get_inactive_board_cells():
		cells_below.append(Vector2i(cell[0], cell[1] + 1))
	place_cells(cells_below, inactive_outline_layer, INACTIVE_SOURCE, 0)

func are_cells_legal(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if cell.x < 0 or cell.x >= level_data.width:
			return false
		if cell.y < 0 or cell.y >= level_data.height:
			return false
		if cell_occupied(cell):
			return false
	return true

func freeze_cell(cell: Vector2i) -> void:
	frozen_blocks[cell] = true

func unfreeze_cell(cell: Vector2i) -> void:
	frozen_blocks.erase(cell)

func is_frozen(cell: Vector2i) -> bool:
	return frozen_blocks.has(cell)