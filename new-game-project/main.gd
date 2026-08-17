extends Node

var rock_scene = preload("res://rock.tscn")
var crate_scene = preload("res://crate.tscn")
var bird_scene = preload("res://bird.tscn")
var obstacle_types := [rock_scene, crate_scene]
var obstacles : Array
var bird_heights := [250, 400]

# --- NEW: Preloaded Explosion Scene ---
const EXPLOSION_SCENE = preload("res://explosion.tscn")

var lives: int = 3
var max_lives: int = 3
var is_invincible: bool = false
var invincibility_time_left: float = 0.0

# --- Cooldown variables for the air-jump ability ---
var air_ability_cooldown: float = 0.0
const AIR_ABILITY_COOLDOWN_MAX: float = 5.0 # Change this duration (in seconds) as needed

const FOX_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed : float
const START_SPEED : float = 10.0
const MAX_SPEED : float = 15.0
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs
const CHERRY_SCENE = preload("res://cherry.tscn")
const GOLDEN_CHERRY_SCENE = preload("res://golden_cherry.tscn")

func _ready():
	screen_size = get_window().size 
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	
	# Connect player's air invincibility signal
	$Player.triggered_air_invincibility.connect(_on_player_air_invincibility)
	
	new_game()

func new_game():
	score = 0
	show_score()
	
	# Reset lives & invincibility
	lives = max_lives
	is_invincible = false
	invincibility_time_left = 0.0
	air_ability_cooldown = 0.0
	$Player.modulate = Color.WHITE
	update_lives_ui()
	
	if $HUD.has_node("InvincibilityTimerLabel"):
		$HUD.get_node("InvincibilityTimerLabel").text = ""
		
	if $HUD.has_node("DHLabel"):
		$HUD.get_node("DHLabel").text = "Ability Ready!"
	
	# Clear obstacles
	for obs in obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	obstacles.clear()
	
	# Clear stray animated sprites (cherries/explosions)
	for child in get_children():
		if child is AnimatedSprite2D and child.has_signal("animation_finished"):
			child.queue_free()
			
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	# Reset nodes
	$Player.position = FOX_START_POS
	$Player.velocity = Vector2i(0,0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	# Reset HUD and game over screen
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

func _process(delta):
	if game_running:
		# Speed up and adjust difficulty
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		# Count down general invincibility time (damage flash / golden cherry)
		if invincibility_time_left > 0:
			invincibility_time_left -= delta
			if invincibility_time_left <= 0:
				invincibility_time_left = 0
				if $HUD.has_node("InvincibilityTimerLabel"):
					$HUD.get_node("InvincibilityTimerLabel").text = ""
			else:
				if $HUD.has_node("InvincibilityTimerLabel"):
					$HUD.get_node("InvincibilityTimerLabel").text = "Invincible: " + str(snappedf(invincibility_time_left, 0.1)) + "s"
		
		# Count down air ability cooldown and update DHLabel
		if air_ability_cooldown > 0:
			air_ability_cooldown -= delta
			if air_ability_cooldown <= 0:
				air_ability_cooldown = 0.0
				if $HUD.has_node("DHLabel"):
					$HUD.get_node("DHLabel").text = "Ability Ready!"
			else:
				if $HUD.has_node("DHLabel"):
					$HUD.get_node("DHLabel").text = "Cooldown: " + str(snappedf(air_ability_cooldown, 0.1)) + "s"
		else:
			if $HUD.has_node("DHLabel"):
				$HUD.get_node("DHLabel").text = "Ability Ready!"
		
		# Generate obstacles
		generate_obs()
		
		# Move player and camera forward at full frame rate
		$Player.position.x += speed
		$Camera2D.position.x += speed
		
		# Update score
		score += speed
		show_score()
		
		# Update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x 
			
		# Remove obstacles that have gone off the screen
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
				
		if randf() < 0.005:
			generate_cherry()
	else:
		if Input.is_action_pressed("ui_accept") or Input.is_action_pressed("Jump"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(100, 300):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 30         
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
			
		# Additionally random chance to spawn bird
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs.bind(obs))
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	if is_instance_valid(obs):
		obs.queue_free()
		obstacles.erase(obs)

func hit_obs(body: Node2D, obstacle_instance: Node2D):
	if body.name == "Player":
		# Disable collision on the hit obstacle immediately so it can't hit twice
		if obstacle_instance.has_node("CollisionShape2D"):
			obstacle_instance.get_node("CollisionShape2D").set_deferred("disabled", true)
		elif obstacle_instance.has_node("Area2D/CollisionShape2D"):
			obstacle_instance.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)
			
		# --- NEW: Spawn Explosion Animation ---
		spawn_explosion(obstacle_instance.global_position)
			
		# Destroy obstacle and deal damage
		remove_obs(obstacle_instance)
		take_damage()

