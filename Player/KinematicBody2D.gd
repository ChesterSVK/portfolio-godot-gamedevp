extends KinematicBody2D

const UP = Vector2(0, -1)
const ORIGINAL_GRAVITY = 50
var GRAVITY = 50
var PARACHUTING_CONSTANT = 5
const SPEED = 300
const JUMP_HEIGHT = -550
const SLIDE_DISTANCE = 25


const IDLE_ANIM = "Idle"
const RUN_ANIM = "Run"
const CROUCH_ANIM = "Crouch"
const PARACHUTE_ANIM = "Parachute"
const JUMP_ANIM = "Jump"
const WALK_ANIM = "Walk"
const SLIDE_ANIM = "Slide"
const FALL_ANIM = "Fall"

var disabled_left = false
var disabled_right = false
var disabled_up = false
var disabled_down = false

var block_movement = false
var motion = Vector2()
var is_allowed_to_jump = false
var is_allowed_to_parachute = true
var slide_covered = 0

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	motion.x = 0		
	play_animation(IDLE_ANIM)
	$CollisionShape2DCrouch.disabled = true
	$CollisionShape2D.disabled = false
	pass


func _input(event):
	if(event.is_action_pressed("ui_down")):
		if !is_player_running():
			block_movement = true
	elif(event.is_action_released("ui_down")):
		block_movement = false
		disabled_down = false
		slide_covered = 0
		$CollisionShape2DCrouch.disabled = true
		$CollisionShape2D.disabled = false
	if(event.is_action_pressed("ui_left")):
		disabled_right = true
	elif(event.is_action_released("ui_left")):
		disabled_right = false
	if(event.is_action_pressed("ui_right")):
		disabled_left = true
	elif(event.is_action_released("ui_right")):
		disabled_left = false


func _physics_process(delta):
	controls_loop()
	gravity_loop()
	
func gravity_loop():
	motion.y +=GRAVITY
	# if position.y > 400:
		# get_tree().reload_current_scene()

func controls_loop():
	var final_anim 			= IDLE_ANIM
	var INPUT_LEFT 			= Input.is_action_pressed("ui_left")
	var INPUT_RIGHT 		= Input.is_action_pressed("ui_right")
	var INPUT_UP 			= Input.is_action_just_pressed("ui_up")
	var INPUT_DOWN 			= Input.is_action_pressed("ui_down")
	var INPUT_DOWN_JUST 	= Input.is_action_just_pressed("ui_down")
	
	if right_direction(INPUT_RIGHT):
		$Sprite.flip_h = false
		if is_player_walking():
			motion.x = SPEED / 2
			final_anim = WALK_ANIM
		else:
			motion.x = SPEED
			final_anim = RUN_ANIM
		motion = move_and_slide(motion, UP)
	elif left_direction(INPUT_LEFT):
		$Sprite.flip_h = true
		if is_player_walking():
			motion.x = -SPEED / 2
			final_anim = WALK_ANIM
		else:
			motion.x = -SPEED
			final_anim = RUN_ANIM
		motion = move_and_slide(motion, UP)
	else:
		motion.x = 0		
		final_anim = IDLE_ANIM
		motion = move_and_slide(motion, UP)
	
	if up_direction(INPUT_UP):
		jump(INPUT_UP)
		final_anim = JUMP_ANIM
		
	if down_direction(INPUT_DOWN):
		if is_player_running():
			if slide($Sprite.flip_h):
				final_anim = SLIDE_ANIM
		else:
			crouch(INPUT_DOWN)
			final_anim = CROUCH_ANIM
		
	
	if is_player_falling():
		if can_player_parachute():
			if Input.is_key_pressed(KEY_SPACE):
				GRAVITY = PARACHUTING_CONSTANT
				is_allowed_to_parachute = false
				final_anim = PARACHUTE_ANIM
		if !is_player_parachuting(): 
			GRAVITY = ORIGINAL_GRAVITY
			final_anim = FALL_ANIM
		else: 
			final_anim = PARACHUTE_ANIM
			
	if is_on_floor():
		GRAVITY = ORIGINAL_GRAVITY
		is_allowed_to_parachute = true
		
		
		
	play_animation(final_anim)
	
func is_player_parachuting():
	return is_player_falling() and GRAVITY != ORIGINAL_GRAVITY and !is_allowed_to_parachute
	
func can_player_parachute():
	return is_player_falling() and GRAVITY == ORIGINAL_GRAVITY and is_allowed_to_parachute
	
		
func slide(going_right):
	if slide_covered < SLIDE_DISTANCE:
		$CollisionShape2DCrouch.disabled = false
		$CollisionShape2D.disabled = true
		if going_right:
			motion.x = -SLIDE_DISTANCE
		else:
			motion.x = SLIDE_DISTANCE
		motion = move_and_slide(motion, UP)
		slide_covered +=1
		var player = AudioStreamPlayer.new()
		self.add_child(player)
		player.stream = load("res://Player/Sounds/slide.wav")
		player.play()
		return true
	else:
		$CollisionShape2DCrouch.disabled = true
		$CollisionShape2D.disabled = false
		disabled_down = true
		slide_covered = 0
		return false
	
func right_direction(INPUT_RIGHT):
	return INPUT_RIGHT and !disabled_right and !block_movement

func left_direction(INPUT_LEFT):
	return INPUT_LEFT and !disabled_left and !block_movement
	
func up_direction(INPUT_UP):
	return INPUT_UP and !disabled_up
	
func down_direction(INPUT_DOWN):
	return INPUT_DOWN and !disabled_down
	
func jump(INPUT_UP):
	
	slide_covered = 0
	$CollisionShape2DCrouch.disabled = true
	$CollisionShape2D.disabled = false
	
	if is_on_floor():
		is_allowed_to_jump = true
		if INPUT_UP:
			motion.y = JUMP_HEIGHT
			motion = move_and_slide(motion, UP)
			var player = AudioStreamPlayer.new()
			self.add_child(player)
			player.stream = load("res://Player/Sounds/Jump.wav")
			player.play()
			return
			return
	else:
		if INPUT_UP and is_allowed_to_jump:
			is_allowed_to_jump = false
			motion.y = JUMP_HEIGHT
			motion = move_and_slide(motion, UP)
			var player = AudioStreamPlayer.new()
			self.add_child(player)
			player.stream = load("res://Player/Sounds/Jump.wav")
			player.play()
	
func crouch(INPUT_DOWN):	
	if is_on_floor():	
		if INPUT_DOWN:
			$CollisionShape2DCrouch.disabled = false
			$CollisionShape2D.disabled = true
			block_movement = true


func is_player_walking():
	return Input.is_key_pressed(KEY_ALT) and !block_movement

func is_player_crouching():
	block_movement

func is_player_falling():
	return motion.y > 0 and !is_on_floor()

func is_player_jumping():
	return motion.y < 0 and !is_on_floor()
	
func is_player_running():
	return motion.x != 0  and !block_movement
	
func is_player_moving():
	return motion.y != 0 or motion.x != 0  and !block_movement
	
func is_player_idle():
	return motion == 0
	
func play_animation(animation_name):
	if animation_name != $Sprite.animation:
		$Sprite.play(animation_name)
