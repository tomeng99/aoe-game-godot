extends Node2D

var peer = ENetMultiplayerPeer.new()
@export var main_scene: PackedScene

@onready var menu_bar = $MenuBar

func _on_host_pressed():
	# Set up server
	peer.create_server(25566)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()  # Add the local player
	menu_bar.queue_free()  # Remove the MenuBar after logic

func _add_player(id = 1):
	var player = main_scene.instantiate()
	player.name = "Player_" + str(id)
	player.set_multiplayer_authority(id)
	add_child(player)

func _on_join_pressed():
	# Set up client
	var chosen_ip = $MenuBar/TextEdit.text
	peer.create_client(chosen_ip, 25566)
	multiplayer.multiplayer_peer = peer
	menu_bar.queue_free()
	
