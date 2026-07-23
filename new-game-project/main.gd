extends Node

var rock_scene = preload("res://rock.tscn")
var crate_scene = preload("res://crate.tscn")
var bird_scene = preload("res://bird.tscn")
var obstacle_types := [rock_scene, crate_scene]
var obstacles : Array
var bird_heights := [200, 400]


const FOX_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed : float
const START_SPEED : float = 6.0
const MAX_SPEED : float = 12.0
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs
const CHERRY_SCENE = preload("res://cherry.tscn")

func _ready():
	screen_size = get_window().size 
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()
	
func new_game():
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	#delete all obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	#reset nodes
	$Player.position = FOX_START_POS
	$Player.velocity = Vector2i(0,0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	#reset HUD and game over screen
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

func _process(delta):
	if game_running:
		#speed up and adjust difficulty
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		#generate obstacles
		generate_obs()
		
		#move fox and camera
		$Player.position.x += speed
		$Camera2D.position.x += speed
		
		#update score
		score += speed
		show_score()
		
		#update ground position
		if $Camera2D.position.x - $Ground.position.x >  screen_size.x * 1.5:
			$Ground.position.x += screen_size.x 
			
		#remove obstacles that have gone off the screen
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
		for i in range(randi() %  max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 30          
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		#additionally random chance to spawn bird
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				#generate bird obstacles
				obs = bird_scene.instantiate()
				var obs_x : int  = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

	
func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if body.name == "Player":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGHSCORE: " + str(score / SCORE_MODIFIER)



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
	var cherry = CHERRY_SCENE.instantiate()
	
	var cherry_x = screen_size.x + score + randf_range(100, 300)
	var cherry_y = randf_range(350, 450) 
	cherry.position = Vector2(cherry_x, cherry_y)
	
	add_child(cherry)
	obstacles.append(cherry)
	
	cherry.get_node("Area2D").body_entered.connect(_on_cherry_collected.bind(cherry))
	
func _on_cherry_collected(body: Node2D, cherry_instance: Node2D):
	
	if body.is_in_group("player"):
		score += 500
		show_score()
		
		obstacles.erase(cherry_instance)
		cherry_instance.queue_free()
