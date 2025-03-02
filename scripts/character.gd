extends CharacterBody2D

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@export var move_speed: float = 200.0
var selected: bool = false
var target_position: Vector2 = Vector2.ZERO
var stop_threshold: float = 5.0


func _ready():
	modulate = Color(1, 1, 1, 0.5)
	target_position = global_position


func _physics_process(delta: float):
	if not is_multiplayer_authority():
		return
		
	navigation_agent_2d.target_position = target_position
	
	var current_agent_position = global_position
	var next_path_position = navigation_agent_2d.get_next_path_position()
	
	var new_velocity = current_agent_position.direction_to(next_path_position) * move_speed
	new_velocity.x = clamp(new_velocity.x, -move_speed, move_speed)
	
	if navigation_agent_2d.is_navigation_finished():
		return
	
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	move_and_slide()


func select():
	selected = true
	modulate = Color(1, 1, 1, 1)

func deselect():
	selected = false
	modulate = Color(1, 1, 1, 0.5)

func move_to(position: Vector2):
	target_position = position

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
