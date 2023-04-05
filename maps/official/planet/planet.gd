extends CSGMesh3D

var powerups = preload("res://powerup.tscn")
var base = preload("res://base.tscn")

@export var population = 0
@export var colonisable = false
@export var colonise = false
enum avail_faction  {Humans,Parsilon,Pirates}
@export var faction = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	$Spawn.faction = faction
	if colonise:
		if multiplayer.is_server():
			$Timer.start()
			$Spawn.faction = faction
		var i = base.instantiate()
		add_child(i)
		#color = Color(0,0,1,1)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_z(deg_to_rad(0.05))
	%Area3D.rotate_z(deg_to_rad(0.1))
	if not colonise && population > 1:
		var i = base.instantiate()
		add_child(i)
		colonise = true
		$Spawn.faction = faction
		#material.albedo_color = Color(0,0,1,1)



func _on_area_3d_body_entered(body):
	if multiplayer.is_server(): return
	if body.is_in_group("player"):
		if body.faction == faction or colonisable != colonise:
			get_tree().get_current_scene().send_message("RADIO:" ,"You can orbit the planet",false)
			body.can_orbit = true
			body.orbit = self


func _on_area_3d_body_exited(body):
	if multiplayer.is_server(): return
	if body.is_in_group("player"):
		if body.faction == faction:
			get_tree().get_current_scene().send_message("RADIO:" ,"you are leaving the orbit",false)
			body.can_orbit = false

func get_orbit():
	return $Area3D/orbitpoint.global_position
	
@rpc("call_local", "any_peer")
func drop_pop(f):
	if not is_multiplayer_authority(): return
	population += 1
	if not colonise && population > 1:
		if multiplayer.is_server():
			faction = f
			$Timer.start()
			$Spawn.faction = faction
		var i = base.instantiate()
		add_child(i)
		colonise = true
		faction = f
		$Spawn.faction = faction
		
@rpc("call_local", "any_peer")
func pickup_pop():
	if not is_multiplayer_authority(): return
	population -= 1

@rpc("call_local","any_peer")
func spawn_powerup(n,rot):
	var inst = powerups.instantiate()
	inst.position = global_position
	inst.name = n
	inst.rotation = rot
	get_tree().get_current_scene().get_node("Space/Spawner").add_child(inst)

func _on_timer_timeout():
	if not is_multiplayer_authority(): return
	if colonise:
		spawn_powerup.rpc(str(rid_allocate_id()),Vector3(0,0,deg_to_rad(randi_range(0,360))))
		population += 1
