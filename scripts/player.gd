extends CharacterBody2D

const MAX_SPEED = 150
const JUMP_VELOCITY = -300
const ACCELERATION = 500
const DECELERATION = 600

@onready var accelerationTween = get_tree().create_tween()
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func setVelocityX(value):
	velocity.x = value

func _physics_process(delta: float) -> void:
		# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")
	
	# Hanlde animation.
	if not is_on_floor():
		# Add the gravity.
		velocity += get_gravity() * delta
		animated_sprite.play("jump")
	else:
		# Play idle animation if standing still, else play "run" animation.
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")

	# Handle sprite direction and velocity.
	if direction:
		if accelerationTween:
			accelerationTween.kill()

		accelerationTween = create_tween()
		accelerationTween.tween_method(setVelocityX, velocity.x, direction * MAX_SPEED, 1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

		if direction > 0:
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
	else:
		if accelerationTween:
			accelerationTween.kill()

		accelerationTween = create_tween()
		accelerationTween.tween_method(setVelocityX, velocity.x, 0, 1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		
	move_and_slide()
