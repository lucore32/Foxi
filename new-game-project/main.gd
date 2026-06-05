extends Node

const FOX_START_POS := Vector2i(100, 560)
const CAM_START_POS := Vector2i(576, 324)
var score : int
var speed : float
const START_SPEED : float = 9.0
const MAX_SPEED : float = 25.0 
var screen_size : Vector2i

func _ready():
	screen_size = get_window().size
	new_game()

func new_game():
	score = 0
	$Player.position = FOX_START_POS
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	# Initialize speed at the start of the game
	speed = START_SPEED 

func _process(delta):
	# 1. Update the position directly using speed and delta
	# (Multiply by 60 if you want '9' to mean 9 pixels per frame at 60fps, 
	# or just increase START_SPEED to something like 200-500)
	var movement = speed * delta * 60 
	
	$Player.position.x += movement
	$Camera2D.position.x += movement
	
	score += speed
	print(score)
	
	# 2. Infinite ground scrolling logic
	if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
		$Ground.position.x += screen_size.x
