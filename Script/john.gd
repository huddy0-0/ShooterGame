extends CharacterBody3D

var player = null
var state_machine
var propel_force = Vector3.ZERO


const SPEED = 4.0
const ATTACK_RANGE = 1.5
const PROPEL_STRENGTH = 8.0

@export var player_path := "../Player"

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var palmer_texture = preload("res://IMG_86141.jpg")
@onready var john_texture = preload("res://IMG_86142.jpg")
@onready var aiden_texture = preload("res://IMG_86143.jpg")



func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	
	var sphere = $Armature/Skeleton3D/Head2Attachment3D/CSGSphere3D
	_randomize_texture(sphere)

func _process(delta):
	if player == null:
		return
	
	var movement_velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Walk":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			movement_velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			look_at(Vector3(global_position.x + movement_velocity.x, global_position.y, global_position.z + movement_velocity.z), Vector3.UP)
		"DropKick":
			var direction = (player.global_position - global_position).normalized()
			movement_velocity = direction * (SPEED * 0.5)  
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	movement_velocity += propel_force
	
	propel_force = propel_force.lerp(Vector3.ZERO, delta * 5.0)
	
	velocity = movement_velocity
	move_and_slide()
	
	#Conditions
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	anim_tree.get("parameters/playback")

func _target_in_range():
	if player == null:
		return false
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	

func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)

func propel_forward():
	if player == null:
		return
	var direction = (player.global_position - global_position).normalized()
	propel_force = direction * PROPEL_STRENGTH

func _randomize_texture(sphere):
	if sphere.material_override == null:
		sphere.material_override = StandardMaterial3D.new()
		
	var random_value = randi() % 3
	var chosen_texture
	match random_value:
		0: chosen_texture = palmer_texture
		1: chosen_texture = john_texture
		2: chosen_texture = aiden_texture
		_: chosen_texture = john_texture
	
	sphere.material_override.albedo_texture = chosen_texture
