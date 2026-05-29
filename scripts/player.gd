extends CharacterBody2D

const MAX_SPEED = 150
const ACCELERATION = 500
const DECELERATION = 600
const JUMP_VELOCITY = -170
const MAX_DONWARD_SPEED = 400
const TIME_TO_REACH_MAX_HEIGHT = .4
const JUMP_FORGIVENESS_WINDOW = .03
const JUMP_BUFFER_WINDOW = .06

var jump_timer := 0.0
var jump_buffer_timer := 0.0
var fallen_timer := 0.0
var double_jumped = false
var direction := 0.0
var near_ground_velocityY := 0.0

@onready var acceleration_tween = get_tree().create_tween()
@onready var jump_accel_tween = get_tree().create_tween()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_label: Label = $StateLabel

enum Physics_States {
	ON_FLOOR,
	JUMP_FORGIVEN,
	JUMPING,
	FALLING,
	JUMP_BUFFERING
}
var current_physics_state: Physics_States = Physics_States.FALLING: set = set_physics_state
var previous_physics_state: Physics_States = current_physics_state

enum Animation_States {
	IDLE,
	RUNNING,
	JUMPING,
	ASCENDING,
	FALLING,
	LANDING
}
var current_animation_state: Animation_States = Animation_States.IDLE: set = set_animation_state


func update_state_label():
	# state_label.text = Physics_States.find_key(current_physics_state)
	state_label.text = Animation_States.find_key(current_animation_state)

func initialize_jump():
	animated_sprite.play("jumping")
	set_animation_state(Animation_States.JUMPING)
	jump_timer = 0
	jump_buffer_timer = 0
	jump_accel_tween = create_tween()
	jump_accel_tween.tween_method(set_velocityY, JUMP_VELOCITY, 0, TIME_TO_REACH_MAX_HEIGHT).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	set_physics_state(Physics_States.JUMPING)
	position.y -= 1


func jump_process(delta: float):
	if is_on_floor():
		set_physics_state(Physics_States.ON_FLOOR)
	match current_physics_state:
		Physics_States.ON_FLOOR:
			double_jumped = false
			jump_timer = 0
			fallen_timer = 0
			if Input.is_action_just_pressed("jump") or jump_buffer_timer > 0:
				initialize_jump()
				return
			if not is_on_floor():
				set_physics_state(Physics_States.JUMP_FORGIVEN)
				return
		Physics_States.JUMP_FORGIVEN:
			if fallen_timer > JUMP_FORGIVENESS_WINDOW:
				set_physics_state(Physics_States.FALLING)
				return
			elif Input.is_action_just_pressed("jump"):
				initialize_jump()
				return
			fallen_timer += delta
			velocity += 2 * get_gravity() * delta

		Physics_States.FALLING:
			if Input.is_action_just_pressed("jump"):
				if not double_jumped:
					initialize_jump()
					double_jumped = true
					return
				else:
					set_physics_state(Physics_States.JUMP_BUFFERING)
					jump_buffer_timer = JUMP_BUFFER_WINDOW
					return
			if velocity.y < MAX_DONWARD_SPEED:
				velocity += get_gravity() * delta

		Physics_States.JUMP_BUFFERING:
			if jump_buffer_timer <= 0:
				set_physics_state(Physics_States.FALLING)
				return
			jump_buffer_timer -= delta
			velocity += get_gravity() * delta

		Physics_States.JUMPING:
			if jump_timer >= TIME_TO_REACH_MAX_HEIGHT or not Input.is_action_pressed("jump") or is_on_ceiling():
				if jump_accel_tween:
					jump_accel_tween.kill()
				set_physics_state(Physics_States.FALLING)
				return
			if Input.is_action_just_pressed("jump"):
				initialize_jump()
				double_jumped = true
				return
			jump_timer += delta

	if near_ground_velocityY != velocity.y and velocity.y:
		near_ground_velocityY = velocity.y


func animation_process():
	print(Animation_States.find_key(current_animation_state))
	match current_animation_state:
		Animation_States.IDLE:
			if current_physics_state == Physics_States.JUMPING:
				set_animation_state(Animation_States.JUMPING)
				return
			if direction:
				animated_sprite.play("running")
				set_animation_state(Animation_States.RUNNING)
				return
		
		Animation_States.JUMPING:
			if velocity.y >= -140 and velocity.y != 0:
				animated_sprite.play("ascending")
				set_animation_state(Animation_States.ASCENDING)
				return
				
		Animation_States.ASCENDING:
			if current_physics_state == Physics_States.FALLING:
				animated_sprite.play("slow_falling")
				set_animation_state(Animation_States.FALLING)
				return

		Animation_States.FALLING:
			if current_physics_state == Physics_States.ON_FLOOR and near_ground_velocityY > 0:
				animated_sprite.play("landing")
				set_animation_state(Animation_States.LANDING)
				return
			if velocity.y >= 300:
				animated_sprite.play("fast_falling")
				return
			elif velocity.y >= 200:
				animated_sprite.play("falling")
				return
			else:
				animated_sprite.play("slow_falling")

		Animation_States.LANDING:
			if direction:
				animated_sprite.play("running")
				set_animation_state(Animation_States.RUNNING)
				return
			if animated_sprite.animation_finished:
				animated_sprite.play("idle")
				set_animation_state(Animation_States.IDLE)
				return

		Animation_States.RUNNING:
			if current_physics_state != Physics_States.ON_FLOOR:
				set_animation_state(Animation_States.JUMPING)
				return
			if not direction:
				animated_sprite.play("idle")
				set_animation_state(Animation_States.IDLE)
				return


# Handle sprite direction and velocity.
func horizontal_velocity_process():
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

	
func _physics_process(delta: float) -> void:
	direction = Input.get_axis("left", "right")
	jump_process(delta)
	animation_process()
	horizontal_velocity_process()
	update_state_label()
		
	move_and_slide()


func set_physics_state(new_state: Physics_States):
	previous_physics_state = current_physics_state
	current_physics_state = new_state

func set_animation_state(new_state: Animation_States):
	current_animation_state = new_state


func set_velocityX(value: float):
	velocity.x = value


func set_velocityY(value: float):
	velocity.y = value