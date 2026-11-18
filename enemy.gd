
extends CharacterBody2D

@export var speed: float = 100.0

var player: CharacterBody2D = null
var player_chase: bool = false

func _physics_process(delta: float) -> void:
	if player_chase and is_instance_valid(player):
		# Find direction toward player
		var direction = (player.global_position - global_position).normalized()
		# Move toward player
		velocity = direction * speed
	else:
		# Stop moving
		velocity = Vector2.ZERO
	move_and_slide()


# -------- DETECTION AREAS -------- #

func _on_enter_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player = body as CharacterBody2D
		player_chase = true


func _on_exit_body_exited(body: Node2D) -> void:
	if body == player:
		player_chase = false
		player = null
