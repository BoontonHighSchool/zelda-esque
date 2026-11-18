extends CharacterBody2D

# --------------------------------------------------
# VARIABLES
# --------------------------------------------------

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var speed: float = 100.0
@export var stop_distance: float = 40.0
@export var attack_cooldown_time: float = 1.5

var current_state: State = State.IDLE
var player: CharacterBody2D = null
var player_chase: bool = false

# Direction:
# 0 = East / Right
# 1 = South / Down
# 2 = West / Left
# 3 = North / Up

var facing_direction: int = 0


# --------------------------------------------------
# NODE REFERENCES
# --------------------------------------------------

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Attack
@onready var attack_cooldown: Timer = $AttackCooldown


# --------------------------------------------------
# READY
# --------------------------------------------------

func _ready() -> void:
	attack_cooldown.wait_time = attack_cooldown_time

	update_attack_direction()
	play_current_animation()


# --------------------------------------------------
# PHYSICS PROCESS
# --------------------------------------------------

func _physics_process(_delta: float) -> void:

	# No valid player: stop moving and return to idle.
	if not player_chase or not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		change_state(State.IDLE)
		return

	# Calculate direction and distance to player.
	var offset: Vector2 = player.global_position - global_position
	var distance: float = offset.length()

	# Update the direction the enemy faces.
	if distance > 0.001:
		update_facing_direction(offset.normalized())

	# --------------------------------------------------
	# MOVEMENT
	# --------------------------------------------------

	# Continue moving toward the player until stop distance.
	if distance > stop_distance:
		var direction: Vector2 = offset.normalized()
		velocity = direction * speed

		# Do not interrupt an attack animation.
		if current_state != State.ATTACK:
			change_state(State.CHASE)

	else:
		velocity = Vector2.ZERO

		# Do not interrupt an attack animation.
		if current_state != State.ATTACK:
			change_state(State.IDLE)

	# --------------------------------------------------
	# ATTACKING
	# --------------------------------------------------

	# Attack whenever the player is in range
	# and the cooldown has finished.
	if attack_area.overlaps_body(player):
		if attack_cooldown.is_stopped() and current_state != State.ATTACK:
			start_attack()

	# Apply movement.
	move_and_slide()


# --------------------------------------------------
# FACING DIRECTION
# --------------------------------------------------

func update_facing_direction(direction: Vector2) -> void:

	var new_direction: int

	if abs(direction.x) >= abs(direction.y):

		if direction.x >= 0.0:
			new_direction = 0
		else:
			new_direction = 2

	else:

		if direction.y >= 0.0:
			new_direction = 1
		else:
			new_direction = 3

	if new_direction != facing_direction:
		facing_direction = new_direction

		update_attack_direction()
		play_current_animation()


# --------------------------------------------------
# ATTACK AREA ROTATION
# --------------------------------------------------

func update_attack_direction() -> void:

	attack_area.rotation = facing_direction * PI / 2.0


# --------------------------------------------------
# ANIMATION CONTROL
# --------------------------------------------------

func play_current_animation() -> void:

	var animation_name: String

	match current_state:

		State.IDLE:
			animation_name = "idle" + str(facing_direction)

		State.CHASE:
			animation_name = "chase" + str(facing_direction)

		State.ATTACK:
			animation_name = "attack" + str(facing_direction)

		State.DEAD:
			animation_name = "death"

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("Missing enemy animation: " + animation_name)
		return

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func change_state(new_state: State) -> void:

	if current_state == new_state:
		return

	current_state = new_state
	play_current_animation()


# --------------------------------------------------
# ATTACKING
# --------------------------------------------------

func start_attack() -> void:

	change_state(State.ATTACK)
	attack_cooldown.start()


# --------------------------------------------------
# ANIMATION FINISHED SIGNAL
# --------------------------------------------------

func _on_animated_sprite_2d_animation_finished() -> void:

	if current_state == State.ATTACK:

		if player_chase and is_instance_valid(player):
			change_state(State.CHASE)
		else:
			change_state(State.IDLE)

	elif current_state == State.DEAD:
		pass


# --------------------------------------------------
# PLAYER DETECTION
# --------------------------------------------------

func _on_enter_body_entered(body: Node2D) -> void:

	if body.is_in_group("player") or body.name == "Player":

		if body is CharacterBody2D:

			player = body
			player_chase = true

			change_state(State.CHASE)


func _on_exit_body_exited(body: Node2D) -> void:

	if body == player:

		player_chase = false
		player = null

		velocity = Vector2.ZERO

		change_state(State.IDLE)


# --------------------------------------------------
# DAMAGE FLASH
# --------------------------------------------------

func flash_sprite() -> void:

	var sprite_material := animated_sprite.material as ShaderMaterial

	if sprite_material == null:
		push_warning("Assign a ShaderMaterial to AnimatedSprite2D first.")
		return

	var tween := create_tween()

	tween.tween_method(
		func(amount: float):
			sprite_material.set_shader_parameter("flash_amount", amount),
		0.0, 1.0, 0.05
	)

	tween.tween_method(
		func(amount: float):
			sprite_material.set_shader_parameter("flash_amount", amount),
		1.0, 0.0, 0.10
	)
