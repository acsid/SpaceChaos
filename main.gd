extends Node

var version = "0.1-c"

var player = preload("res://player.tscn")
var map = preload("res://maps/official/solar_sys.tscn")

var powerup = preload("res://powerup.tscn")

var peer = ENetMultiplayerPeer.new()

var enter_key_pressed = false
var username = ""

var port = 42066

# Called when the node enters the scene tree for the first time.
func _ready():
	send_message("Space Chaos ",version,false)
	%Chatinput.hide()
	%Lobby.hide()
	%Host.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	pass



func _input(event):
	if %Menu.visible: return
	if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
		if not enter_key_pressed:
			enter_key_pressed = true
			%Chatinput.visible = !%Chatinput.visible
			
			if not %Chatinput.visible:
				if %InputMessage.text != "":
					send_message.rpc(%Username.text,%InputMessage.text,multiplayer.is_server())
					%InputMessage.text = ""
				%Timer_Chatbox.start()
			else:
				%Chatinput.show()
				%InputMessage.grab_focus()
				%Timer_Chatbox.stop()
	else:
		enter_key_pressed = false

func _on_host_button_pressed():
	%Menu.hide()
	%Host.show()


func start_server():
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	send_message("Server","started waiting for players",false)
	load_game()


@rpc("call_local","any_peer")
func send_message(player_name,message,is_server):
	var HBox = HBoxContainer.new()
	var msg_node = %Message
	msg_node.add_child(HBox)
	var label_name = Label.new()
	if is_server:
		player_name = "@SERVER"
		label_name.modulate = Color(1,0,0)
	label_name.text = player_name
	var label_msg = Label.new()
	label_msg.text = ": " + message
	HBox.add_child(label_name)
	HBox.add_child(label_msg)
	#only keep last 10 msg
	if msg_node.get_child_count() > 10 :
		msg_node.get_child(0). queue_free()
	%ChatBox.show()
	%Timer_Chatbox.start()



func _on_join_button_pressed():
	if %ServerHost.text == "":
		%ServerHost.text = "localhost"
	if %ServerPort.text == "":
		%ServerPort.text = str(port)
	peer.create_client(%ServerHost.text,port)
	multiplayer.multiplayer_peer = peer
	if %Username.text == "":
		%Username.text = "Unamed"

	username = %Username.text
	send_message("Connecting to server",%ServerHost.text,false)
	multiplayer.server_disconnected.connect(server_offline)
	load_game()

func add_player(id):
	var player_instanfce = player.instantiate()
	player_instanfce.name = str(id)
	player_instanfce.position = spawn_random()
	%Spawner.add_child(player_instanfce)
	#send_message.rpc(str(id), " Joined the game", false)
	
func remove_player(id):
	var player = %Spawner.get_node_or_null(str(id))
	player.queue_free()
	#send_message.rpc(str(id), " Left the game", false)
	
func load_game():
	send_message("Loading","Map",false)
	var map_instance = map.instantiate()
	%MapInstance.add_child(map_instance)
	%Menu.hide()

func server_offline():
	%Menu.show()
	%MapInstance.get_child(0). queue_free()

func spawn_random():
	var rnd = get_tree().get_nodes_in_group("Spawners").pick_random().global_position 
	rnd.z = 0
	return rnd
	#print(get_tree().get_nodes_in_group("Spawners").size())


func update_UiScore(score):
	%score.text = str(score)
	
func _on_timer_chatbox_timeout():
	%ChatBox.hide()





func _on_faction_1_pressed():
	pass # Replace with function body.


func _on_faction_2_pressed():
	pass # Replace with function body.


func _on_button_host_pressed():
	start_server()
	%Host.hide()


func _on_button_pressed():
	%Host.hide()
	%Menu.show()
