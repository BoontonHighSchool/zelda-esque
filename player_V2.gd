extends CharacterBody2D
#Player V2
# --- EXPORT VARIABLES ---
@export var speed: float = 150.0

# --- STATES ---
enum State { IDLE, WALK, ATTACK, DEAD }
@export var max_health: int = 100
var current_health: int
var current_state: State = State.IDLE

# --- NODES & VARIABLES ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var damage_cooldown_time: float = 1.0

var can_take_damage: bool = true
var flash_tween: Tween

# Facing direction index: 0 = Right, 1 = Down, 2 = Left, 3 = Up
var last_dir_index: int = 1 


func _ready() -> void:
	current_health = max_health
	# Automatically connect the animation_finished signal to reset states
	if not sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE, State.WALK:
			handle_input()
		State.ATTACK, State.DEAD:
			# Freeze movement while attacking or taking damage
			velocity = Vector2.ZERO
			
	move_and_slide()
	update_animation()


func handle_input() -> void:
	# Trigger attack state using your custom "attack" action
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
		return
		
	# Trigger hurt state for testing (Press 'H')
	if Input.is_key_pressed(KEY_H):
		take_damage(10)
		return

	# Standard 4-direction movement input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		current_state = State.WALK
		velocity = input_dir * speed
		
		# Map movement vector angle to direction index (0: Right, 1: Down, 2: Left, 3: Up)
		var angle = snappedf(input_dir.angle(), PI / 2) / (PI / 2)
		last_dir_index = wrapi(int(angle), 0, 4)
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO


func update_animation() -> void:

	if current_state == State.DEAD:
		if sprite.animation != "die":
			sprite.play("die")
		return

	var action_prefix: String = ""

	match current_state:
		State.IDLE:
			action_prefix = "idle"
		State.WALK:
			action_prefix = "walk"
		State.ATTACK:
			action_prefix = "attack"

	var anim_name = action_prefix + str(last_dir_index)

	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	# Return control to the player after attack animations complete
	if current_state == State.ATTACK :
		current_state = State.IDLE

func take_damage(amount: int) -> void:
	if current_state == State.DEAD or not can_take_damage:
		return

	current_health -= amount
	print("Player health: ", current_health)

	if current_health <= 0:
		die()
	else:
		can_take_damage = false
		flash_sprite()
		await get_tree().create_timer(damage_cooldown_time).timeout
		can_take_damage = true


func die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	print("Player has died!")
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

func flash_sprite() -> void:
	flash_tween = create_tween()
	flash_tween.set_loops()

	flash_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.1
	)

	flash_tween.tween_property(
		sprite,
		"modulate",
		Color(1.0, 0.0, 0.0, 1.0),
		0.1
	)

	await get_tree().create_timer(damage_cooldown_time).timeout

	if is_instance_valid(flash_tween):
		flash_tween.kill()

	sprite.modulate = Color.WHITE
