# weapon_manager.gd
extends Node3D

@export var _weapon_resources: Array[Weapon_Resource]
@export var start_weapons: Array[String]                               # All weapons held at game start

var current_weapon_scene = null
var current_weapon_animation_player: AnimationPlayer = null
var weapon_stack = []                                                  # Weapons held in inventory 
var weapon_indicator = 0                                               # For tracking weapons in weapon_stack array
var next_weapon: String
var current_weapon_resource: Weapon_Resource = null

var weapon_list = {}                                                   # Dictionary for all weapons in the game

func _ready():
	Initialize(start_weapons)

func _input(event):
	if event.is_action_pressed("weapon_up"):
		print("Mouse Wheel up")
		#weapon_indicator = min(weapon_indicator+1, weapon_stack.size()-1)
		#exit(weapon_stack[weapon_indicator])
	
	if event.is_action_pressed("weapon_down"):
		print("Mouse Wheel down")
		#weapon_indicator = max(weapon_indicator-1, 0)
		#exit(weapon_stack[weapon_indicator])
		
	if event.is_action_pressed("shoot"):
		shoot()
	
	if event.is_action_pressed("reload"):
		reload()

func Initialize(_start_weapons: Array):
	for weapon in _weapon_resources:
		weapon_list[weapon.weapon_name] = weapon
	
	for i in _start_weapons:
		weapon_stack.push_back(i)
	
	if weapon_stack.size() > 0:
		var first_weapon_name = weapon_stack[0]
		var weapon_resource = weapon_list.get(first_weapon_name, null)
		if weapon_resource:
			equip_weapon(weapon_resource) 

# Call before changing weapons, ensures player not currently doing something
func exit(_next_weapon: String):
	if not current_weapon_resource:
		return
	
	if _next_weapon != current_weapon_resource.weapon_name:
		if current_weapon_animation_player.get_current_animation() != current_weapon_resource.unequip_anim:
			current_weapon_animation_player.play(current_weapon_scene.unequip_anim)
			next_weapon = _next_weapon

func change_weapon(weapon_name: String):
	var weapon_resource = weapon_list.get(weapon_name, null)
	next_weapon = ""
	equip_weapon(weapon_resource)

# Function for equiping weapon
func equip_weapon(weapon_res: Weapon_Resource):
	# Remove current weapon if one is equiped
	if current_weapon_scene:
		current_weapon_scene.queue_free()
	
	# Get the WeaponHoldPos from the Player
	var weapon_hold_pos = get_node("../WeaponHoldPos")
	current_weapon_scene = weapon_res.weapon_scene.instantiate()
	weapon_hold_pos.add_child(current_weapon_scene)

	# Store the corresponding animation player
	current_weapon_resource = weapon_res
	current_weapon_animation_player = current_weapon_scene.get_node("AnimationPlayer")
	
	if current_weapon_animation_player and weapon_res.equip_anim != "" and current_weapon_animation_player.has_animation(weapon_res.equip_anim):
		current_weapon_animation_player.play(weapon_res.equip_anim)
	

func shoot():
	current_weapon_animation_player.play(current_weapon_resource.shoot_anim)

func reload():
	current_weapon_animation_player.play(current_weapon_resource.reload_anim)
