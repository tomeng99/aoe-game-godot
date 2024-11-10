extends Node2D

var selection_start: Vector2 = Vector2.ZERO
var selection_end: Vector2 = Vector2.ZERO
var selecting: bool = false
var selected_characters: Array = []

@onready var selection_box: ColorRect = $Control/SelectionBox
@onready var characters_node = $Characters  # The parent node where new characters will be added
@export var player_scene: PackedScene # The parent node where new characters will be added


func _ready():
	selection_box.visible = false

func _enter_tree():
	set_multiplayer_authority(name.to_int())  # Ensure authority is set based on the player ID

func _input(event):
	if is_multiplayer_authority():  # Only allow input handling if this peer is the authority
		handle_input(event)
		#print(name.to_int())


func handle_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_selection(event.position)
			else:
				end_selection(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and not selecting and event.pressed:
			move_selected_characters(event.position)

	if event is InputEventMouseMotion and selecting:
		update_selection(event.position)

	if event.is_action_pressed("ui_cancel"):  # Esc key to deselect all
		deselect_all_characters()

func start_selection(position: Vector2):
	selection_start = position
	selection_end = position
	selecting = true
	selection_box.visible = true
	selection_box.position = selection_start
	selection_box.size = Vector2.ZERO

func update_selection(position: Vector2):
	selection_end = position
	# Sets position for the start of colorrect drawing
	selection_box.position = Vector2(min(selection_start.x, selection_end.x), min(selection_start.y, selection_end.y))
	selection_box.size = (selection_end - selection_start).abs()

	#print("Update selection")
	for character in characters_node.get_children():
		#print(character)
		if get_selection_rect().has_point(character.global_position):
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
	for character in selected_characters:
		character.move_to(target_position)

func deselect_all_characters():
	for character in selected_characters:
		character.deselect()
	selected_characters.clear()
	
func _on_button_pressed():
	# Notify all clients to add this character to their Characters node
	rpc_add_character.rpc(Vector2(randf() * 500, randf() * 500), multiplayer.get_unique_id())

@rpc("any_peer", "call_local")
func rpc_add_character(position, authority):
	if !multiplayer.is_server():
		return
	print("Is server:", multiplayer.is_server())
	var scene_instance = player_scene.instantiate()
	scene_instance.global_position = position
		
	# Ensure authority is set correctly
	#scene_instance.set_multiplayer_authority(authority)
	#print("spawned minion for ", authority, " on ", multiplayer.get_unique_id())
		
	# Add MultiplayerSynchronizer if needed
	if not scene_instance.has_node("MultiplayerSynchronizer"):
		var sync = MultiplayerSynchronizer.new()
		sync.name = "MultiplayerSynchronizer"
		scene_instance.add_child(sync)
		
	print(characters_node)
	characters_node.add_child(scene_instance)
