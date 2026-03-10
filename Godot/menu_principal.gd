extends Control
@onready var remplir_pseudo = preload("res://remplir_pseudo.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_commencer_button_down() -> void:
	get_tree().change_scene_to_packed(remplir_pseudo)


func _on_btn_quitter_button_down() -> void:
	get_tree().quit()
