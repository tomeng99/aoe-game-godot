extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_click)

func _on_click(body: Node2D):
	if multiplayer.is_server():
		var scoreboard_points_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Points")
		
		var points_name = "Points_" + str(body.get_multiplayer_authority())
		var points_node = scoreboard_points_node.get_node_or_null(points_name)
		
		if points_node == null:
			points_node = preload("res://scenes/Score.tscn").instantiate()
			points_node.text = str(1)
			points_node.name = points_name
			scoreboard_points_node.add_child(points_node)
			
			var scoreboard_names_node = get_tree().get_root().get_node_or_null("/root/Menu/Scoreboard/PanelContainer/Entries/Names")
			var name_label = preload("res://scenes/Score.tscn").instantiate()
			name_label.text = str(body.get_multiplayer_authority())
			scoreboard_names_node.add_child(name_label)
		else:
			points_node.text = str(int(points_node.text)+1)
			

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
