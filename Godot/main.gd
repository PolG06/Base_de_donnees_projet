extends Node2D

# Signal pour les autres nœuds du projet
signal tir_finalise(position_joueur, position_impact)

@onready var plateform = $Lava/Plateform
@onready var lava = $Lava
@onready var player = $Player
@onready var socket = $SocketClient

var temps_restant : float = 10.0
var jeu_actif : bool = true
var dernier_seconde_affichee : int = 11

func _ready():
	if socket.has_method("connect_socket"):
		# Essayer de passer un dictionnaire de configuration
		var config = {
			"host": "127.0.0.1",
			"port": 3000,
			"path": "/socket.io/"
		}
		socket.connect_socket(config) 
		print("Connexion lancée via dictionnaire")
	else:
		print("Erreur: connect_socket attend peut-être d'autres arguments.")

func _process(delta):
	if jeu_actif:
		temps_restant -= delta
		var seconde_actuelle = ceil(temps_restant)
		
		if seconde_actuelle < dernier_seconde_affichee and seconde_actuelle >= 0:
			print("Temps restant : ", seconde_actuelle)
			dernier_seconde_affichee = seconde_actuelle

		if temps_restant <= 0:
			fin_du_compte_a_rebours()
		else:
			Get_mouvements()
			verifier_collision_lave()
			queue_redraw()

func get_player_center() -> Vector2:
	return player.position + (player.size / 2)

func _draw():
	if jeu_actif:
		var mouse_pos = get_local_mouse_position()
		var center = get_player_center()
		var direction = (mouse_pos - center).normalized()
		var impact_point = get_laser_end_point(center, direction)
		draw_line(center, impact_point, Color.RED, 10)

func fin_du_compte_a_rebours():
	jeu_actif = false
	print("TEMPS ÉCOULÉ !")
	
	var center = get_player_center()
	var mouse_pos = get_local_mouse_position()
	var direction_tir = (mouse_pos - center).normalized()
	var impact_final = get_laser_end_point(center, direction_tir)

	
	# 1. Émission du signal interne
	tir_finalise.emit(center, impact_final)
	
	
	queue_redraw()
	
	var data = {
		"player_id": 1,
		"shoot_order": 1,
		"is_alive": true,
		"pos_x": player.position.x,
		"pos_y": player.position.y,
		"shoot_dir_x": direction_tir.x,
		"shoot_dir_y": direction_tir.y
	}
	
	# 2. Envoi au serveur Node.js via le socket
	socket.emit("submit_shot", data)
	
	print("Données envoyées au serveur : ", data)
	return data

func get_laser_end_point(origin: Vector2, dir: Vector2) -> Vector2:
	var rect_min = lava.position 
	var rect_max = lava.position + lava.size
	var t_x = INF
	var t_y = INF
	
	if dir.x > 0: t_x = (rect_max.x - origin.x) / dir.x
	elif dir.x < 0: t_x = (rect_min.x - origin.x) / dir.x
		
	if dir.y > 0: t_y = (rect_max.y - origin.y) / dir.y
	elif dir.y < 0: t_y = (rect_min.y - origin.y) / dir.y

	var t = min(t_x, t_y)
	return origin + dir * t

func Get_mouvements():
	if(Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)): player.position.x += 7
	if(Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_Q)): player.position.x -= 7
	if(Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_Z)): player.position.y -= 7
	if(Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S)): player.position.y += 7
		
func verifier_collision_lave():
	var center_global = player.global_position + (player.size / 2)
	var plat_min = plateform.global_position
	var plat_max = plateform.global_position + plateform.size
	
	if center_global.x < plat_min.x or center_global.x > plat_max.x or \
	   center_global.y < plat_min.y or center_global.y > plat_max.y:
		jeu_actif = false
		player.visible = false 
		print("GAME OVER : Le joueur a quitté la plateforme !")
		queue_redraw()
		
		
