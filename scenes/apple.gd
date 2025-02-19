extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_click)

func _on_click(body: Node2D):
	if multiplayer.is_server():
		var scoreboard_path = "/root/Menu/Scoreboard" # + str(multiplayer.get_unique_id())
		var scoreboard_node = get_tree().get_root().get_node_or_null(scoreboard_path)
		#player_node.get_node("Points").text = str(int(player_node.get_node("Points").text)+1)
		var points_name = "Points" + str(body.get_multiplayer_authority())
		var points_node = scoreboard_node.get_node_or_null(points_name)
		if points_node == null:
			var label = preload("res://scenes/Score.tscn").instantiate()
			label.get_node("Label").text = str(body.get_multiplayer_authority()) + ": 1"
			label.name = points_name
			label.global_position.y = 15 + scoreboard_node.get_child(-1).position.y
			scoreboard_node.add_child(label)
			#print("points++ for ", body.get_multiplayer_authority())
		else:
			var parts = points_node.get_node("Label").text.split(" ")
			points_node.get_node("Label").text = parts[0] + " " + str(int(parts[1])+1)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
