extends PanelContainer

@onready var terrain_value = $MarginContainer/VBoxContainer/TerrainInfo/Value
@onready var resource_value = $MarginContainer/VBoxContainer/ResourceInfo/Value
@onready var position_value = $MarginContainer/VBoxContainer/PositionInfo/Value

func _ready():
	# Set initial visibility
	modulate.a = 0.9
	
	# Add a stylish background
	add_theme_stylebox_override("panel", create_stylebox())

func create_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)  # Semi-transparent dark background
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.7, 0.7, 0.8)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	return style

func update_info(terrain_type: String, resource_type: String, tile_position: Vector2i):
	# Update the UI
	terrain_value.text = terrain_type
	resource_value.text = resource_type
	position_value.text = "(%d, %d)" % [tile_position.x, tile_position.y]
	
	# Color-code the terrain types
	match terrain_type.to_lower():
		"grass":
			terrain_value.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		"water":
			terrain_value.add_theme_color_override("font_color", Color(0.2, 0.4, 0.8))
		"sand":
			terrain_value.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		_:
			terrain_value.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Color-code the resource types
	match resource_type.to_lower():
		"gold":
			resource_value.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		"iron":
			resource_value.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		"none":
			resource_value.add_theme_color_override("font_color", Color(1, 1, 1))
		_:
			resource_value.add_theme_color_override("font_color", Color(1, 1, 1))
