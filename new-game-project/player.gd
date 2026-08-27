extends CharacterBody2D

@onready var sfx_jump: AudioStreamPlayer2D = $sfx_jump

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1300

# New variable so the Main script knows when to slow down the world
var is_ducking : bool = false

# --- NEW: Air-Invincibility Ability Variables ---
var can_use_air_ability: bool = true
var has_used_air_ability: bool = false
var air_ability_cooldown: float = 0.0
const AIR_ABILITY_COOLDOWN_TIME: float = 5.0

signal triggered_air_invincibility

func _physics_process(delta):
	# Tick down the cooldown timer
	if air_ability_cooldown > 0:
		air_ability_cooldown -= delta

	# If in the air and holding the down key, fall faster.
	if not is_on_floor() and Input.is_action_pressed("ui_down") or Input.is_action_pressed("Crouch"):
		velocity.y += (GRAVITY * 3.5) * delta
	else:
		velocity.y += GRAVITY * delta
		
	if is_on_floor():
		# Reset ability states when landing
		has_used_air_ability = false
		can_use_air_ability = true

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
				sfx_jump.play()
			elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("Crouch"):
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
		
		# --- NEW: Mid-air Invincibility Check (No Extra Jump) ---
		if (Input.is_action_just_pressed("ui_accept") or Input.is_action_pressed("Jump")):
			if can_use_air_ability and not has_used_air_ability and air_ability_cooldown <= 0:
				has_used_air_ability = true
				air_ability_cooldown = AIR_ABILITY_COOLDOWN_TIME
				
				# Trigger invincibility on the main script without changing velocity
				emit_signal("triggered_air_invincibility")
		
	move_and_slide()
