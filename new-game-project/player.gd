extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1300

# New variable so the Main script knows when to slow down the world
var is_ducking : bool = false

func _physics_process(delta):
	# If in the air and holding the down key, fall faster.
	if not is_on_floor() and Input.is_action_pressed("ui_down"):
		velocity.y += (GRAVITY * 3.5) * delta
	else:
		velocity.y += GRAVITY * delta
		
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("Idle")
			is_ducking = false # Reset if game isn't running
		else:
			$RunCol.disabled = false
			$JumpCol.disabled = true
			
			if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("Jump"):
				velocity.y = JUMP_SPEED
				$JumpCol.disabled = false
				$RunCol.disabled = true
				$DuckCol.disabled = true
				is_ducking = false # Can't duck while jumping
				
			elif Input.is_action_pressed("ui_down"):
				# --- FEATURE 2: GROUND DUCKING ---
				$AnimatedSprite2D.play("crouch")
				$RunCol.disabled = true
				$JumpCol.disabled = true
				$DuckCol.disabled = false
				is_ducking = true # Signal the main script to slow down
				
			else:
				$AnimatedSprite2D.play("run")
				is_ducking = false # Reset when not holding down
	else:
		$AnimatedSprite2D.play("jump")
		
	move_and_slide()
