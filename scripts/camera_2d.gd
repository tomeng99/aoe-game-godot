extends Camera2D

@export var move_speed: float = 500.0
@export var map_width: float = 5000.0
@export var map_height: float = 5000.0

# Reference to the Player node (parent of Camera)
@onready var player = get_parent()  # ✅ Player is the parent of the camera

func _process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	# Move the player (which also moves the camera)
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1

	# Normalize direction to maintain consistent speed
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Move the Player (not just the camera)
	player.position += direction * move_speed * delta

	# Clamp the player's position within map boundaries
	player.position.x = clamp(player.position.x, 0, map_width)
	player.position.y = clamp(player.position.y, 0, map_height)
