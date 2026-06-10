extends Node

var rock_scene = preload("res://rock.tscn")
var crate_scene = preload("res://crate.tscn")
var bird_scene = preload("res://bird.tscn")
var obstacle_types := [rock_scene, crate_scene, bird_scene]
var obstacles : Array
var bird_heights := [200, 390]

const FOX_START_POS := Vector2i(100, 640)
const CAM_START_POS := Vector2i(576, 324)
var score : int
const SCORE_MODIFIER : int = 500
var speed : float
const START_SPEED : float = 9.0
const MAX_SPEED : float = 25.0 
const SPEED_MODIFIER : int = 8000
var screen_size : Vector2i
var game_running : bool
var last_obs

func _ready():
	screen_size = get_window().size
	new_game()

func new_game():
	score = 0
	game_running = false
	$Player.position = FOX_START_POS
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	# Initialize speed at the start of the game
	speed = START_SPEED 
	$HUD.get_node("StartLabel").show()

func _process(delta):
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		print(speed)
		# 1. Update the position directly using speed and delta
		# (Multiply by 60 if you want '9' to mean 9 pixels per frame at 60fps, 
		# or just increase START_SPEED to something like 200-500)
		var movement = speed * delta * 60 
		
		$Player.position.x += movement
		$Camera2D.position.x += movement
		
		score += speed
		show_score()
		
		# 2. Infinite ground scrolling logic
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)
