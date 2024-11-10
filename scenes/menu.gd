extends Node2D

signal start_server()
signal start_client(client_name)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_server_pressed() -> void:
	start_server.emit()
	

func _on_client_pressed() -> void:
	start_client.emit($ClientName.text)
