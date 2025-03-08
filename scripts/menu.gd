extends Node2D

var peer = ENetMultiplayerPeer.new()

@onready var menu_bar = $MenuBar

func _on_host_pressed():
	# Set up server
	peer.create_server(25565)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	
	# Add the main scene first
	#var main = main_scene.instantiate()
	#add_child(main)
	var resources = preload("res://scenes/resourceMesh.tscn").instantiate()
	add_child(resources)
	var scoreboard = preload("res://scenes/Scoreboard.tscn").instantiate()
	scoreboard.global_position = Vector2(800, 100)
	add_child(scoreboard)
	
	# Add FPS counter for the host
	_add_fps_counter()
	
	# Then add the local player
	_add_player(multiplayer.get_unique_id())
	menu_bar.queue_free()  # Remove the MenuBar after logic

func _add_player(id):
	var player = preload("res://scenes/Player.tscn").instantiate()
	player.name = "Player_" + str(id)
	player.set_multiplayer_authority(id)
	add_child(player)
	
	# Set up scoreboard
	var scoreboard_points_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Points")
	var points_name = "Points_" + str(id)
	var points_node = preload("res://scenes/Score.tscn").instantiate()
	points_node.text = "0"
	points_node.name = points_name
	scoreboard_points_node.add_child(points_node)
	var scoreboard_names_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Names")
	var name_label = preload("res://scenes/Score.tscn").instantiate()
	name_label.text = str(id)
	name_label.name = points_name
	scoreboard_names_node.add_child(name_label)

func _on_join_pressed():
	# Set up client
	var chosen_ip = $MenuBar/TextEdit.text
	peer.create_client(chosen_ip, 25565)
	multiplayer.multiplayer_peer = peer
	
	# Add FPS counter for the client
	_add_fps_counter()
	
	menu_bar.queue_free()

func _add_fps_counter():
	# Add FPS counter to the UI
	var fps_counter = preload("res://scenes/FPSCounter.tscn").instantiate()
	
	# Create a CanvasLayer to ensure the FPS counter is always on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "FPSCounterLayer"
	canvas_layer.layer = 100  # High layer value to be on top
	
	# Add the FPS counter to the canvas layer
	canvas_layer.add_child(fps_counter)
	
	# Position the FPS counter in the top-right corner
	fps_counter.anchor_left = 1.0
	fps_counter.anchor_right = 1.0
	fps_counter.offset_left = -100
	fps_counter.offset_right = -10
	fps_counter.offset_top = 10
	
	# Add the canvas layer to the scene
	add_child(canvas_layer)
