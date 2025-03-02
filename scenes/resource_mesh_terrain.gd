extends TileMapLayer

@onready var resource_mesh_resource: TileMapLayer = $"../ResourceMesh_Resource"

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	if coords in resource_mesh_resource.get_used_cells_by_id(1):
		return true
	return false

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if coords in resource_mesh_resource.get_used_cells_by_id(1):
		tile_data.set_navigation_polygon(0, null)
