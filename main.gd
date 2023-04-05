extends Node

var version = "0.1-c"

var player = preload("res://player.tscn")
var map = preload("res://maps/official/solar_sys.tscn")
var powerup = preload("res://powerup.tscn")

var peer = ENetMultiplayerPeer.new()

var enter_key_pressed = false
var username = ""

var port = 42069
var me =  PackedScene.new()
enum avail_faction {Humans,Parsilon,Pirates}

var thread = null
signal upnp_complete


func _enter_tree():
	send_message("Space Chaos ",version,false)
# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.get_cmdline_args():
		print("arg ",OS.get_cmdline_args() )
		var arg = OS.get_cmdline_args() 
		print(arg[0])
		if OS.get_cmdline_args()[0] == "--server":
			print("Starting Space Chaos Dedicated Server")
			start_server()
	%Chatinput.hide()
	%Lobby.hide()
	%Host.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if %Lobby.visible:
		%Stats_ponline.text = str(get_tree().get_nodes_in_group("player").size());
	if multiplayer.is_server():
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		%Camera3D.position.x += input_dir.x
		%Camera3D.position.y -= input_dir.y
		if Input.is_key_pressed(KEY_KP_ADD):
			%Camera3D.position.z -= 1
			print(%Camera3D.position.z);
		if Input.is_key_pressed(KEY_KP_SUBTRACT):
			%Camera3D.position.z += 1
			print(%Camera3D.position.z);
		if Input.is_key_pressed(KEY_TAB):
			if %Lobby.visible:
				%Lobby.hide()
			else:
				%Lobby.show()

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
	send_message("Server","upnp start",false)
	thread = Thread.new()
	thread.start(_upnp_start.bind(port))
	load_game()

@rpc("call_local","any_peer")
func send_message(player_name,message,is_server):
	var HBox = HBoxContainer.new()
	var msg_node = %Message
	msg_node.add_child(HBox)
	var label_name = Label.new()
	if is_server:
		label_name.modulate = Color(1,0,0)
	label_name.text = player_name
	var label_msg = Label.new()
	label_msg.text = ": " + message
	HBox.add_child(label_name)
	HBox.add_child(label_msg)
	print(player_name,": ",message)
	#only keep last 10 msg
	if msg_node.get_child_count() > 10 :
		msg_node.get_child(0). queue_free()
	%ChatBox.show()
	if not %Lobby.visible:
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
	%Spawner.add_child(player_instanfce)
	#send_message.rpc(str(id), " Joined the game", false)
	
func remove_player(id):
	var playr = %Spawner.get_node_or_null(str(id))
	playr.queue_free()
	#send_message.rpc(str(id), " Left the game", false)
	
func load_game():
	send_message("Loading","Map",false)
	var map_instance = map.instantiate()
	%MapInstance.add_child(map_instance)
	%Menu.hide()
	show_lobby()

func show_lobby():
	%Lobby.show()
	if multiplayer.is_server():
		$Control/Lobby/VBoxContainer/HBoxContainer/VBoxContainer/faction1.hide()
		$Control/Lobby/VBoxContainer/HBoxContainer/VBoxContainer2/faction2.hide()
		$Control/Lobby/VBoxContainer/HBoxContainer/VBoxContainer3/faction3.hide()
func hide_lobby():
	%Lobby.hide()

func server_offline():
	%Menu.show()
	%MapInstance.get_child(0). queue_free()
	
	
	
func _upnp_start(server_port):
	var upnp = UPNP.new()
	var err = upnp.discover()
	
	if err != OK:
		push_error(str(err))
		emit_signal("upnp_complete", err)
		return
	
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "UDP")
		upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "TCP")
		emit_signal("upnp_completed", OK)

	
func _exit_tree():
	if thread:
		print('missing something')
	
func spawn_random(faction = avail_faction.Pirates):
	var good_spawn = false
	#var rnd = get_tree().get_nodes_in_group("Spawners").pick_random()
	while !good_spawn:
		var rnd = get_tree().get_nodes_in_group("Spawners").pick_random()
		if rnd.faction == faction:
			good_spawn = true
			return rnd.global_position

func _on_upnp_complete(status):
	if (status == 27) :
		send_message("UPNP"," Cannot find upnp device " + str(status) ,true)
	else:
		send_message("UPNP","Error: " + str(status) ,false)

func update_UiScore(score):
	%score.text = str(score)
	
func _on_timer_chatbox_timeout():
	%ChatBox.hide()

func _on_faction_1_pressed():
	send_message("","Join as humans",true)
	me.add_to_group("humans")
	me.respawn(avail_faction.Humans)

func _on_faction_2_pressed():
	send_message("Game","Join as Parsilon",true)
	me.add_to_group("Parsilon")
	me.respawn(avail_faction.Parsilon)

func _on_button_host_pressed():
	start_server()
	%Host.hide()

func _on_button_pressed():
	%Host.hide()
	%Menu.show()

func _on_faction_3_pressed():
	send_message("Game","Join as a Pirates",true)
	me.add_to_group("Pirates")
	me.respawn(avail_faction.Pirates)

