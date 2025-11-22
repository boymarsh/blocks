@tool
extends Resource
class_name PolyominoShape

@export var name: String = "Unnamed"
@export var color: Color = Color.WHITE
@export var cells: Array[Vector2i] = [] # relative coordinates
@export var id: int = 0
