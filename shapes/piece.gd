extends RefCounted
class_name Piece

var shape: PolyominoShape
var position: Vector2i
var cells: Array[Vector2i]
var id: int
var rotation_state: int = 0


enum Rotation {
    LEFT = 0,
    RIGHT = 1,
    TWICE = 2
}

enum Direction {
    LEFT = 0,
    RIGHT = 1,
    UP = 2,
    DOWN = 3
}

func _init(p_shape: PolyominoShape, p_position: Vector2i, p_id: int = 0) -> void:
    shape = p_shape
    position = p_position
    cells = shape.cells.duplicate()
    id = p_id
    #pivot_cell = pivot

static func blank_piece() -> Piece:
    var blank_shape := PolyominoShape.new()
    blank_shape.cells = []

    var p = Piece.new(blank_shape, Vector2i.ZERO, -1)
    p.cells.clear()
    return p

func copy() -> Piece:
    var p := Piece.new(shape, position, id)
    p.cells = cells.duplicate() # keep current orientation, not shape.cells
    p.rotation_state = rotation_state
    return p


func update_cells_and_position(new_cells: Array[Vector2i], new_position: Vector2i) -> void:
    cells = new_cells.duplicate()
    position = new_position

func get_board_position() -> Array[Vector2i]:
    var board_position: Array[Vector2i] = []
    for cell in cells:
        board_position.append(Vector2i(cell[0] + position[0], cell[1] + position[1]))
    return board_position

func try_rotate_srs(direction: Rotation, is_legal_function: Callable) -> bool:
    # Rotation.TWICE not currently used
    if direction == Rotation.TWICE:
        return false

    var from_state := rotation_state
    var rotation_delta := 0
    if direction == Rotation.RIGHT:
        rotation_delta = 1
    elif direction == Rotation.LEFT:
        rotation_delta = 3
    else:
        return false
    var to_state := (rotation_state + rotation_delta) % 4
   
    var rotated_cells := rotate_around_pivot(direction)
    var kicks: Array[Vector2i] = get_kicks(from_state, to_state)

    for k in kicks:
        var test_pos: Vector2i = position + k
        var world_cells: Array[Vector2i] = []
        world_cells.resize(rotated_cells.size())

        for i in rotated_cells.size():
            world_cells[i] = test_pos + rotated_cells[i]
        
        if is_legal_function.call(world_cells):
            cells = rotated_cells
            position = test_pos
            rotation_state = to_state
            return true
    return false


func rotate_around_pivot(direction: Rotation) -> Array[Vector2i]:
    var pivot: Vector2 = shape.pivot
    var out: Array[Vector2i] = []
    out.resize(cells.size())

    for i in cells.size():
        var cell_pos: Vector2 = Vector2(cells[i].x, cells[i].y)
        var relative_pos: Vector2 = cell_pos - pivot

        var rotation_relative: Vector2
        if direction == Rotation.RIGHT:
            rotation_relative = Vector2(relative_pos.y, -relative_pos.x)
        elif direction == Rotation.LEFT:
            rotation_relative = Vector2(-relative_pos.y, relative_pos.x)
        elif direction == Rotation.TWICE:
            rotation_relative = Vector2(-relative_pos.x, -relative_pos.y)
        else:
            push_error("Invalid rotation direction: %s" % [str(direction)])
            rotation_relative = relative_pos
        var rotated_cell_position: Vector2 = pivot + rotation_relative
        out[i] = Vector2i(
            int(round(rotated_cell_position.x)),
            int(round(rotated_cell_position.y))
        )
    return out

func get_kicks(from_state: int, to_state: int) -> Array[Vector2i]:
    match shape.kick_profile:
        PolyominoShape.KickProfile.I:
            return kicks_I(from_state, to_state)
        PolyominoShape.KickProfile.JLSTZ:
            return kicks_JLSTZ(from_state, to_state)
        PolyominoShape.KickProfile.O, PolyominoShape.KickProfile.NONE:
            return [Vector2i(0, 0)]
        PolyominoShape.KickProfile.GENERIC:
            return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]
        _:
           return [Vector2i(0, 0)]

func kicks_I(from_state: int, to_state: int) -> Array[Vector2i]:
    var key := "%d>%d" % [from_state, to_state]
    match key:
        "0>1": return [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)]
        "1>0": return [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)]
        "1>2": return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)]
        "2>1": return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)]
        "2>3": return [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)]
        "3>2": return [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)]
        "3>0": return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)]
        "0>3": return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)]
        _: return [Vector2i(0, 0)]

func kicks_JLSTZ(from_state: int, to_state: int) -> Array[Vector2i]:
    var key := "%d>%d" % [from_state, to_state]
    match key:
        "0>1": return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)]
        "1>0": return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)]
        "1>2": return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)]
        "2>1": return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)]
        "2>3": return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)]
        "3>2": return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)]
        "3>0": return [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)]
        "0>3": return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)]
        _: return [Vector2i(0, 0)]