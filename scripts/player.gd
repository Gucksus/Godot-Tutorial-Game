extends CharacterBody2D

const MAX_SPEED = 150
const ACCELERATION = 500
const DECELERATION = 600
const JUMP_VELOCITY = -200
const TIME_TO_REACH_MAX_HEIGHT = .4
const JUMP_FORGIVENESS_WINDOW = .03

var jump_timer := 0.0
var fallen_timer := 0.0

@onready var acceleration_tween = get_tree().create_tween()
@onready var jump_accel_tween = get_tree().create_tween()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum States {
	ON_FLOOR,
	JUMP_FORGIVEN,
	JUMPING,
	FALLING
}
var current_state: States = States.FALLING: set = set_state


func jump_process(delta: float):
	print(States.find_key(current_state))
	match current_state:
		States.ON_FLOOR:
			if Input.is_action_just_pressed("jump"):
				jump_accel_tween = create_tween()
				jump_accel_tween.tween_method(set_velocityY, JUMP_VELOCITY, 0, TIME_TO_REACH_MAX_HEIGHT).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
				set_state(States.JUMPING)
				return
			if not is_on_floor():
				set_state(States.JUMP_FORGIVEN)
				return
			jump_timer = 0
			fallen_timer = 0

		States.JUMP_FORGIVEN:
			if fallen_timer > JUMP_FORGIVENESS_WINDOW:
				set_state(States.FALLING)
			if fallen_timer <= JUMP_FORGIVENESS_WINDOW and Input.is_action_just_pressed("jump"):
				jump_accel_tween = create_tween()
				jump_accel_tween.tween_method(set_velocityY, JUMP_VELOCITY, 0, TIME_TO_REACH_MAX_HEIGHT).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
				set_state(States.JUMPING)
				return
			fallen_timer += delta
			velocity += get_gravity() * delta

		States.FALLING:
			if is_on_floor():
				velocity.y = 0
				set_state(States.ON_FLOOR)
				return
			velocity += get_gravity() * delta

		States.JUMPING:
			if jump_timer >= TIME_TO_REACH_MAX_HEIGHT or Input.is_action_just_released("jump"):
				if jump_accel_tween:
					jump_accel_tween.kill()

				set_state(States.FALLING)
				return
			jump_timer += delta


func _physics_process(delta: float) -> void:
	jump_process(delta)

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
	current_state = new_state


func set_velocityX(value: float):
	velocity.x = value


func set_velocityY(value: float):
	velocity.y = value