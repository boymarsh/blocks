extends Node2D

@export var level_data: LevelData

func _ready() -> void:
	# test code	
	var source_id: int = 1
	var pieces_layer = $PiecesLayer
	var background_layer = $BackgroundLayer
	var highlight_layer = $HighlightLayer

	var pieces_ts: TileSet = pieces_layer.tile_set
	var pieces_source := pieces_ts.get_source(source_id) as TileSetAtlasSource
	var tile_count: int = pieces_source.get_tiles_count()
	print("tile_count =", tile_count)
	for i in tile_count:
		var pieces_atlas_coords: Vector2i = pieces_source.get_tile_id(i)
		print("tile", i, "atlas coords:", pieces_atlas_coords)

		pieces_layer.set_cell(Vector2i(i, 0), source_id, pieces_atlas_coords, 0)

	var h_ts: TileSet = highlight_layer.tile_set
	var h_source := h_ts.get_source(source_id) as TileSetAtlasSource
	var h_tile_count: int = h_source.get_tiles_count()
	print("h_tile_count =", h_tile_count)
	for i in h_tile_count:
		var h_atlas_coords: Vector2i = h_source.get_tile_id(i)
		print("tile", i, "atlas coords:", h_atlas_coords)

		highlight_layer.set_cell(Vector2i(i, 4), source_id, h_atlas_coords, 0)
	
	for i in range(level_data.width):
		for j in range(level_data.height):
			background_layer.set_cell(Vector2i(i, j), 0, Vector2i(0, 0), 0)
