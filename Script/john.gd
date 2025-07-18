extends CharacterBody3D

var player = null
var state_machine
var propel_force = Vector3.ZERO
var was_in_attack_range = false
var attacking = false

const SPEED = 4.0
const ATTACK_RANGE = 2
const PROPEL_STRENGTH = 10.0

@export var player_path := "../Player"
@onready var path_points := get_node(player_path + "/PathPoints")
var player_target

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var palmer_texture = preload("res://Texture/OrbHeads/palmer.png")
@onready var john_texture = preload("res://Texture/OrbHeads/john.png")
@onready var aiden_texture = preload("res://Texture/OrbHeads/aidan.png")

func _ready():
	player = get_node(player_path)
	var markers = path_points.get_children()
	player_target = markers[randi() % markers.size()]
	state_machine = anim_tree.get("parameters/playback")
	
	var cube = $Armature/Skeleton3D/Head2Attachment3D/CSGBox3D
	_randomize_texture(cube)

func _process(delta):
	if player == null:
		return
	
	var movement_velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"Walk":
			nav_agent.set_target_position(player_target.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			movement_velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			look_at(Vector3(global_position.x + movement_velocity.x, global_position.y, global_position.z + movement_velocity.z), Vector3.UP)
		
		"DropKick":
			look_at(Vector3(player.global_position.x, global_position.y, player_target.global_position.z), Vector3.UP)
	
	
	movement_velocity += propel_force
	propel_force = propel_force.lerp(Vector3.ZERO, delta * 5.0)
	
	velocity = movement_velocity
	move_and_slide()
	
	# Attack recovery
	var current_state = state_machine.get_current_node()
	if current_state == "Walk":
		attacking = false
	
	# Attack logic
	var in_attack_range = _target_in_range()
	if in_attack_range and not was_in_attack_range:
		_choose_attack()
	was_in_attack_range = in_attack_range

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

func _randomize_texture(cube):
	if cube.material_override == null:
		cube.material_override = StandardMaterial3D.new()
	
	var random_value = randi() % 3
	var chosen_texture
	match random_value:
		0: chosen_texture = palmer_texture
		1: chosen_texture = john_texture
		2: chosen_texture = aiden_texture
		_: chosen_texture = john_texture
	
	cube.material_override.albedo_texture = chosen_texture

func _choose_attack():
	if attacking:
		return
	attacking = true
	state_machine.travel("DropKick")
