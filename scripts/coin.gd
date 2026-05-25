extends Area2D

@onready var pickup_behaviour: AnimationPlayer = $PickupBehaviour
@onready var score_counter: Label = $"../../StickyUI/ScoreCounterBound/ScoreCounter"

func _on_body_entered(body: Node2D) -> void:
	score_counter.increaseScore()
	pickup_behaviour.play("pickup")
