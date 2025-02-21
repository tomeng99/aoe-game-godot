extends Node2D

@export var resource_name: String = "Generic Resource"
@export var total_resource_amount: int = 10
@export var required_time: int = 2

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the sprite

@export var gold_texture: Texture2D
@export var iron_texture: Texture2D


var tracked_players = {}
var extracted_resource = 0

func _ready() -> void:
	print("Create resource")
	apply_texture();
	$Area2D.body_entered.connect(_on_enter)
	$Area2D.body_exited.connect(_on_exit)
	
	var check_timer = Timer.new()
	check_timer.wait_time = 1
	check_timer.autostart = true
	check_timer.timeout.connect(_check_players)
	add_child(check_timer)

func _on_enter(body: Node2D):
	if multiplayer.is_server():
		tracked_players[body] = 0

func _on_exit(body: Node2D):
	if body in tracked_players:
		tracked_players.erase(body)

func _check_players():
	if multiplayer.is_server():
		for player in tracked_players.keys():
			tracked_players[player] += 1
			
			if tracked_players[player] >= required_time:
				tracked_players[player] -= required_time
				update_scoreboard(player)
				extracted_resource += 1				
				if extracted_resource >= total_resource_amount:
					despawn_resource()

func update_scoreboard(body: Node2D):
	var scoreboard_points_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Points")
	
	if scoreboard_points_node:
		var points_name = "Points" + "_" + str(body.get_multiplayer_authority())
		var points_node = scoreboard_points_node.get_node_or_null(points_name)
		points_node.text = str(int(points_node.text) + 1)

func despawn_resource():
	print(resource_name, "depleted! Despawning...")
	queue_free()  # Remove from scene
	
func apply_texture():
	match resource_name:
		"gold":
			sprite.texture = gold_texture
		"iron":
			sprite.texture = iron_texture
		_:
			print("Unknown resource type:", resource_name)
