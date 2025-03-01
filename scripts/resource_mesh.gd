extends Node2D

@onready var terrain_layer: TileMapLayer = $"ResourceMesh_Terrain"
@onready var resource_layer: TileMapLayer = $"ResourceMesh_Resource"
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var terrain_data: Dictionary = {}
@export var resource_data: Dictionary = {}
@export var tracked_characters: Dictionary = {}

# Synchronized properties
@export var current_chunk_updates: Dictionary = {}
@export var current_chunk_position: Vector2i = Vector2i(-1, -1)
@export var initial_sync_complete: bool = false

var chunk_size: Vector2i = Vector2i(16, 16)
var dirty_chunks: Array = []
var pending_updates: Dictionary = {}
var chunks_to_sync: Array = []

@export var total_resource_amount: int = 5
@export var required_time: int = 2

var noise = FastNoiseLite.new()

@export var map_size: Vector2i = Vector2i(100, 100)
@export var noise_scale: float = 5.0

var resource_tile_ids: Dictionary = {}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	if multiplayer.is_server():
		print("Server is generating the map...")
		noise.seed = randi()
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise.frequency = 0.05  # For terrain
		
		# Create separate noise for resources
		var resource_noise = FastNoiseLite.new()
		resource_noise.seed = randi()  # Different seed than terrain
		resource_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		resource_noise.frequency = 0.2  # Higher frequency for smaller clusters
		
		load_tile_ids()
		generate_terrain()
		spawn_resources_clusters(resource_noise)
		
		# Prepare initial sync
		_prepare_full_map_sync()
	else:
		print("Client is waiting for map sync...")

	var sync_timer = Timer.new()
	sync_timer.wait_time = 0.1
	sync_timer.autostart = true
	sync_timer.timeout.connect(_process_chunk_updates)
	add_child(sync_timer)

	# Add timer for checking character positions
	var check_timer = Timer.new()
	check_timer.wait_time = 1
	check_timer.autostart = true
	check_timer.timeout.connect(_check_players)
	add_child(check_timer)

func queue_update(pos: Vector2i, data: Dictionary, is_terrain: bool = true):
	var chunk_pos = Vector2i(pos.x / chunk_size.x, pos.y / chunk_size.y)
	print("[Server] Queueing update for chunk: ", chunk_pos, " tile: ", pos, " data: ", data)
	
	if not pending_updates.has(chunk_pos):
		pending_updates[chunk_pos] = {"terrain": {}, "resources": {}}
		if not dirty_chunks.has(chunk_pos):
			dirty_chunks.append(chunk_pos)
	
	if is_terrain:
		pending_updates[chunk_pos]["terrain"][pos] = data
	else:
		pending_updates[chunk_pos]["resources"][pos] = data
		print("[Server] Added resource update to pending updates: ", pending_updates[chunk_pos])

func _physics_process(delta):
	if not multiplayer.is_server():
		return
		
	if not initial_sync_complete:
		_handle_initial_sync()
		return
	
	# Process dirty chunks
	if not dirty_chunks.is_empty():
		var chunk_pos = dirty_chunks[0]
		if pending_updates.has(chunk_pos):
			print("[Server] Sending updates for chunk: ", chunk_pos, " updates: ", pending_updates[chunk_pos])
			_apply_chunk_updates.rpc(pending_updates[chunk_pos])
			pending_updates.erase(chunk_pos)
		dirty_chunks.remove_at(0)

func _prepare_full_map_sync():
	chunks_to_sync.clear()
	for x in range(0, map_size.x, chunk_size.x):
		for y in range(0, map_size.y, chunk_size.y):
			chunks_to_sync.append(Vector2i(x / chunk_size.x, y / chunk_size.y))
	initial_sync_complete = false

func _process_chunk_updates():
	if not multiplayer.is_server():
		return
		
	if not initial_sync_complete and not chunks_to_sync.is_empty():
		# Handle initial full map sync
		var chunk_pos = chunks_to_sync.pop_front()
		_sync_chunk(chunk_pos)
		if chunks_to_sync.is_empty():
			initial_sync_complete = true
			print("✅ Initial map sync complete!")
	elif not dirty_chunks.is_empty():
		# Handle regular updates
		var chunk_pos = dirty_chunks.pop_front()
		if chunk_pos != null and pending_updates.has(chunk_pos):
			_sync_chunk(chunk_pos)
			pending_updates.erase(chunk_pos)

func _sync_chunk(chunk_pos: Vector2i):
	current_chunk_position = chunk_pos
	current_chunk_updates = _get_chunk_data(chunk_pos)

