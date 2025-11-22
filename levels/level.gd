extends Node2D

@export var level_data: LevelData

@onready var tilemap: TileMapLayer = $BoardLayer
@onready var background := $BackgroundLayer

enum CellType {
    EMPTY = -1
}

var width: int
var height: int
var spawn_rows: int
var shapes: Array[PolyominoShape] = []

var grid: Array = [] # 2D [y][x], runtime only
var active_pieces: Array = [] # later: Array[Piece]

class Piece:
    var shape: PolyominoShape
    var pos: Vector2i

    func _init(p_shape: PolyominoShape, p_pos: Vector2i) -> void:
        shape = p_shape
        pos = p_pos


var active_piece: Piece = null

func _ready() -> void:
    if level_data == null:
        push_error("LevelData not assigned on Level scene")
        return

    width = level_data.width
    height = level_data.height
    spawn_rows = level_data.spawn_rows
    shapes = level_data.shapes

    _fill_background_grid()
    _init_grid()
    _spawn_initial_piece()
    _sync_tilemap_from_grid()
    #_debug_fill_bottom_row()
    _center_board_horizontally()

func _init_grid() -> void:
    grid.clear()
    grid.resize(height)
    for y in range(height):
        grid[y] = []
        grid[y].resize(width)
        for x in range(width):
            grid[y][x] = CellType.EMPTY

func _fill_background_grid():
    background.clear()

    for y in range(spawn_rows, height):
        for x in range(width):
            background.set_cell(
                Vector2i(x, y),
                0, # source_id
                Vector2i(0, 0), # atlas coords inside atlas
                0 # alternative tile (if any)
            )


const BLOCK_SOURCE_ID := 0 # your atlas source id


func _sync_tilemap_from_grid() -> void:
    tilemap.clear()

    # Draw resting blocks
    for y in range(spawn_rows, height):
        for x in range(width):
            var id: int = grid[y][x]
            if id >= 0:
                tilemap.set_cell(
                    Vector2i(x, y),
                    BLOCK_SOURCE_ID, # source_id (atlas source)
                    Vector2i(0, 0), # atlas coords inside that source
                    id # alternative tile (0..6)
                )

    # Draw active piece on top
    if active_piece != null:
        for local in active_piece.shape.cells:
            var cell := active_piece.pos + local
            if cell.y < 0 or cell.y >= height:
                continue
            if cell.x < 0 or cell.x >= width:
                continue
            if cell.y >= spawn_rows:
                tilemap.set_cell(
                    cell,
                    BLOCK_SOURCE_ID,
                    Vector2i(0, 0),
                    active_piece.shape.id
                )

func _debug_fill_bottom_row() -> void:
    # just to see something
    var y := height - 1
    for x in range(width):
        grid[y][x] = x % 7 # assume tiles 0..6 exist in tileset
    _sync_tilemap_from_grid()

func _center_board_horizontally() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size

    # Get cell size from the tileset used by the board layer
    var cell_size: Vector2 = Vector2(tilemap.tile_set.tile_size)

    # Board width in pixels
    var board_width: float = width * cell_size.x

    # Current y stays as-is, just change x
    position.x = (viewport_size.x - board_width) / 2.0

func _spawn_initial_piece() -> void:
    if shapes.is_empty():
        push_warning("No shapes assigned in LevelData")
        return

    var shape: PolyominoShape = shapes[1] # for now just use the first shape

    # Compute shape width from its local cells
    var min_x := 999
    var max_x := -999
    for c in shape.cells:
        if c.x < min_x:
            min_x = c.x
        if c.x > max_x:
            max_x = c.x
    var shape_width := max_x - min_x + 1

    # Center horizontally at top of spawn area (y = 0)
    var start_x := int((width - shape_width) / 2) - min_x
    var start_y := 0

    active_piece = Piece.new(shape, Vector2i(start_x, start_y))


func _can_piece_fit_at(pos: Vector2i, shape: PolyominoShape) -> bool:
    for local in shape.cells:
        var cell := pos + local
        var x := cell.x
        var y := cell.y

        # Outside board horizontally?
        if x < 0 or x >= width:
            return false

        # Below bottom?
        if y >= height:
            return false

        # Above top: treat as blocked for now
        if y < 0:
            return false

        # Colliding with resting block?
        if grid[y][x] != CellType.EMPTY:
            return false

    return true


func _try_move_active_piece(delta: Vector2i) -> bool:
    if active_piece == null:
        return false

    var new_pos := active_piece.pos + delta
    if _can_piece_fit_at(new_pos, active_piece.shape):
        active_piece.pos = new_pos
        _sync_tilemap_from_grid()
        return true
    return false


func _lock_active_piece() -> void:
    if active_piece == null:
        return

    for local in active_piece.shape.cells:
        var cell := active_piece.pos + local
        if cell.y < 0 or cell.y >= height:
            continue
        if cell.x < 0 or cell.x >= width:
            continue
        grid[cell.y][cell.x] = active_piece.shape.id

    active_piece = null
    _sync_tilemap_from_grid()
    # Later: spawn the next piece here

func _unhandled_input(event: InputEvent) -> void:
    if active_piece == null:
        return

    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_SPACE:
                _step_piece(0) # drop straight down 1
            KEY_LEFT:
                _step_piece(-1) # move left + drop 1
            KEY_RIGHT:
                _step_piece(1) # move right + drop 1


func _step_piece(horizontal_delta: int) -> void:
    if active_piece == null:
        return

    # Try move horizontally + down
    var moved := _try_move_active_piece(Vector2i(horizontal_delta, 1))

    if not moved:
        # If that fails, try just dropping 1
        if not _try_move_active_piece(Vector2i(0, 1)):
            # Can't move down at all -> lock piece
            _lock_active_piece()
