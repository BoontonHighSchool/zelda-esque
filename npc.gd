extends CharacterBody2D

# -------- VARIABLES -------- #

@export var move_speed: float = 35.0
@export var dialogue_text: String = "Hello, traveler!"

var wander_direction: Vector2 = Vector2.ZERO
var facing_direction: int = 1
var player: CharacterBody2D = null
var player_in_range: bool = false
var is_talking: bool = false

# -------- NODE REFERENCES -------- #

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wander_timer: Timer = $WanderTimer
@onready var interaction_area: Area2D = $InteractionArea

@onready var dialogue_panel: Panel = $DialogueLayer/DialoguePanel
@onready var dialogue_label: Label = $DialogueLayer/DialoguePanel/DialogueLabel


func _ready() -> void:

	dialogue_panel.visible = false

	wander_timer.timeout.connect(_on_wander_timer_timeout)

	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)

	choose_wander_direction()


# -------- MOVEMENT -------- #

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


func choose_wander_direction() -> void:

	var directions = [
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

	if not is_talking:
		choose_wander_direction()


# -------- DIRECTION -------- #

func update_facing_direction(direction: Vector2) -> void:

	if abs(direction.x) >= abs(direction.y):

		if direction.x > 0:
			facing_direction = 0
		else:
			facing_direction = 2

	else:

		if direction.y > 0:
			facing_direction = 1
		else:
			facing_direction = 3


# -------- ANIMATIONS -------- #

func update_animation() -> void:

	var animation_name: String

	if wander_direction == Vector2.ZERO or is_talking:
		animation_name = "idle" + str(facing_direction)
	else:
		animation_name = "walk" + str(facing_direction)

	if sprite.animation != animation_name:
		sprite.play(animation_name)


# -------- PLAYER INTERACTION -------- #

func _on_interaction_area_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):
		player = body
		player_in_range = true

		wander_direction = Vector2.ZERO
		wander_timer.stop()

		face_player()


func _on_interaction_area_body_exited(body: Node2D) -> void:

	if body == player:
		player_in_range = false
		player = null

		stop_talking()
		choose_wander_direction()


func _process(_delta: float) -> void:

	if player_in_range:

		if not is_talking:
			dialogue_panel.visible = true
			dialogue_label.text = "Press E to interact"

		if Input.is_action_just_pressed("interact"):

			if is_talking:
				stop_talking()
			else:
				start_talking()


func start_talking() -> void:

	is_talking = true
	wander_direction = Vector2.ZERO

	face_player()

	dialogue_label.text = dialogue_text
	dialogue_panel.visible = true


func stop_talking() -> void:

	is_talking = false

	if player_in_range:
		dialogue_panel.visible = true
		dialogue_label.text = "Press E to interact"
	else:
		dialogue_panel.visible = false

func face_player() -> void:

	if not is_instance_valid(player):
		return

	var direction = player.global_position - global_position

	update_facing_direction(direction)

	update_animation()
