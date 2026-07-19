extends AnimatedSprite2D

func _process(delta: float) -> void:
	position.x -= get_parent().speed * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Foxi":
		get_parent().score += 500
		get_parent().show_score()
		
		#Delete the cherry
		queue_free()
