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

const BASE_FOV = 85.0
const FOV_CHANGE = 1.5

signal player_hit

const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

var gravity = 9.8

@onready var playerHead = $PlayerHead
@onready var camera = $PlayerHead/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		playerHead.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(80))

func _physics_process(delta):
	# Unlock mouse
	if Input.is_action_just_pressed("unlock mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Toggle noclip
	if Input.is_action_just_pressed("no_clip"):
		noclip_enabled = !noclip_enabled
		
	# Apply gravity
	if not is_on_floor() and not noclip_enabled:
		velocity.y -= gravity * delta
		
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Sprint speed
	speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
		
	# Movement
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (playerHead.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var input_velocity = Vector3.ZERO
		
	if noclip_enabled:
		var forward = -playerHead.global_transform.basis.z.normalized()
		var right = playerHead.global_transform.basis.x.normalized()
		var up = playerHead.global_transform.basis.y.normalized()
		
		var vertical_input = Input.get_action_strength("up") - Input.get_action_strength("down")
		var move_dir = (forward * -input_dir.y) + (right * input_dir.x) + (up * vertical_input)
	
		if move_dir.length() > 0:
			velocity = move_dir.normalized() * speed
		else:
			velocity = Vector3.ZERO
	else:
		if is_on_floor():
			if direction:
				input_velocity.x = lerp(velocity.x, direction.x * speed, delta * 10)
				input_velocity.z = lerp(velocity.z, direction.z * speed, delta * 10)
			else:
				input_velocity.x = lerp(velocity.x, 0.0, delta * 10)
				input_velocity.z = lerp(velocity.z, 0.0, delta * 10)
		else:
			input_velocity.x = lerp(velocity.x, direction.x * speed, delta * 3)
			input_velocity.z = lerp(velocity.z, direction.z * speed, delta * 3)
	
		input_velocity.x += external_force.x
		input_velocity.z += external_force.z
		velocity.x = input_velocity.x
		velocity.z = input_velocity.z
	
	# Decay external force
	external_force = external_force.lerp(Vector3.ZERO, delta * 5.0)
	
	# Head bob (only grounded)
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV effect
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Final movement step
	if noclip_enabled:
		global_translate(velocity * delta)
	else:
		move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func hit(dir):
	emit_signal("player_hit")
	external_force += dir * HIT_STAGGER
