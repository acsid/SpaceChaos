extends CharacterBody3D
enum state {free,orbit}

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var rotation_speed:= 100.0
@export var max_speed := 15.0
@export var acceleration := 1.0
@export var hitpoint := 100
@export var shield := 10
@export var shield_regen := 0.1
@export var username := ""
var can_orbit = false
var orbit = PackedScene.new()
var is_orbit = false
var canshoot = true
var d := 0.0
var laser = preload("res://weapons/laser.tscn")
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var score = 0
@export var alive = true
@export var population = 0
enum avail_faction {Humans,Persilon,Pirates}
@export var faction = avail_faction.Humans
func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	



func _ready():
	if not is_multiplayer_authority(): return
	$Camera3D.make_current()
	var main = get_tree().get_current_scene()
	username = main.username
	#position = main.spawn_random(faction)
	position = Vector3(0,0,0)
	main.send_message.rpc("--",username + " Has joined the battle",false)
	main.me = self
	lobby()
	
	
func lobby():
	var main = get_tree().get_current_scene()
	hide()
	$CollisionShape3D.disabled = true
	alive = false
	main.show_lobby()

func _process(delta):
	if not alive: 
		return
	if not is_multiplayer_authority():	return
	if %Planet.visible:
		%POP.text = str(orbit.population)
		%Planet_name.text = orbit.name
		if not can_orbit:
			%Planet.hide
	if population > 0 && not $Cargo.visible: 
		$Cargo.show()
	elif population < 1 && $Cargo.visible:
		$Cargo.hide()
	if Input.is_action_just_pressed("orbit"):
		if can_orbit:
			if is_orbit:
				is_orbit = false
				%Planet.hide()
			else:
				is_orbit = true
				%Planet.show()
	if Input.is_action_pressed("shoot") and canshoot:
		shoot.rpc(str(rid_allocate_id()))
		canshoot = false
		%Cooldown.start()
	if hitpoint <= 0:
		lobby()


func respawn(f = avail_faction.Humans):
	if not is_multiplayer_authority(): return
	var main = get_tree().get_current_scene()
	score = 0
	hitpoint = 100
	show()
	position.z = 0
	main.hide_lobby()
	self.position = main.spawn_random(f)
	alive = true
	faction = f
	$CollisionShape3D.disabled = false

func _physics_process(delta):
	if not alive: return
	if not is_multiplayer_authority(): return
	# Add the gravity.
	orbiting()
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(0, -input_dir.y, 0)).normalized()
	velocity += direction * acceleration
	#velocity = velocity.rotated(Vector3(0,0,1),rotation.z)
	velocity = velocity.limit_length(max_speed)

	rotate_z(deg_to_rad(-input_dir.x*rotation_speed*delta))
	
	if input_dir.y == 0:
		velocity = velocity.move_toward(Vector3.ZERO,0.1)
	
	move_and_slide()
	

func orbiting():
	if can_orbit && is_orbit:
		var orbi = orbit.get_orbit()
		position = position.move_toward(orbi,0.1)
	else:
		is_orbit = false
	
	
@rpc("call_local", "any_peer")
func addScore(pts):
	score += pts
	if not is_multiplayer_authority(): return
	get_tree().get_current_scene().update_UiScore(score)

@rpc("call_local", "any_peer")
func shoot(id):
	var inst = laser.instantiate()
	inst.position = $Guns.global_position
	inst.rotation = rotation
	inst.name = id
	
	get_tree().get_current_scene().get_node("Space/Spawner").add_child(inst)

@rpc("call_local", "any_peer")
func damage(hp,from):
	if not is_multiplayer_authority(): return
	hitpoint -= hp
	get_tree().get_current_scene().send_message("DMG", from + " hit " + str(hp) + "(life: " + str(hitpoint) + ")",false)
	
@rpc("call_local", "any_peer")
func pickup_pop():
	if not is_multiplayer_authority(): return
	if orbit.population > 2:
		population += 1
		orbit.pickup_pop.rpc()
		get_tree().get_current_scene().send_message("RADIO"," pickup",false)
	
@rpc("call_local", "any_peer")
func drop_pop():
	if not is_multiplayer_authority(): return
	if orbit.faction != faction && orbit.colonise: return
	if population > 0:
		population -= 1
		orbit.drop_pop.rpc(faction)

func _on_cooldown_timeout():
	canshoot = true


func _on_timer_timeout():
	respawn()


func _on_grab_pressed():
	pickup_pop.rpc()


func _on_drop_pressed():
	drop_pop.rpc()
	
