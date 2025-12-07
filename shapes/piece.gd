extends RefCounted
class_name Piece

var shape: PolyominoShape
var position: Vector2i
var cells: Array[Vector2i]
var id: int

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

static func blank_piece() -> Piece:
    var blank_shape := PolyominoShape.new()
    blank_shape.cells = []

    var p = Piece.new(blank_shape, Vector2i.ZERO, -1)
    p.cells.clear()
    return p

func rotate_cell(cell_pos: Vector2i, direction: Rotation) -> Vector2i:
    match direction:
        Rotation.RIGHT:
            return Vector2i(cell_pos.y, -cell_pos.x)
        Rotation.LEFT:
            return Vector2i(-cell_pos.y, cell_pos.x)
        Rotation.TWICE:
            return Vector2i(-cell_pos.x, -cell_pos.y)
        _:
            push_error("Invalid Rotation Direction")
            return cell_pos

func rotate_around_cell(pivot_cell_index: int, direction: Rotation) -> Array:
    """
    Returns positions and array of cells after a given rotation around a spefic cell. This returns
    the details of what the proposed rotation would result in, it doesn't apply it to the piece.
    """
    var out_cells: Array[Vector2i] = cells.duplicate()

    if pivot_cell_index < 0 or pivot_cell_index >= cells.size():
        push_error("invalid cell index %s" % [str(pivot_cell_index)])
        return [cells.duplicate(), position]
    
    var pivot_cell_local_before: Vector2i = cells[pivot_cell_index]
    var pivot_cell_world_before: Vector2i = position + pivot_cell_local_before

    for i in out_cells.size():
        out_cells[i] = rotate_cell(out_cells[i], direction)
    
    var pivot_cell_local_after: Vector2i = out_cells[pivot_cell_index]
    var position_after = pivot_cell_world_before - pivot_cell_local_after

    return [out_cells, position_after]

func move_piece(direction: Direction, steps: int = 1) -> Vector2i:
    match direction:
        Direction.LEFT:
            return position + Vector2i(-steps, 0)
        Direction.RIGHT:
            return position + Vector2i(steps, 0)
        Direction.UP:
            return position + Vector2i(0, -steps)
        Direction.DOWN:
            return position + Vector2i(0, steps)
        _:
            push_error("Invalid Rotation Direction")
            return position

        
func update_cells_and_position(new_cells: Array[Vector2i], new_position: Vector2i) -> void:
    cells = new_cells.duplicate()
    position = new_position

func get_board_position() -> Array[Vector2i]:
    var board_position: Array[Vector2i] = []
    for cell in cells:
        board_position.append(Vector2i(cell[0] + position[0], cell[1] + position[1]))
    return board_position