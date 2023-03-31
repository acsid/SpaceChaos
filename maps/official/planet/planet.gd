extends CSGMesh3D

var powerups = preload("res://powerup.tscn")

var population = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	if multiplayer.is_server():
		$Timer.start()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_z(deg_to_rad(0.05))
	pass


func _on_area_3d_body_entered(body):
	if multiplayer.is_server(): return
	if body.is_in_group("humans"):
		get_tree().get_current_scene().send_message("RADIO:" ,"You can orbit the planet",false)
		body.can_orbit = true
		body.orbit = global_position


func _on_area_3d_body_exited(body):
	if multiplayer.is_server(): return
	if body.is_in_group("humans"):
		get_tree().get_current_scene().send_message("RADIO:" ,"you are leaving the orbit",false)
		body.can_orbit = false
		body.orbit = global_position

@rpc("call_local","any_peer")
func spawn_powerup(n,rot):
	var inst = powerups.instantiate()
	inst.position = global_position
	inst.name = n
	inst.rotation = rot
	get_tree().get_current_scene().get_node("Space/Spawner").add_child(inst)

func _on_timer_timeout():
	if not is_multiplayer_authority(): return
	spawn_powerup.rpc(str(rid_allocate_id()),Vector3(0,0,deg_to_rad(randi_range(0,360))))
