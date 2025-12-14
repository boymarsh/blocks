@tool
extends Resource
class_name PolyominoShape

@export var name: String = "Unnamed"
@export var color: Color = Color.WHITE
@export var cells: Array[Vector2i] = [] # relative coordinates
@export var id: int = 0

enum KickProfile {NONE, JLSTZ, I, O, GENERIC}
@export var pivot: Vector2 = Vector2.ZERO
@export var kick_profile: KickProfile = KickProfile.NONE
