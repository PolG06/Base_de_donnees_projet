extends Node

const CLICK_SOUND := preload("res://assets/ui_click.mp3")

var click_player: AudioStreamPlayer

func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = CLICK_SOUND
	click_player.bus = "Master"
	add_child(click_player)

func connect_buttons(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		_connect_button(root as Button)
	for child: Node in root.get_children():
		connect_buttons(child)

func _connect_button(button: Button) -> void:
	if button.has_meta("menu_audio_connected"):
		return
	button.set_meta("menu_audio_connected", true)
	button.pressed.connect(_play_click)

func _play_click() -> void:
	if click_player == null:
		return
	click_player.stop()
	click_player.play()
