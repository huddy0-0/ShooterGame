extends CharacterBody3D

var noclip_enabled = false
var speed
var external_force = Vector3.ZERO


const WALK_SPEED = 5.0    
const SPRINT_SPEED = 8.0                                                                            
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const HIT_STAGGER = 4.0
const PROPEL_STRENGTH = 8.0

const BASE_FOV =  75.0                                                                              #Player FOV value
const FOV_CHANGE = 1.5                                                                              #Value for changing FOV (ie while sprinting)

signal player_hit                                                                          

const BOB_FREQ = 2.0                                                                                #Head bob frequency
const BOB_AMP = 0.08                                                                                #Head bob amplitude
var t_bob = 0.0                                                                                     #Variable for passing how far along a sine wave the head is

var gravity = 9.8

@onready var playerHead = $PlayerHead                                                               #Save the PlayerHead node for access
@onready var camera = $PlayerHead/Camera3D                                                          #Save the Camera node for access

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)                                                 #Hides/Locks mouse on start


#Handle Head Rotation
func _unhandled_input(event):                                                                       #Function called when any action is made by player
	if event is InputEventMouseMotion:                                                              #If there is mouse motion
		playerHead.rotate_y(-event.relative.x * SENSITIVITY)                                        #Rotate PlayerHead around the y axis relative to mouse movement along the x axis
		camera.rotate_x(-event.relative.y * SENSITIVITY)                                            #Rotate Camera around x axis relative to mouse movement along the y acis
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))               #Sets the camera rotation along the x axis to a range of -40 to 60                         


func _physics_process(delta):                                                                       #Built in function for gravity
	#Unlock Mouse
	if Input.is_action_just_pressed("unlock mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Toggle Noclip
	if Input.is_action_just_pressed("no_clip"):
		noclip_enabled = !noclip_enabled
	
	#Handle Gravity
	if not is_on_floor() and not noclip_enabled:                                                    #If player is not on the floor
		velocity.y -= gravity * delta                                                               #Add velocity down based on gravity
	
	#Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():                                      #If player presses jump action and is on the floor
		velocity.y = JUMP_VELOCITY                                                                  #Set player velocity along the y axis to the jump velocity
	
	#Handle Sprint
	if Input.is_action_pressed("sprint"):                                                           #If player is pressing sprint key
		speed = SPRINT_SPEED                                                                        #Set speed to SPRINT_SPEED
	else:                                                                                           #Otherwise, set speed to WALK_SPEED
		speed = WALK_SPEED
	
	#Handle Movement
	var input_velocity = Vector3.ZERO
	var input_dir = Input.get_vector("left", "right", "forward", "backward")                        #Built in player movement with custom actions
	var direction = (playerHead.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if noclip_enabled:
		var vertical_input = Input.get_action_strength("up") - Input.get_action_strength("down")
		var movement_input = Vector3(input_dir.x, vertical_input, input_dir.y)
	
		if movement_input.length() > 0:
			var move_dir = (playerHead.global_transform.basis * movement_input).normalized()
			velocity = move_dir * speed
		else:
			velocity = Vector3.ZERO
			
	else:
		if is_on_floor():                                                                           #If player is on the floor
			if direction:                                                                           #Give player normal movement
				input_velocity.x = lerp(velocity.x, direction.x * speed, delta * 10)
				input_velocity.z = lerp(velocity.z, direction.z * speed, delta * 10)
			else:
				input_velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
				input_velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
		else:                                                                                       #Otherwise (ie while jumping)
			input_velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)                   #Incrementally decrease movement with lerp
			input_velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	
	input_velocity.x += external_force.x
	input_velocity.z += external_force.z
	
	velocity.x = input_velocity.x
	velocity.z = input_velocity.z
	
	external_force = external_force.lerp(Vector3.ZERO, delta * 5.0)
	
	#Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())                                       #Incrementing t_bob as the speed of player with is_on_floor ensuring bobs occur only on ground/while not jumping
	camera.transform.origin = _headbob(t_bob)                                                       #Moves camera using the value derived from _headbob() function
	
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)                          #Some shi idrk, for changing the fov though
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()


#Function for Head Bob
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP                                                          #Idek some shit for the up and down head bob
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP                                                      #Still don't know, adds a horizontal head bob effect
	return pos

func hit(dir):
	emit_signal("player_hit")
	external_force += dir * HIT_STAGGER
