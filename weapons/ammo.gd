extends Area3D


@export var damage = 1
@export var hp = 1
var from = "@SERVER"

# Called when the node enters the scene tree for the first time.
func _ready():
	position.z = 0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	translate(Vector3(0,0.9,0).normalized())

@rpc("call_local","any_peer")
func rpcfree():
	queue_free()

func _on_body_entered(body):
	if multiplayer.is_server():
		hp -= 1
		body.damage.rpc(damage,name)
		if hp <= 0:
			rpcfree.rpc()


func _on_timer_timeout():
	queue_free()
