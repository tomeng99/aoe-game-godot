extends Node2D

@export var resource_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_resource("iron", Vector2(100, 100))
	spawn_resource("gold", Vector2(200, 100))


func spawn_resource(resource_type: String, spawn_position: Vector2):
	var resource_instance = resource_scene.instantiate()
	resource_instance.position = spawn_position
	resource_instance.resource_name = resource_type
	add_child(resource_instance)
	print("Spawned", resource_type, "at:", spawn_position)
