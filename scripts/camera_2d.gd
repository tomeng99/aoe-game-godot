extends Camera2D

# Variables for movement speed and map boundaries
@export var move_speed: float = 500.0
@export var map_width: float = 5000.0
@export var map_height: float = 5000.0

# Called every frame
func _process(delta: float) -> void:
	var direction = Vector2.ZERO
	
	# Move the camera with arrow keys or WASD keys
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1

	# Normalize direction to ensure consistent movement speed
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		
	# Move the camera by adjusting its position
	position += direction * move_speed * delta
	
	# Clamp the camera's position within the map boundaries
	position.x = clamp(position.x, 0, map_width)
	position.y = clamp(position.y, 0, map_height)
