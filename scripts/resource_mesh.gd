extends TileMapLayer

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var resource_data: Dictionary = {}
@export var resource_updates: Dictionary = {}

@export var tracked_characters: Dictionary = {}

# TODO Should probably be handled in some type of layer config and not in code
@export var gold_tile_id: int = 0
@export var iron_tile_id: int = 1

@export var total_resource_amount: int = 5
@export var required_time: int = 2

var noise = FastNoiseLite.new()

@export var map_size: Vector2i = Vector2i(100, 100)
@export var noise_scale: float = 5.0
@export var gold_threshold: float = 0.4
@export var iron_threshold: float = -0.4

func _ready():
	if multiplayer.is_server():
		noise.seed = randi()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise.frequency = 1.0 / noise_scale
		spawn_resources_with_noise()

	var check_timer = Timer.new()
	check_timer.wait_time = 1
	check_timer.autostart = true
	check_timer.timeout.connect(_check_players)
	add_child(check_timer)

func spawn_resource(resource_type: String, tile_position: Vector2i):
	var tile_id = get_tile_id(resource_type)
	if tile_id != -1:
		set_cell(tile_position, tile_id, Vector2i(0, 0))
		resource_data[tile_position] = {"tile_id": tile_id, "remaining": total_resource_amount}
		resource_updates[tile_position] = tile_id 

		if multiplayer_synchronizer:
			multiplayer_synchronizer.notify_property_list_changed()

		
func spawn_resources_with_noise():
	for x in range(map_size.x):
		for y in range(map_size.y):
			var noise_value = noise.get_noise_2d(x / noise_scale, y / noise_scale)
			
			if noise_value > gold_threshold:
				spawn_resource("gold", Vector2i(x, y))
			elif noise_value < iron_threshold:
				spawn_resource("iron", Vector2i(x, y))

func _process(_delta):
	if multiplayer.is_server():
		check_character_positions()
		return

	# ✅ Only update tiles when `resource_updates` has changes
	if resource_updates.size() > 0:
		for tile_position in resource_updates.keys():
			var tile_id = resource_updates[tile_position]

			if tile_id == -1:
				set_cell(tile_position, -1)
			else:
				set_cell(tile_position, tile_id, Vector2i(0, 0))

		resource_updates.clear()

func check_character_positions():
	var characters_node = get_tree().get_root().get_node_or_null("/root/Menu/characters")
	if characters_node:
		for character in characters_node.get_children():
			var tile_pos = local_to_map(character.global_position)

			if tile_pos in resource_data:
				if character not in tracked_characters:
					_on_enter_tile(character, tile_pos)
			else:
				if character in tracked_characters:
					_on_exit_tile(character)

func _on_enter_tile(body: Node2D, tile_position: Vector2i):
	if multiplayer.is_server():
		print("Character", body.name, "entered tile", tile_position)
		tracked_characters[body] = {"tile": tile_position, "time": 0}

func _on_exit_tile(body: Node2D):
	if multiplayer.is_server() and body in tracked_characters:
		print("Character", body.name, "left tile")
		tracked_characters.erase(body)

func _check_players():
	if multiplayer.is_server():
		for character in tracked_characters.keys():
			tracked_characters[character]["time"] += 1
			
			var tile_pos = tracked_characters[character]["tile"]
			if tracked_characters[character]["time"] >= required_time:
				tracked_characters[character]["time"] = 0
				collect_resource(tile_pos, character)

func collect_resource(tile_position: Vector2i, player: Node2D):
	if tile_position in resource_data:
		var remaining = resource_data[tile_position]["remaining"]

		resource_data[tile_position]["remaining"] -= 1
		update_scoreboard(player)

		print("Player", player.name, "collected resource at", tile_position, 
			  "Remaining:", resource_data[tile_position]["remaining"])

		if resource_data[tile_position]["remaining"] <= 0:
			remove_resource(tile_position)
			
func remove_resource(tile_position: Vector2i):
	if !multiplayer.is_server():
		return

	print("Server removing resource at:", tile_position)

	set_cell(tile_position, -1)
	resource_updates[tile_position] = -1

	if tile_position in resource_data:
		resource_data.erase(tile_position)

	if multiplayer_synchronizer:
		multiplayer_synchronizer.notify_property_list_changed()

func update_scoreboard(player: Node2D):
	var scoreboard_points_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Points")
	
	if scoreboard_points_node:
		var points_name = "Points_" + str(player.get_multiplayer_authority())
		var points_node = scoreboard_points_node.get_node_or_null(points_name)
		if points_node:
			points_node.text = str(int(points_node.text) + 1)

func get_tile_id(resource_type: String) -> int:
	match resource_type:
		"gold":
			return gold_tile_id
		"iron":
			return iron_tile_id
		_:
			return -1
