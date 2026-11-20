
extends CharacterBody2D


# ==================================================
# VARIABLES
# ==================================================

# --- MOVEMENT ---
@export var move_speed: float = 35.0

var wander_direction: Vector2 = Vector2.ZERO

# Facing direction:
# 0 = Right, 1 = Down, 2 = Left, 3 = Up
var facing_direction: int = 1


# --- PLAYER INTERACTION ---
var player: CharacterBody2D = null
var player_in_range: bool = false
var is_talking: bool = false


# --- DIALOGUE ---
@export var dialogue_text: Array[String] = [
	"Hello, traveler!",
	"Welcome to our village.",
	"Be careful in the forest!"
]

var dialogue_index: int = 0


# ==================================================
# NODE REFERENCES
# ==================================================

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wander_timer: Timer = $WanderTimer
@onready var interaction_area: Area2D = $InteractionArea

@onready var dialogue_panel: Panel = $DialogueLayer/DialoguePanel
@onready var dialogue_label: Label = $DialogueLayer/DialoguePanel/DialogueLabel


# ==================================================
# INITIALIZATION
# ==================================================

func _ready() -> void:

	dialogue_panel.hide()

	wander_timer.timeout.connect(_on_wander_timer_timeout)

	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

	choose_wander_direction()


# ==================================================
# MAIN GAME LOOP
# ==================================================

func _physics_process(_delta: float) -> void:

	if is_talking:
		velocity = Vector2.ZERO
	else:
		velocity = wander_direction * move_speed

	move_and_slide()

	if is_on_wall() and not is_talking:
		wander_direction = Vector2.ZERO
		wander_timer.start(0.5)

	update_animation()


func _process(_delta: float) -> void:

	if not player_in_range:
		return

	# Start or advance dialogue
	if Input.is_action_just_pressed("interact"):

		if is_talking:
			advance_dialogue()
		else:
			start_talking()

	# Show interaction prompt when not talking
	if not is_talking:
		dialogue_panel.show()
		dialogue_label.text = "Press E to interact"


# ==================================================
# MOVEMENT & WANDERING
# ==================================================

func choose_wander_direction() -> void:

	var directions: Array[Vector2] = [
		Vector2.ZERO,
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN
	]

	wander_direction = directions.pick_random()

	if wander_direction != Vector2.ZERO:
		update_facing_direction(wander_direction)

	wander_timer.start(randf_range(1.0, 3.0))


func _on_wander_timer_timeout() -> void:

	if not is_talking and not player_in_range:
		choose_wander_direction()


# ==================================================
# DIRECTION & ANIMATIONS
# ==================================================

func update_facing_direction(direction: Vector2) -> void:

	if abs(direction.x) >= abs(direction.y):

		facing_direction = 0 if direction.x > 0 else 2

	else:

		facing_direction = 1 if direction.y > 0 else 3


func face_player() -> void:

	if not is_instance_valid(player):
		return

	var direction: Vector2 = player.global_position - global_position

	if direction != Vector2.ZERO:
		update_facing_direction(direction)

	update_animation()


func update_animation() -> void:

	var animation_name: String

	if wander_direction == Vector2.ZERO or is_talking:
		animation_name = "idle" + str(facing_direction)
	else:
		animation_name = "walk" + str(facing_direction)

	if sprite.animation != animation_name:
		sprite.play(animation_name)


# ==================================================
# DIALOGUE
# ==================================================

func start_talking() -> void:

	if dialogue_text.is_empty():
		return

	is_talking = true
	wander_direction = Vector2.ZERO
	wander_timer.stop()

	face_player()

	dialogue_index = 0
	show_dialogue()


func show_dialogue() -> void:

	dialogue_label.text = dialogue_text[dialogue_index]
	dialogue_panel.show()


func advance_dialogue() -> void:

	dialogue_index += 1

	if dialogue_index >= dialogue_text.size():
		stop_talking()
	else:
		show_dialogue()


func stop_talking() -> void:

	is_talking = false
	dialogue_index = 0

	if player_in_range:
		dialogue_panel.show()
		dialogue_label.text = "Press E to interact"
	else:
		dialogue_panel.hide()

	if not player_in_range:
		choose_wander_direction()


# ==================================================
# PLAYER DETECTION
# ==================================================

func _on_interaction_area_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):

		player = body
		player_in_range = true

		wander_direction = Vector2.ZERO
		wander_timer.stop()

		face_player()

		dialogue_panel.show()
		dialogue_label.text = "Press E to interact"


func _on_interaction_area_body_exited(body: Node2D) -> void:

	if body == player:

		player_in_range = false
		player = null

		stop_talking()
		dialogue_panel.hide()

		choose_wander_direction()
