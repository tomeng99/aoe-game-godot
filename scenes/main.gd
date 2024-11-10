extends Node2D

@onready var Lobby = $Lobby
@onready var Menu = $Menu
var Game = preload("res://scenes/Game.tscn").instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass #Lobby.player_loaded.rpc_id(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func start_game():
	print("Started Game")


func _on_menu_start_client(client_name: Variant) -> void:
	Lobby.player_info = {"name": client_name }
	Lobby.join_game()
	remove_child(Menu)
	add_child(Game)


func _on_menu_start_server() -> void:
	print("Start server")
	Lobby.player_info = {"name": "Server"}
	Lobby.create_game()
	remove_child(Menu)
	add_child(Game)


func _on_lobby_player_connected(peer_id: Variant, player_info: Variant) -> void:
	print("On ", multiplayer.get_unique_id(), " connect ", player_info, "with ID ", peer_id)
	Game.get_child(0).text += player_info["name"] + "\n"
	if multiplayer.is_server():
		var character = preload("res://scenes/Character.tscn").instantiate()
		character.global_position = Vector2(randf() * 100, randf() * 100)
		character.set_multiplayer_authority(1)
		Game.add_child(character)
