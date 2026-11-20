
extends CharacterBody2D

# ==================================================
# VARIABLES
# ==================================================

# --- MOVEMENT ---
@export var speed: float = 150.0

# --- COMBAT ---
@export var attack_damage: int = 25
@export var max_health: int = 100
@export var damage_cooldown_time: float = 1.0

# --- STATES ---
enum State { IDLE, WALK, ATTACK, DEAD }

var current_state: State = State.IDLE
var current_health: int
var can_take_damage: bool = true

# Facing direction:
# 0 = Right, 1 = Down, 2 = Left, 3 = Up
var last_dir_index: int = 1

# Enemies already hit during the current attack
var hit_enemies: Array[Node] = []

# Flash effect
var flash_tween: Tween


# ==================================================
# NODE REFERENCES
# ==================================================

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_area: Area2D = $AttackPivot/Attack


# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:

	current_health = max_health

	# Connect animation finished signal
	if not sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


# ==================================================
# MAIN GAME LOOP
# ==================================================

func _physics_process(_delta: float) -> void:

	match current_state:

		State.IDLE, State.WALK:
			handle_input()

		State.ATTACK, State.DEAD:
			velocity = Vector2.ZERO

	# Check for enemies during an attack
	if current_state == State.ATTACK:
		check_attack_hits()

	move_and_slide()
	update_animation()


# ==================================================
# PLAYER MOVEMENT & INPUT
# ==================================================

func handle_input() -> void:

	# Attack input
	if Input.is_action_just_pressed("attack"):
		start_attack()
		return

	# Movement input
	var input_dir := Input.get_vector("left", "right", "up", "down")

	if input_dir != Vector2.ZERO:

		current_state = State.WALK
		velocity = input_dir * speed

		# Determine facing direction
		var angle := snappedf(input_dir.angle(), PI / 2.0)
		last_dir_index = wrapi(int(angle / (PI / 2.0)), 0, 4)

	else:

		current_state = State.IDLE
		velocity = Vector2.ZERO


# ==================================================
# ANIMATION
# ==================================================

func update_animation() -> void:

	if current_state == State.DEAD:
		if sprite.animation != "die":
			sprite.play("die")
		return

	var action_prefix: String

	match current_state:
		State.IDLE:
			action_prefix = "idle"
		State.WALK:
			action_prefix = "walk"
		State.ATTACK:
			action_prefix = "attack"
		_:
			return

	var anim_name: String = action_prefix + str(last_dir_index)

	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _on_animated_sprite_2d_animation_finished() -> void:

	# Return control after attack animation
	if current_state == State.ATTACK:
		current_state = State.IDLE


# ==================================================
# COMBAT & ATTACKING
# ==================================================

func start_attack() -> void:

	current_state = State.ATTACK
	velocity = Vector2.ZERO

	# Reset enemies hit during this swing
	hit_enemies.clear()

	# Rotate attack pivot to face player direction
	attack_pivot.rotation = last_dir_index * PI / 2.0


func check_attack_hits() -> void:

	var overlapping_areas: Array[Area2D] = attack_area.get_overlapping_areas()

	for area in overlapping_areas:

		var enemy: Node = area.get_parent()

		if enemy == null:
			continue

		if enemy.has_method("take_damage") and not hit_enemies.has(enemy):

			hit_enemies.append(enemy)
			enemy.take_damage(attack_damage)


# ==================================================
# HEALTH & DAMAGE
# ==================================================

func take_damage(amount: int) -> void:

	if current_state == State.DEAD or not can_take_damage:
		return

	current_health -= amount
	print("Player health: ", current_health)

	if current_health <= 0:
		die()
		return

	can_take_damage = false
	flash_sprite()

	await get_tree().create_timer(damage_cooldown_time).timeout

	if current_state != State.DEAD:
		can_take_damage = true


func flash_sprite() -> void:

	flash_tween = create_tween()
	flash_tween.set_loops()

	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(sprite, "modulate", Color.RED, 0.1)

	await get_tree().create_timer(damage_cooldown_time).timeout

	if is_instance_valid(flash_tween):
		flash_tween.kill()

	sprite.modulate = Color.WHITE


func die() -> void:

	if current_state == State.DEAD:
		return

	current_state = State.DEAD
	velocity = Vector2.ZERO

	print("Player has died!")

	await get_tree().create_timer(2.0).timeout

	get_tree().reload_current_scene()
