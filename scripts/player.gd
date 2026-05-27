extends CharacterBody2D

const MAX_SPEED = 150
const ACCELERATION = 500
const DECELERATION = 600
const JUMP_VELOCITY = -170
const TIME_TO_REACH_MAX_HEIGHT = .4
const JUMP_FORGIVENESS_WINDOW = .03
const JUMP_BUFFER_WINDOW = .06

var jump_timer := 0.0
var jump_buffer_timer := 0.0
var fallen_timer := 0.0
var double_jumped = false

@onready var acceleration_tween = get_tree().create_tween()
@onready var jump_accel_tween = get_tree().create_tween()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_label: Label = $StateLabel

enum States {
	ON_FLOOR,
	JUMP_FORGIVEN,
	JUMPING,
	FALLING,
	JUMP_BUFFERING
}
var current_state: States = States.FALLING: set = set_state
var previous_state: States = current_state

func update_state_label():
	if previous_state != current_state:
		state_label.text = States.find_key(current_state)
		# print(States.find_key(previous_state) + " -> " + States.find_key(current_state))

func initialize_jump():
	jump_timer = 0
	jump_buffer_timer = 0
	jump_accel_tween = create_tween()
	jump_accel_tween.tween_method(set_velocityY, JUMP_VELOCITY, 0, TIME_TO_REACH_MAX_HEIGHT).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	set_state(States.JUMPING)
	position.y -= 1


func state_process(delta: float):
	print(States.find_key(current_state))
	if is_on_floor():
		set_state(States.ON_FLOOR)
	match current_state:
		States.ON_FLOOR:
			double_jumped = false
			jump_timer = 0
			fallen_timer = 0
			if Input.is_action_just_pressed("jump") or jump_buffer_timer > 0:
				initialize_jump()
				return
			if not is_on_floor():
				set_state(States.JUMP_FORGIVEN)
				return
		States.JUMP_FORGIVEN:
			if fallen_timer > JUMP_FORGIVENESS_WINDOW:
				set_state(States.FALLING)
				return
			elif Input.is_action_just_pressed("jump"):
				initialize_jump()
				return
			fallen_timer += delta
			velocity += get_gravity() * delta

		States.FALLING:
			if Input.is_action_just_pressed("jump"):
				if not double_jumped:
					initialize_jump()
					double_jumped = true
					return
				else:
					set_state(States.JUMP_BUFFERING)
					jump_buffer_timer = JUMP_BUFFER_WINDOW
					return
			velocity += get_gravity() * delta

		States.JUMP_BUFFERING:
			if jump_buffer_timer <= 0:
				set_state(States.FALLING)
				return
			jump_buffer_timer -= delta
			velocity += get_gravity() * delta

		States.JUMPING:
			if jump_timer >= TIME_TO_REACH_MAX_HEIGHT or not Input.is_action_pressed("jump") or is_on_ceiling():
				if jump_accel_tween:
					jump_accel_tween.kill()
				set_state(States.FALLING)
				return
			if Input.is_action_just_pressed("jump"):
				initialize_jump()
				double_jumped = true
				return
			jump_timer += delta

	update_state_label()


func _physics_process(delta: float) -> void:
	state_process(delta)

	var direction := Input.get_axis("left", "right")
	
	# Hanlde animation.
	if not is_on_floor():
		animated_sprite.play("jump")
	else:
		# Play idle animation if standing still, else play "run" animation.
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")

	# Handle sprite direction and velocity.
	if direction:
		if acceleration_tween:
			acceleration_tween.kill()

		acceleration_tween = create_tween()
		acceleration_tween.tween_method(set_velocityX, velocity.x, direction * MAX_SPEED, 1.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

		if direction > 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
	else:
		if acceleration_tween:
			acceleration_tween.kill()

		acceleration_tween = create_tween()
		acceleration_tween.tween_method(set_velocityX, velocity.x, 0, 1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		
	move_and_slide()


func set_state(new_state: States):
	previous_state = current_state
	current_state = new_state


func set_velocityX(value: float):
	velocity.x = value


func set_velocityY(value: float):
	velocity.y = value