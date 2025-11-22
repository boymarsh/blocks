extends Resource
class_name LevelData

@export var width: int = 10
@export var height: int = 24
@export var spawn_rows: int = 4: set = _set_spawn_rows # invisible rows at the top for spawning

# Which shapes this level is allowed to spawn
@export var shapes: Array[PolyominoShape] = []

# Possible stuff later
# @export var max_active_pieces: int = 3
# @export var allow_bombs: bool = false
# @export var allow_partial_clears: bool = false


func _set_spawn_rows(value: int) -> void:
    # clamp to something sensible
    spawn_rows = clamp(value, 0, height - 1)
