extends CharacterBody2D

# --- EXPORT VARIABLES ---
@export var speed: float = 150.0

# --- STATES ---
enum State { IDLE, WALK, ATTACK, HURT }
var current_state: State = State.IDLE

# --- NODES & VARIABLES ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Facing direction index: 0 = Right, 1 = Down, 2 = Left, 3 = Up
var last_dir_index: int = 1 


func _ready() -> void:
	# Automatically connect the animation_finished signal to reset states
	if not sprite.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE, State.WALK:
			handle_input()
		State.ATTACK, State.HURT:
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
		current_state = State.HURT
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
	# Single-direction animation (hurt)
	if current_state == State.HURT:
		if sprite.animation != "hurt":
			sprite.play("hurt")
		return

	# 4-directional animations (idle, walk, attack)
	var action_prefix: String = ""
	
	match current_state:
		State.IDLE:
			action_prefix = "idle"
		State.WALK:
			action_prefix = "walk"
		State.ATTACK:
			action_prefix = "attack"
			
	# Builds full animation name, e.g., "walk0", "attack1", "idle3"
	var anim_name = action_prefix + str(last_dir_index)
	
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _on_animated_sprite_2d_animation_finished() -> void:
	# Return control to the player after attack or hurt animations complete
	if current_state == State.ATTACK or current_state == State.HURT:
		current_state = State.IDLE
