extends MeshInstance3D

var laser = preload("res://weapons/laser.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_z(0.01)
	pass

@rpc("call_local", "any_peer")
func shoot(id):
	var inst = laser.instantiate()
	inst.position = $Guns.global_position
	inst.rotation = rotation
	inst.name = id
	
	get_tree().get_current_scene().get_node("Space/Spawner").add_child(inst)

func _on_area_3d_body_entered(body):
	shoot.rpc(str(rid_allocate_id()))
	print("shoot")
	pass # Replace with function body.
