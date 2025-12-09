extends RefCounted
class_name Piece

var shape: PolyominoShape
var position: Vector2i
var cells: Array[Vector2i]
var id: int
var pivot_cell: int = 0

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

func _init(p_shape: PolyominoShape, p_position: Vector2i, p_id: int = 0, pivot: int = 0) -> void:
    shape = p_shape
    position = p_position
    cells = shape.cells.duplicate()
    id = p_id
    pivot_cell = pivot

static func blank_piece() -> Piece:
    var blank_shape := PolyominoShape.new()
    blank_shape.cells = []

    var p = Piece.new(blank_shape, Vector2i.ZERO, -1)
    p.cells.clear()
    return p

func copy() -> Piece:
    var p := Piece.new(shape, position, id, pivot_cell)
    p.cells = cells.duplicate() # keep current orientation, not shape.cells
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
    Returns [new_cells, new_position] after rotating the piece around the
    given pivot cell. The pivot cell's *world* position (and its local
    coordinates) remain fixed.
    """
    if pivot_cell_index < 0 or pivot_cell_index >= cells.size():
        push_error("invalid cell index %s" % [str(pivot_cell_index)])
        return [cells.duplicate(), position]

    var pivot_local: Vector2i = cells[pivot_cell_index]

    var out_cells: Array[Vector2i] = []
    out_cells.resize(cells.size())

    # Rotate every cell around the pivot in local space
    for i in cells.size():
        var local: Vector2i = cells[i]
        var relative: Vector2i = local - pivot_local # shift so pivot is at (0,0)
        var rotated_relative: Vector2i = rotate_cell(relative, direction)
        out_cells[i] = pivot_local + rotated_relative # shift back

    # Position does NOT change – we rotated in local space around the pivot
    var position_after: Vector2i = position

    # Optional sanity check: pivot world pos should be identical
    var pivot_world_before: Vector2i = position + cells[pivot_cell_index]
    var pivot_world_after: Vector2i = position_after + out_cells[pivot_cell_index]
    if pivot_world_before != pivot_world_after:
        push_error("Pivot drift! before=%s after=%s"
            % [str(pivot_world_before), str(pivot_world_after)])

    return [out_cells, position_after]


# func rotate_around_cell(pivot_cell_index: int, direction: Rotation) -> Array:
#     """
#     Returns [rotated_cells, new_position] after rotating the piece
#     around the given pivot cell. The pivot cell's *world* position
#     should remain identical before and after the rotation.
#     """
#     var out_cells: Array[Vector2i] = cells.duplicate()

#     if pivot_cell_index < 0 or pivot_cell_index >= cells.size():
#         push_error("invalid cell index %s" % [str(pivot_cell_index)])
#         return [cells.duplicate(), position]

#     var pivot_cell_local_before: Vector2i = cells[pivot_cell_index]
#     var pivot_cell_world_before: Vector2i = position + pivot_cell_local_before

#     # Rotate all local cell positions around (0,0)
#     for i in out_cells.size():
#         out_cells[i] = rotate_cell(out_cells[i], direction)

#     var pivot_cell_local_after: Vector2i = out_cells[pivot_cell_index]
#     var position_after: Vector2i = pivot_cell_world_before - pivot_cell_local_after

#     # --- debug check: did the pivot move in world space? ---
#     var pivot_cell_world_after: Vector2i = position_after + out_cells[pivot_cell_index]
#     if pivot_cell_world_before != pivot_cell_world_after:
#         push_error("Pivot drift! before=%s after=%s"
#             % [str(pivot_cell_world_before), str(pivot_cell_world_after)])

#     return [out_cells, position_after]


# func rotate_around_cell(pivot_cell_index: int, direction: Rotation) -> Array:
#     """
#     Returns positions and array of cells after a given rotation around a spefic cell. This returns
#     the details of what the proposed rotation would result in, it doesn't apply it to the piece.
#     """
#     var out_cells: Array[Vector2i] = cells.duplicate()

#     if pivot_cell_index < 0 or pivot_cell_index >= cells.size():
#         push_error("invalid cell index %s" % [str(pivot_cell_index)])
#         return [cells.duplicate(), position]
    
#     var pivot_cell_local_before: Vector2i = cells[pivot_cell_index]
#     var pivot_cell_world_before: Vector2i = position + pivot_cell_local_before

#     for i in out_cells.size():
#         out_cells[i] = rotate_cell(out_cells[i], direction)
    
#     var pivot_cell_local_after: Vector2i = out_cells[pivot_cell_index]
#     var position_after = pivot_cell_world_before - pivot_cell_local_after

#     return [out_cells, position_after]

# func move_piece(direction: Direction, steps: int = 1) -> Vector2i:
#     match direction:
#         Direction.LEFT:
#             return position + Vector2i(-steps, 0)
#         Direction.RIGHT:
#             return position + Vector2i(steps, 0)
#         Direction.UP:
#             return position + Vector2i(0, -steps)
#         Direction.DOWN:
#             return position + Vector2i(0, steps)
#         _:
#             push_error("Invalid Rotation Direction")
#             return position

        
func update_cells_and_position(new_cells: Array[Vector2i], new_position: Vector2i) -> void:
    cells = new_cells.duplicate()
    position = new_position

func get_board_position() -> Array[Vector2i]:
    var board_position: Array[Vector2i] = []
    for cell in cells:
        board_position.append(Vector2i(cell[0] + position[0], cell[1] + position[1]))
    return board_position