func _get_chunk_data(chunk_pos: Vector2i) -> Dictionary:
	var chunk_data = {
		"terrain": {},
		"resources": {}
	}
	
	var start_x = chunk_pos.x * chunk_size.x
	var start_y = chunk_pos.y * chunk_size.y
	
	for x in range(start_x, min(start_x + chunk_size.x, map_size.x)):
		for y in range(start_y, min(start_y + chunk_size.y, map_size.y)):
			var pos = Vector2i(x, y)
			if terrain_data.has(pos):
				chunk_data.terrain[pos] = terrain_data[pos]
			if resource_data.has(pos):
				chunk_data.resources[pos] = resource_data[pos]
	
	return chunk_data

func _process(_delta):
	if not multiplayer.is_server():
		# Apply received updates on clients
		if current_chunk_position != Vector2i(-1, -1):
			_apply_chunk_updates(current_chunk_updates)
			current_chunk_position = Vector2i(-1, -1)
			current_chunk_updates.clear()

@rpc("any_peer", "call_local", "reliable")
func _apply_chunk_updates(updates: Dictionary):
	print("Applying chunk updates for client....")
	if updates.has("terrain"):
		for pos in updates.terrain:
			terrain_data[pos] = updates.terrain[pos]
			var data = terrain_data[pos]
			terrain_layer.set_cell(pos, data.source_id, data.atlas_coords)

	if updates.has("resources"):
		for pos in updates.resources:
			var data = updates.resources[pos]
			if data.source_id == -1:
				# Resource was removed
				resource_layer.erase_cell(pos)
				if pos in resource_data:
					resource_data.erase(pos)
			else:
				# Resource was updated or added
				resource_data[pos] = data
				resource_layer.set_cell(pos, data.source_id, data.atlas_coords)

func load_tile_ids():
	var tile_map_set = terrain_layer.tile_set
	if not tile_map_set:
		push_error("TileSet not found!")
		return

	resource_tile_ids.clear()

	resource_tile_ids["grass"] = Vector2i(6, 8)
	resource_tile_ids["water"] = Vector2i(4, 8)
	resource_tile_ids["sand"] = Vector2i(4, 9)
	resource_tile_ids["iron"] = Vector2i(3, 7)
	resource_tile_ids["gold"] = Vector2i(2, 7)
	resource_tile_ids["house"] = Vector2i(6, 6)

func generate_terrain():
	print("Generating terrain...")
	for x in range(map_size.x):
		for y in range(map_size.y):
			var tile_position = Vector2i(x, y)
			var noise_value = noise.get_noise_2d(float(x) / noise_scale, float(y) / noise_scale)
			
			var tile_type = "grass"
			if noise_value < -0.2:  # Increased to create more water
				tile_type = "water"
			elif noise_value < 0.0:  # Beaches
				tile_type = "sand"
			
			var tile_index = resource_tile_ids.get(tile_type, null)
			if tile_index != null:
				terrain_layer.set_cell(tile_position, 1, tile_index)
				terrain_data[tile_position] = { "source_id": 1, "atlas_coords": tile_index }
				queue_update(tile_position, terrain_data[tile_position], true)

	# Add sand borders around water
	var water_borders = []
	for x in range(map_size.x):
		for y in range(map_size.y):
			var pos = Vector2i(x, y)
			if terrain_data.has(pos) and _is_water_tile(pos):
				for neighbor in _get_neighbors(pos):
					if terrain_data.has(neighbor) and not _is_water_tile(neighbor) and not _is_sand_tile(neighbor):
						water_borders.append(neighbor)
	
	# Apply sand borders
	for pos in water_borders:
		var sand_data = resource_tile_ids["sand"]
		terrain_layer.set_cell(pos, 1, sand_data)
		terrain_data[pos] = { "source_id": 1, "atlas_coords": sand_data }
		queue_update(pos, terrain_data[pos], true)

func spawn_resources_clusters(resource_noise: FastNoiseLite):
	print("Spawning resource clusters...")
	var gold_count = 0
	var iron_count = 0
	
	# Parameters for resource clusters
	var cluster_threshold = 0.6  # Only spawn resources at high noise values
	var min_cluster_size = 4
	var max_cluster_size = 10
	var min_distance_between_clusters = 10
	var existing_clusters = []
	
	# First pass - find potential cluster centers
	for x in range(map_size.x):
		for y in range(map_size.y):
			var tile_position = Vector2i(x, y)
			
			# Skip if invalid terrain
			if _is_water_tile(tile_position) or _is_sand_tile(tile_position) or is_near_water(tile_position):
				continue
			
			# Skip if too close to existing clusters
			var too_close = false
			for cluster in existing_clusters:
				if tile_position.distance_to(cluster) < min_distance_between_clusters:
					too_close = true
					break
			if too_close:
				continue
			
			var noise_value = resource_noise.get_noise_2d(float(x), float(y))
			if abs(noise_value) > cluster_threshold:
				# Decide cluster type and size
				var is_gold = noise_value > 0
				var cluster_size = randi_range(min_cluster_size, max_cluster_size)
				
				# Generate cluster
				var resources_placed = 0
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						if resources_placed >= cluster_size:
							break
							
						var cluster_pos = Vector2i(x + dx, y + dy)
						if cluster_pos.x < 0 or cluster_pos.x >= map_size.x or cluster_pos.y < 0 or cluster_pos.y >= map_size.y:
							continue
							
						if _is_water_tile(cluster_pos) or _is_sand_tile(cluster_pos) or is_near_water(cluster_pos):
							continue
							
						# Random chance to skip some positions for more natural looking clusters
						if randf() > 0.7:
							continue
							
						if is_gold:
							_spawn_resource("gold", cluster_pos)
							gold_count += 1
						else:
							_spawn_resource("iron", cluster_pos)
							iron_count += 1
						
						resources_placed += 1
				
				existing_clusters.append(tile_position)
	
	print("Resource spawning complete - Gold: ", gold_count, ", Iron: ", iron_count)

