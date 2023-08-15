extends MeshInstance3D

var laser = preload("res://weapons/laser.tscn")
var trigger = true
var enemy = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_z(0.01)
	

@rpc("call_local", "any_peer")
func shoot(id):
	var inst = laser.instantiate()
	inst.position = $Guns.global_position
	inst.rotation = global_rotation 
	inst.name = id
	
	get_tree().get_current_scene().get_node("Space/Spawner").add_child(inst)

func _on_area_3d_body_entered(body):
	enemy += 1



func _on_trigger_timer_timeout():
	if enemy > 0:
		shoot.rpc(str(rid_allocate_id()))


func _on_area_3d_body_exited(body):
	enemy -= 1
