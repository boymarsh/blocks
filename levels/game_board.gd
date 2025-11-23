extends Node2D

@export var level_data: LevelData

func _ready() -> void:
	var source_id: int = 1
	var pieces_layer = $PiecesLayer
	var background_layer = $BackgroundLayer

	var ts: TileSet = pieces_layer.tile_set
	var source := ts.get_source(source_id) as TileSetAtlasSource
	var tile_count: int = source.get_tiles_count()
	print("tile_count =", tile_count)

	for i in tile_count:
		var atlas_coords: Vector2i = source.get_tile_id(i)
		print("tile", i, "atlas coords:", atlas_coords)

		pieces_layer.set_cell(Vector2i(i, 0), source_id, atlas_coords, 0)
	
	for i in range(level_data.width):
		for j in range(level_data.height):
			background_layer.set_cell(Vector2i(i, j), 0, Vector2i(0, 0), 0)
