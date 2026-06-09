extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1100

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			pass
		else:
			$RunCol.disabled = false
			if Input.is_action_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
			elif Input.is_action_pressed("ui_down"):
				$AnimatedSprite2D.play("crouch")
				$RunCol.disabled = true
			else:
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump")
	move_and_slide()
