extends Node
class_name MultiplayerClient

# Client HTTP lÃ©ger pour synchroniser les tours multijoueurs.
# Encapsule les appels REST vers le serveur Node (multiplayer_server.js).

signal push_ok(server_id: int)
signal push_failed(message: String)
signal pull_ok(rows: Array, active_players: Array)
signal pull_failed(message: String)

var server_url: String = ""

var _http_push: HTTPRequest
var _http_pull: HTTPRequest
var _http_join: HTTPRequest
var _http_start: HTTPRequest

func setup(url: String) -> void:
	# PrÃ©pare les requÃªtes HTTP et stocke l'URL.
	server_url = url.strip_edges()
	if server_url == "":
		server_url = "http://localhost:3000"
	if not server_url.begins_with("http"):
		server_url = "http://" + server_url
	_ensure_requests()

func _ensure_requests() -> void:
	if _http_push == null:
		_http_push = HTTPRequest.new()
		_http_push.request_completed.connect(_on_push_completed)
		add_child(_http_push)
	if _http_pull == null:
		_http_pull = HTTPRequest.new()
		_http_pull.request_completed.connect(_on_pull_completed)
		add_child(_http_pull)
	if _http_join == null:
		_http_join = HTTPRequest.new()
		_http_join.request_completed.connect(_on_join_completed)
		add_child(_http_join)
	if _http_start == null:
		_http_start = HTTPRequest.new()
		_http_start.request_completed.connect(_on_start_completed)
		add_child(_http_start)

func push_turn(payload: Dictionary) -> void:
	# Envoie un tour vers le serveur (POST /turn).
	if _http_push == null:
		_ensure_requests()
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(payload)
	var err: int = _http_push.request(server_url + "/turn", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_failed.emit("Impossible d'envoyer la mise Ã  jour (%s)" % error_string(err))

func pull_since(last_id: int) -> void:
	# RÃ©cupÃ¨re les tours plus rÃ©cents que last_id (GET /turns?since=...).
	if _http_pull == null:
		_ensure_requests()
	var url := "%s/turns?since=%d" % [server_url, last_id]
	var err: int = _http_pull.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		pull_failed.emit("Impossible de rÃ©cupÃ©rer les donnÃ©es (%s)" % error_string(err))

func join_lobby(player_name: String) -> void:
	if _http_join == null:
		_ensure_requests()
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify({"player_name": player_name})
	var err: int = _http_join.request(server_url + "/join", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		pull_failed.emit("Impossible de rejoindre le serveur (%s)" % error_string(err))

func start_lobby(player_name: String) -> void:
	if _http_start == null:
		_ensure_requests()
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify({"player_name": player_name})
	var err: int = _http_start.request(server_url + "/start", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		pull_failed.emit("Impossible de dÃ©marrer (%s)" % error_string(err))

func _on_push_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		push_failed.emit("Serveur indisponible (code %d)" % response_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("id"):
		push_failed.emit("RÃ©ponse inattendue du serveur.")
		return
	push_ok.emit(int(parsed["id"]))

func _on_pull_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		pull_failed.emit("Erreur de rÃ©cupÃ©ration (code %d)" % response_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("turns"):
		pull_failed.emit("Format de rÃ©ponse invalide.")
		return
	var rows: Array = parsed["turns"]
	var active_players: Array = parsed.get("active_players", [])
	var started: bool = bool(parsed.get("started", false))
	pull_ok.emit(rows, active_players, started)

func _on_join_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		pull_failed.emit("Impossible de rejoindre (code %d)" % response_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var started: bool = bool(parsed.get("started", false))
	pull_ok.emit([], [], started)

func _on_start_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		pull_failed.emit("Impossible de dÃ©marrer (code %d)" % response_code)
		return
	pull_ok.emit([], [], true)
