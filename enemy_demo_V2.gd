
extends CharacterBody2D


# ==================================================
# VARIABLES
# ==================================================

# --- MOVEMENT ---
@export var speed: float = 100.0
@export var stop_distance: float = 40.0

# --- COMBAT ---
@export var attack_damage: int = 10
@export var attack_cooldown_time: float = 1.5

# --- HEALTH ---
@export var max_health: int = 100

var current_health: int

# --- STATES ---
enum State { IDLE, CHASE, ATTACK, DEAD }

var current_state: State = State.IDLE

# --- PLAYER DETECTION ---
var player: CharacterBody2D = null
var player_chase: bool = false

# Facing direction:
# 0 = Right, 1 = Down, 2 = Left, 3 = Up
var facing_direction: int = 0

# --- DAMAGE FLASH ---
var flash_tween: Tween


# ==================================================
# NODE REFERENCES
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Attack
@onready var attack_cooldown: Timer = $AttackCooldown


# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:

	current_health = max_health

	attack_cooldown.wait_time = attack_cooldown_time

	update_attack_direction()
	play_current_animation()


# ==================================================
# MAIN GAME LOOP
# ==================================================

func _physics_process(_delta: float) -> void:

	# Stop if the enemy is dead
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		return

	# Check for a valid player
	if not player_chase or not is_instance_valid(player):
		velocity = Vector2.ZERO
		change_state(State.IDLE)
		move_and_slide()
		return

	# Calculate direction and distance to player
	var offset: Vector2 = player.global_position - global_position
	var distance: float = offset.length()

	# Update facing direction
	if distance > 0.001:
		update_facing_direction(offset.normalized())

	# Handle movement and chasing
	if distance > stop_distance:

		velocity = offset.normalized() * speed

		if current_state != State.ATTACK:
			change_state(State.CHASE)

	else:

		velocity = Vector2.ZERO

		if current_state != State.ATTACK:
			change_state(State.IDLE)

	# Check whether the player is within attack range
	if attack_area.overlaps_body(player):
		if attack_cooldown.is_stopped() and current_state != State.ATTACK:
			start_attack()

	move_and_slide()


# ==================================================
# MOVEMENT & FACING DIRECTION
# ==================================================

func update_facing_direction(direction: Vector2) -> void:

	var new_direction: int

	if abs(direction.x) >= abs(direction.y):

		new_direction = 0 if direction.x >= 0.0 else 2

	else:

		new_direction = 1 if direction.y >= 0.0 else 3

	if new_direction != facing_direction:

		facing_direction = new_direction

		update_attack_direction()
		play_current_animation()


func update_attack_direction() -> void:

	attack_area.rotation = facing_direction * PI / 2.0


# ==================================================
# ANIMATION
# ==================================================

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

	# Check that the animation exists
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


func _on_animated_sprite_2d_animation_finished() -> void:

	match current_state:

		State.ATTACK:

			if player_chase and is_instance_valid(player):
				change_state(State.CHASE)
			else:
				change_state(State.IDLE)

		State.DEAD:
			queue_free()


# ==================================================
# COMBAT & ATTACKING
# ==================================================

func start_attack() -> void:

	change_state(State.ATTACK)

	# Damage the player if they are within attack range
	if is_instance_valid(player) and attack_area.overlaps_body(player):
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)

	attack_cooldown.start()


# ==================================================
# HEALTH & DAMAGE
# ==================================================

func take_damage(amount: int) -> void:

	if current_state == State.DEAD:
		return

	current_health -= amount
	print("Enemy health: ", current_health)

	if current_health <= 0:
		die()
	else:
		flash_sprite()


func die() -> void:

	if current_state == State.DEAD:
		return

	velocity = Vector2.ZERO
	attack_cooldown.stop()

	player_chase = false
	player = null

	change_state(State.DEAD)

	# Stop enemy movement while death animation plays
	set_physics_process(false)


# ==================================================
# DAMAGE FLASH
# ==================================================

func flash_sprite() -> void:

	# Stop an existing flash effect
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()

	animated_sprite.modulate = Color(1.0, 0.3, 0.3)

	flash_tween = create_tween()

	flash_tween.tween_property(
		animated_sprite,
		"modulate",
		Color.WHITE,
		0.12
	)


# ==================================================
# PLAYER DETECTION
# ==================================================

func _on_enter_body_entered(body: Node2D) -> void:

	if body.is_in_group("player") and body is CharacterBody2D:

		player = body
		player_chase = true

		change_state(State.CHASE)


func _on_exit_body_exited(body: Node2D) -> void:

	if body == player:

		player_chase = false
		player = null

		velocity = Vector2.ZERO

		change_state(State.IDLE)