# --- NEW: Explosion Spawn Helper Function ---
func spawn_explosion(pos: Vector2):
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.position = pos
	add_child(explosion)

func take_damage():
	if is_invincible:
		return
		
	lives -= 1
	update_lives_ui()
	
	if lives <= 0:
		game_over()
	else:
		start_invincibility()

func start_invincibility():
	is_invincible = true
	invincibility_time_left = 0.8 # 4 loops * 0.2 seconds = 0.8s
	
	# Flash red 4 times over 0.8 seconds
	var tween = create_tween().set_loops(4)
	tween.tween_property($Player, "modulate", Color(1, 0.2, 0.2, 0.8), 0.1)
	tween.tween_property($Player, "modulate", Color.WHITE, 0.1)
	
	await tween.finished
	$Player.modulate = Color.WHITE
	is_invincible = false

func start_golden_invincibility():
	is_invincible = true
	invincibility_time_left = 3.0 # 15 loops * 0.2 seconds = 3 seconds total
	
	# Flash the player with a golden/yellow tint
	var tween = create_tween().set_loops(15)
	tween.tween_property($Player, "modulate", Color(1, 0.8, 0, 0.8), 0.1)
	tween.tween_property($Player, "modulate", Color.WHITE, 0.1)
	
	await tween.finished
	
	# Ensure the player's color resets back to normal
	$Player.modulate = Color.WHITE
	is_invincible = false

# Function triggered by the player's mid-air double jump
func _on_player_air_invincibility():
	air_ability_cooldown = AIR_ABILITY_COOLDOWN_MAX # Start cooldown timer
	is_invincible = true
	invincibility_time_left = 0.5 # 0.5 seconds of invincibility
	
	# Flash cyan/blue for air-jump invincibility
	var tween = create_tween().set_loops(2)
	tween.tween_property($Player, "modulate", Color(0.5, 0.8, 1, 0.8), 0.125)
	tween.tween_property($Player, "modulate", Color.WHITE, 0.125)
	
	await tween.finished
	if invincibility_time_left <= 0:
		$Player.modulate = Color.WHITE
		is_invincible = false

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGHSCORE: " + str(score / SCORE_MODIFIER)

func update_lives_ui():
	if $HUD.has_node("LivesLabel"):
		$HUD.get_node("LivesLabel").text = "Lives: " + str(lives)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()

func generate_cherry():
	# Golden cherries only spawn if difficulty has reached MAX_DIFFICULTY
	var is_golden = false
	if difficulty >= MAX_DIFFICULTY:
		is_golden = randf() < 0.3 # 30% chance for a golden cherry
		
	var chosen_scene = GOLDEN_CHERRY_SCENE if is_golden else CHERRY_SCENE
	
	var cherry = chosen_scene.instantiate()
	
	var cherry_x = screen_size.x + score + randf_range(100, 300)
	var cherry_y = randf_range(350, 450) 
	cherry.position = Vector2(cherry_x, cherry_y)
	
	add_child(cherry)
	obstacles.append(cherry)
	
	cherry.get_node("Area2D").body_entered.connect(_on_cherry_collected.bind(cherry, is_golden))

func _on_cherry_collected(body: Node2D, cherry_instance: AnimatedSprite2D, is_golden: bool):
	if not is_instance_valid(cherry_instance):
		return

	if body.name == "Foxi" or body.is_in_group("player"):
		score += 2000 if is_golden else 500
		
		if is_golden:
			lives = min(lives + 1, max_lives)
			update_lives_ui()
			start_golden_invincibility() # Trigger the 3-second immunity
			
		show_score()
		obstacles.erase(cherry_instance)
		
		if cherry_instance.has_node("Area2D/CollisionShape2D"):
			cherry_instance.get_node("Area2D/CollisionShape2D").set_deferred("disabled", true)
			
		cherry_instance.play("collected")
		await cherry_instance.animation_finished
		if is_instance_valid(cherry_instance):
			cherry_instance.queue_free()
