extends Control

@onready var input = $Background/LineEdit

func _on_btn_ok_button_down() -> void:
	Global.pseudo_joueur = input.text
	get_tree().change_scene_to_file("res://main.tscn")
