extends Resource
class_name Weapon_Resource

@export var weapon_name : String
@export var equip_anim: String
@export var shoot_anim: String
@export var reload_anim : String

#To be implemented
@export var unequip_anim: String
@export var ammo_empty_anim: String

@export var current_ammo: int                #amt of ammo able to be shot
@export var reserve_ammo: int                #amt of ammo you have to reload from
@export var magazine_ammo: int               #total ammo each gun can hold
@export var max_ammo: int                    #total ammo you can hold in reserve

@export var auto_fire: bool

@export var weapon_scene: PackedScene
