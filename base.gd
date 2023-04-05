extends StaticBody3D


var hitpoint = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multiplayer.is_server():
		if hitpoint >=0:
			rpcfree.rpc()

@rpc("call_local", "any_peer")
func damage(hp,from):
	if not is_multiplayer_authority(): return
	hitpoint -= hp
	get_tree().get_current_scene().send_message("DMG", from + " hit " + str(hp) + "(life: " + str(hitpoint) + ")",false)
	
@rpc("call_local","any_peer")
func rpcfree():
	queue_free()
