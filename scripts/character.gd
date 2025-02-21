extends CharacterBody2D

@export var move_speed: float = 200.0
var selected: bool = false
var target_position: Vector2 = Vector2.ZERO
var stop_threshold: float = 5.0  # Threshold distance to consider the character has "arrived"


func _ready():
	modulate = Color(1, 1, 1, 0.5)
	target_position = global_position

func _physics_process(delta: float):
	var distance_to_target = global_position.distance_to(target_position)
	if distance_to_target > stop_threshold:
		var direction = (target_position - global_position).normalized()
		velocity = direction * move_speed
		rotation = direction.angle() + 90
		move_and_slide()
	else:
		velocity = Vector2.ZERO  # Stop moving when within the threshold
		global_position = target_position  # Snap to the target position

func select():
	selected = true
	modulate = Color(1, 1, 1, 1)  # Highlight the character

func deselect():
	selected = false
	modulate = Color(1, 1, 1, 0.5)  # Revert highlight

func move_to(position: Vector2):
	target_position = position