func _spawn_resource(resource_type: String, tile_position: Vector2i):
	var tile_data = resource_tile_ids.get(resource_type, null)
	if tile_data != null:
		resource_layer.set_cell(tile_position, 1, tile_data)
		resource_data[tile_position] = {
			"source_id": 1,
			"atlas_coords": tile_data,
			"remaining": total_resource_amount
		}
		queue_update(tile_position, resource_data[tile_position], false)

func _is_water_tile(pos: Vector2i) -> bool:
	return terrain_data.has(pos) and terrain_data[pos]["atlas_coords"] == resource_tile_ids["water"]

func _is_sand_tile(pos: Vector2i) -> bool:
	return terrain_data.has(pos) and terrain_data[pos]["atlas_coords"] == resource_tile_ids["sand"]

func _get_neighbors(pos: Vector2i) -> Array:
	return [
		Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x - 1, pos.y),
		Vector2i(pos.x, pos.y + 1),
		Vector2i(pos.x, pos.y - 1)
	]

func is_near_water(tile_pos: Vector2i) -> bool:
	for neighbor in _get_neighbors(tile_pos):
		if _is_water_tile(neighbor):
			return true
	return false

func _check_players():
	if multiplayer.is_server():
		var characters_node = get_tree().get_root().get_node_or_null("/root/Menu/characters")
		if characters_node:
			for character in characters_node.get_children():
				var tile_pos = terrain_layer.local_to_map(character.global_position)
					
				if tile_pos in resource_data:
					if not character in tracked_characters:
						tracked_characters[character] = {"tile": tile_pos, "time": 0}
					else:
						tracked_characters[character]["time"] += 1
						if tracked_characters[character]["time"] >= required_time:
							tracked_characters[character]["time"] = 0
							collect_resource(tile_pos, character)
				else:
					if character in tracked_characters:
						tracked_characters.erase(character)

func collect_resource(tile_position: Vector2i, player: Node2D):
	if tile_position in resource_data:
		resource_data[tile_position]["remaining"] -= 1
		
		if resource_data[tile_position]["remaining"] <= 0:
			remove_resource(tile_position)
		
		var player_id = str(player.name).to_int()
		update_scoreboard(player)

func update_scoreboard(player: Node2D):
	var scoreboard_points_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Points")
	
	if scoreboard_points_node:
		var points_name = "Points_" + str(player.get_multiplayer_authority())
		var points_node = scoreboard_points_node.get_node_or_null(points_name)
		if points_node:
			points_node.text = str(int(points_node.text) + 1)

func remove_resource(tile_position: Vector2i):
	# Clear the resource tile
	resource_layer.set_cell(tile_position, -1)
	queue_update(tile_position, {"source_id": -1}, false)

	if tile_position in resource_data:
		resource_data.erase(tile_position)

func _handle_initial_sync():
	if chunks_to_sync.is_empty():
		_prepare_full_map_sync()
		
	if not chunks_to_sync.is_empty():
		var chunk_pos = chunks_to_sync[0]
		var updates = {
			"terrain": {},
			"resources": {}
		}
		
		# Get all tiles in this chunk
		var start_x = chunk_pos.x * chunk_size.x
		var start_y = chunk_pos.y * chunk_size.y
		var end_x = start_x + chunk_size.x
		var end_y = start_y + chunk_size.y
		
		for x in range(start_x, end_x):
			for y in range(start_y, end_y):
				var pos = Vector2i(x, y)
				if terrain_data.has(pos):
					updates.terrain[pos] = terrain_data[pos]
				if resource_data.has(pos):
					updates.resources[pos] = resource_data[pos]
		
		if not updates.terrain.is_empty() or not updates.resources.is_empty():
			print("[Server] Sending initial sync for chunk: ", chunk_pos, " updates: ", updates)
			_apply_chunk_updates.rpc(updates)
		
		chunks_to_sync.remove_at(0)
		if chunks_to_sync.is_empty():
			initial_sync_complete = true
			print("[Server] Initial sync complete")

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		print("New client connected: ", id, ", preparing sync...")
		# Prepare sync for this specific client
		_prepare_full_map_sync()
		# Start syncing chunks
		_handle_initial_sync()
