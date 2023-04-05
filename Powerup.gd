extends Area3D
var points = 10
var free = false

# Called when the node enters the scene tree for the first time.
func _ready():

	pass
	#rotation = Vector3(0,0,deg_to_rad(randi_range(0,360)))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(Vector3(0,0.01,0))
	$CSGMesh3D.rotate_z(0.1)
	if free:
		queue_free()
		
@rpc("call_local","any_peer")
func rpcfree():
	free = true

func _on_body_entered(body):
	if not multiplayer.is_server(): return
	if body.is_in_group("humans"):
		body.addScore.rpc(points)
		rpcfree.rpc()


func _on_timer_timeout():
	if not multiplayer.is_server(): return
	rpcfree.rpc()
