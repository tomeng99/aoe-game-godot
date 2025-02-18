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
	var apple = preload("res://scenes/apple.tscn").instantiate()
	apple.global_position = Vector2(100, 100)
	add_child(apple)
	
	# Then add the local player
	_add_player(multiplayer.get_unique_id())
	menu_bar.queue_free()  # Remove the MenuBar after logic

func _add_player(id):
	var player = preload("res://scenes/Player.tscn").instantiate()
	player.name = "Player_" + str(id)
	player.set_multiplayer_authority(id)
	add_child(player)

func _on_join_pressed():
	# Set up client
	var chosen_ip = $MenuBar/TextEdit.text
	peer.create_client(chosen_ip, 25565)
	multiplayer.multiplayer_peer = peer
	menu_bar.queue_free()
