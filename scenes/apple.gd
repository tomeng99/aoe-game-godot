extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.area_entered.connect(_on_click)

func _on_click(area: Area2D):
	if multiplayer.is_server():
		var overlapper = area.get_overlapping_bodies()[0]
		print("Eaten by ", overlapper.get_multiplayer_authority())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
