extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_click)

func _on_click(body: Node2D):
	if multiplayer.get_unique_id() == body.get_multiplayer_authority():
		var player_path = "/root/Menu/Player_" + str(multiplayer.get_unique_id())
		var player_node = get_tree().get_root().get_node_or_null(player_path)
		player_node.get_node("Points").text = str(int(player_node.get_node("Points").text)+1)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
