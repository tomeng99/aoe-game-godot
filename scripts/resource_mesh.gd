extends TileMapLayer

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var resource_data: Dictionary = {}
@export var tracked_characters: Dictionary = {}

# TODO Should probably be handled in some type of layer config and not in code
@export var gold_tile_id: int = 0
@export var iron_tile_id: int = 1

@export var total_resource_amount: int = 5
@export var required_time: int = 2

func _ready():
	if multiplayer.is_server():
		spawn_resource("iron", Vector2i(5, 5))
		spawn_resource("gold", Vector2i(10, 5))

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

		if multiplayer_synchronizer:
			multiplayer_synchronizer.notify_property_list_changed()

		print("Spawned", resource_type, "at:", tile_position)
	else:
		print("Error: Could not find tile for", resource_type)

func _process(_delta):
	if multiplayer.is_server():
		check_character_positions()
		return

	for tile_position in resource_data.keys():
		var tile_info = resource_data[tile_position]
		
		if tile_info["tile_id"] == -1:
			set_cell(tile_position, -1)
		else:
			set_cell(tile_position, tile_info["tile_id"], Vector2i(0, 0))

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

	if tile_position in resource_data:
		resource_data.erase(tile_position)

	if multiplayer_synchronizer:
		multiplayer_synchronizer.notify_property_list_changed()

	print("Resource at", tile_position, "fully removed!")

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
