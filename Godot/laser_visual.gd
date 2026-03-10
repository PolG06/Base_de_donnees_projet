extends Node2D

@onready var main = get_parent()

func _process(_delta):
	if main.jeu_actif:
		queue_redraw()

func _draw():
	if main.jeu_actif:
		var mouse_pos = get_local_mouse_position()
		var p_pos = main.player.position
		var dir = (mouse_pos - p_pos).normalized()
		var impact = main.get_laser_end_point(p_pos+main.player.size/2, dir)
		
		draw_line(p_pos+main.player.size/2, impact, Color.RED, 15)
