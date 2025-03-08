extends Node2D

var selection_start: Vector2 = Vector2.ZERO
var selection_end: Vector2 = Vector2.ZERO
var selecting: bool = false
var selected_characters: Array = []

@onready var selection_box: ColorRect = $Control/SelectionBox
@onready var terrain_info_display = $Control/TerrainInfoDisplay
@onready var tile_highlight: Line2D = $TileHighlight
@onready var characters_node: Node2D
@export var player_scene: PackedScene

var last_clicked_position: Vector2i = Vector2i(0, 0)
var resource_mesh: Node2D = null

func _ready():
	var spawner_path = "/root/Menu/MultiplayerSpawner"  # Path includes Menu node
	var spawner_node = get_node_or_null(spawner_path)
	if spawner_node:
		spawner = spawner_node
	else:
		push_error("MultiplayerSpawner not found at path: " + spawner_path)
	if !is_multiplayer_authority():
		get_node("Control").visible = false;
	
	resource_mesh = get_tree().get_root().get_node_or_null("/root/Menu/ResourceMesh")

@onready var spawner: Node

func _enter_tree():
	print(name)
	set_multiplayer_authority(name.to_int())

func _process(delta):
	if resource_mesh and last_clicked_position != Vector2i(0, 0):
		var world_pos = resource_mesh.get_node("ResourceMesh_Terrain").map_to_local(last_clicked_position)
		tile_highlight.global_position = resource_mesh.to_global(world_pos)

func _input(event):
	if is_multiplayer_authority():
		handle_input(event)

func handle_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_selection(event.position)
				update_terrain_info(event.position)
			else:
				end_selection(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and not selecting and event.pressed:
			move_selected_characters(event.position)
			update_terrain_info(event.position)

	if event is InputEventMouseMotion and selecting:
		update_selection(event.position)
		
		
	if event is InputEventKey and event.keycode == KEY_DELETE and event.pressed:
		for character in selected_characters:
			delete_char(character.get_path())
		selected_characters = []


	if event.is_action_pressed("ui_cancel"):
		deselect_all_characters()

func start_selection(position: Vector2):
	selection_start = get_global_mouse_position()
	selection_end = selection_start
	selecting = true
	selection_box.visible = true

	selection_box.position = selection_start
	selection_box.size = Vector2.ZERO


func update_selection(position: Vector2):
	selection_end = get_global_mouse_position()

	var world_start = selection_start
	var world_end = selection_end

	var selection_rect = Rect2(
		Vector2(
			min(world_start.x, world_end.x),
			min(world_start.y, world_end.y)
		),
		(world_end - world_start).abs()
	)

	selection_box.position = get_viewport_transform() * selection_rect.position
	selection_box.size = selection_rect.size

	var characters_node = get_tree().get_root().get_node_or_null("/root/Menu/characters")
	if characters_node:
		for character in characters_node.get_children():
			var character_pos = character.global_position

			if selection_rect.has_point(character_pos) and character.get_multiplayer_authority() == multiplayer.get_unique_id():
				character.select()
				if character not in selected_characters:
					selected_characters.append(character)
			else:
				character.deselect()
				if character in selected_characters:
					selected_characters.erase(character)


func end_selection(position: Vector2):
	selection_end = position
	selecting = false
	selection_box.visible = false
	update_selection(position)

func get_selection_rect() -> Rect2:
	return Rect2(selection_box.position, selection_box.size).abs()

func move_selected_characters(target_position: Vector2):
	var world_target = get_global_mouse_position()

	for character in selected_characters:
		character.move_to(world_target)

func deselect_all_characters():
	for character in selected_characters:
		character.deselect()
	selected_characters.clear()

func _on_button_pressed():
	print("Button pressed - attempting to spawn character")
	var position = Vector2(randf() * 500, randf() * 500)
	var my_id = multiplayer.get_unique_id()
	print("My ID:", my_id)

	if spawner:
		print("Spawner found, requesting spawn at position:", position)
		if multiplayer.is_server():
			print("Running as server, calling rpc_request_spawn directly")
			spawner.rpc_request_spawn(position, my_id)  # Direct local call
		else:
			print("Running as client, sending spawn request to server")
			spawner.rpc_id(1, "rpc_request_spawn", position, my_id)
	else:
		push_error("Spawner is not assigned in SelectionBox!")

func delete_char(char):
	spawner.rpc_request_delete(char, multiplayer.get_unique_id())

func update_terrain_info(world_position: Vector2):
	if resource_mesh:
		var local_position = resource_mesh.to_local(get_global_mouse_position())
		
		var tile_position = resource_mesh.get_node("ResourceMesh_Terrain").local_to_map(local_position)
		last_clicked_position = tile_position
		
		var terrain_type = get_terrain_type_at(tile_position)
		var resource_type = get_resource_type_at(tile_position)
		
		terrain_info_display.update_info(terrain_type, resource_type, tile_position)
		
		if tile_highlight:
			var world_pos = resource_mesh.get_node("ResourceMesh_Terrain").map_to_local(tile_position)
			
			tile_highlight.global_position = resource_mesh.to_global(world_pos)
			tile_highlight.visible = true

func get_terrain_type_at(tile_position: Vector2i) -> String:
	if not resource_mesh:
		return "Unknown"
	
	if resource_mesh.terrain_data.has(tile_position):
		var atlas_coords = resource_mesh.terrain_data[tile_position].atlas_coords
		if atlas_coords == resource_mesh.resource_tile_ids["grass"]:
			return "Grass"
		elif atlas_coords == resource_mesh.resource_tile_ids["water"]:
			return "Water"
		elif atlas_coords == resource_mesh.resource_tile_ids["sand"]:
			return "Sand"
	
	return "Mangler info om tile"

func get_resource_type_at(tile_position: Vector2i) -> String:
	if not resource_mesh:
		return "None"
	
	if resource_mesh.resource_data.has(tile_position):
		var atlas_coords = resource_mesh.resource_data[tile_position].atlas_coords
		if atlas_coords == resource_mesh.resource_tile_ids["iron"]:
			return "Iron"
		elif atlas_coords == resource_mesh.resource_tile_ids["gold"]:
			return "Gold"
	
	return "None"
