extends Control

@onready var board_container = $BoardContainer
@onready var game_board = $BoardContainer/GameBoard
const TILE_SIZE = 64
var cols: int
var rows: int

func _ready() -> void:
	cols = game_board.level_data.width # in tiles
	rows = game_board.level_data.height # in tiles

	# 1) Root fills the whole screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	#size = get_viewport_rect().size

	# 2) BoardContainer fills the root
	_board_container_set_full_size()

	# 3) Reset GameBoard transform
	game_board.scale = Vector2.ONE
	game_board.position = Vector2.ZERO

	# 4) Re-scale when the container resizes
	board_container.resized.connect(_update_board_scale)

	# 5) After layout settles, do the first fit
	await get_tree().process_frame
	_update_board_scale()

func _board_container_set_full_size():
	board_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	board_container.offset_left = 0
	board_container.offset_top = 0
	board_container.offset_right = 0
	board_container.offset_bottom = 0

func _update_board_scale() -> void:
	var container_size: Vector2 = board_container.size
	if container_size.x <= 0.0 or container_size.y <= 0.0:
		return

	# How many whole pixels can each tile get in each direction?
	var max_tile_px_x: int = floor(container_size.x / cols)
	var max_tile_px_y: int = floor(container_size.y / rows)

	# Use the limiting direction
	var tile_px := int(min(max_tile_px_x, max_tile_px_y))
	tile_px = max(tile_px, 1)

	# Scale relative to 64px source art
	var scale_factor := float(tile_px) / float(TILE_SIZE)
	game_board.scale = Vector2(scale_factor, scale_factor)

	# Actual used size of the board on screen
	var used_size := Vector2(cols * tile_px, rows * tile_px)

	# Centre, but snap to whole pixels too
	var pos := (container_size - used_size) * 0.5
	game_board.position = pos.round()

	print("cols:", cols, "rows:", rows,
		"container:", container_size,
		"tile_px:", tile_px,
		"scale_factor:", scale_factor,
		"used_size:", used_size)
