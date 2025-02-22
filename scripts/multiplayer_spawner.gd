extends Node

@rpc("any_peer", "call_local")
func rpc_request_spawn(position, authority):
	# check if allowed to do stuff?
	print("rpc_request_spawn called with position:", position, " authority:", authority)
	if multiplayer.is_server():
		print("Server received spawn request, calling rpc_add_character")
		rpc("rpc_add_character", position, authority)
	else:
		print("Client received spawn request (this shouldn't happen)")

@rpc("call_local", "authority")
func rpc_add_character(position, authority):
	print("rpc_add_character called with position:", position, " authority:", authority)
	
	var player_path = "/root/Menu/Player_" + str(authority)
	var player_node = get_tree().get_root().get_node_or_null(player_path)
	print("Looking for player at path:", player_path)
	
	if player_node:
		print("Found player node, spawning character")
		_spawn_character(position, authority)

func _spawn_character(position, authority):
	print("_spawn_character called")
	var characters = get_tree().get_root().get_node_or_null("/root/Menu/characters")
	var scene_instance = preload("res://scenes/Character.tscn").instantiate()
	scene_instance.global_position = position
	scene_instance.set_multiplayer_authority(authority)
	characters.add_child(scene_instance)
	print("Character spawned successfully for plsayer:", authority)

@rpc("any_peer", "call_local")
func rpc_request_delete(char_path: NodePath, authority):
	var charNode = get_node(char_path)
	if charNode.get_multiplayer_authority() == authority:
		print("Server received delete request for:", char_path)
		rpc("rpc_delete_character", char_path)

@rpc("any_peer", "call_local")
func rpc_delete_character(char_path: NodePath):
	var char = get_node_or_null(char_path)
	if char and char.is_inside_tree():
		print("Removing character:", char.name)
		char.queue_free()
	else:
		print("Character not found or already deleted!")
