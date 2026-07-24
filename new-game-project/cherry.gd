extends AnimatedSprite2D

func _process(delta: float) -> void:
	position.x -= get_parent().speed * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Checks if whatever touched the cherry belongs to the "player" group
	if body.is_in_group("player"):
		get_parent().score += 500
		get_parent().show_score()
		
		# Stop it from triggering twice
		$Area2D.set_deferred("monitoring", false)
		
		play("collected")
		await animation_finished
		queue_free()
