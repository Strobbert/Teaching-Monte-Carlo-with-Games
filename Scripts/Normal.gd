extends Node2D

#region variables
enum GameState{
	Playing,
	Sheet,
	Over,
	Done,
	Policy,
	TestPolicy,
	OverTestPol,
}

const tileScene = preload("res://Scenes/Tile.tscn")
const gameoverUI = preload("res://Scenes/game_over.tscn")
const no_policyUI = preload("res://Scenes/no_policy.tscn")
const policy_buttonsUI = preload("res://Scenes/policy_buttons.tscn")
const overPolicyTestUI = preload("res://Scenes/policy_test_over.tscn")
const scoresheetUI = preload("res://Scenes/score_sheet.tscn")
const doneUI = preload("res://Scenes/Done.tscn")

@onready var base: TileMapLayer = $Grid
@onready var extras: TileMapLayer = $States

@export var time_out: float

var state: GameState:
	set(value):
		delete_current_UI()
		match value:
			GameState.Playing:
				current_sprite.visible = false
				start_game()
			GameState.Sheet:
				current_sprite.visible = false
				start_sheet()
			GameState.Over:
				current_sprite.visible = false
				end_game()
			GameState.Done:
				current_sprite.visible = false
				game_done()
			GameState.Policy:
				if state == GameState.Over:
					highscore = 0
				current_sprite.visible = true
				current_sprite.position = Navigation.grid_to_world(Vector2i.ZERO)
				current_tile = get_tile(Vector2i.ZERO)
				start_policy()
			GameState.TestPolicy:
				current_sprite.visible = false
				start_test_policy()
			GameState.OverTestPol:
				current_sprite.visible = false
				start_OTP()
		state = value

var player: Vector2i:
	set(value):
		if value == -Vector2i.ONE:
			player = value
			return
		extras.erase_cell(player)
		player = Navigation.clamp_to_grid(value)
		extras.set_cell(player, 0, Vector2i.ZERO)
var end: Vector2i
var player_start_pos: Vector2i

var all_good: Array[Vector2i]
var all_bad: Array[Vector2i]
var score: int = 0
var specials: Dictionary

var highscore: int
var current_tile: Tile
@onready var current_sprite: Sprite2D = $Current 
var tiles: Array[Array]
var pi_policy: Dictionary
var sm_policy: Dictionary
var currentUI:Node = null
var number_of_games: int
var previous_guesses: Array[int] = [0,0,0,0]

#endregion

#region Set-up code

func _ready() -> void:
	Navigation.set_up(base, -1)
	$Timer.wait_time = time_out
	number_of_games = 0
	reset()
	# create_tiles()

func create_tiles() -> void:
	for x in range(base.get_used_rect().size.x):
		var row = []
		for y in range(base.get_used_rect().size.y):
			var new_tile = tileScene.instantiate()
			new_tile.position = Navigation.grid_to_world(Vector2i(x, y))
			$Tiles.add_child(new_tile)
			row.append(new_tile)
		tiles.append(row)

func reset() -> void:
	number_of_games += 1
	specials = {}
	player_start_pos = Navigation.get_random_cornor()
	state = GameState.Playing
	player = player_start_pos
	end = base.get_used_rect().size + base.get_used_rect().position - Vector2i.ONE - player_start_pos
	specials[end] = Globals.end_value
	extras.set_cell(end, 0, Vector2i.ONE)
	set_good_and_bad()

	score = 0
	highscore = int(-INF)

	player = player_start_pos
	Policy.create_grid(base.get_used_rect(), player_start_pos, end, all_good, all_bad)
	sm_policy = {}

func set_good_and_bad() -> void:
	all_good = []
	all_bad = []
	var areas: Array[Rect2i] = []
	for x in range(0, 8, 2):
		for y in range(0, 6, 2):
			var start = Vector2i(x, y)
			var area = Rect2i(start, Vector2i.ONE * 2)
			if area.has_point(player) or area.has_point(end):
				continue
			areas.append(area)
	for x in range(6 + randi() % 3):
		areas.shuffle()
		var area = areas.pop_front()
		var point = Navigation.get_random_tile(area)
		if randi() % 2 == 0:
			all_bad.append(point)
		else:
			all_good.append(point)
	show_good_and_bad()
	
func show_good_and_bad() -> void:
	for tile in all_good:
		extras.set_cell(tile, 0, Vector2i.RIGHT)
		specials[tile] = Globals.yellow_value
	for tile in all_bad:
		extras.set_cell(tile, 0, Vector2i.DOWN)
		specials[tile] = Globals.red_value

func restart() -> void:
	number_of_games += 1
	state = GameState.Playing
	player = player_start_pos
	extras.set_cell(end, 0, Vector2i.ONE)
	show_good_and_bad()
	score = 0

#endregion

#region Playing Code

func update_score() -> void:
	if not specials.has(player):
		score += Globals.step_value
		return
	match specials[player]:
		Globals.end_value:
			score += Globals.end_value
			if state == GameState.Playing:
				state = GameState.Sheet
		Globals.yellow_value:
			score += Globals.yellow_value
			specials.erase(player)
		Globals.red_value:
			score += Globals.red_value
			specials.erase(player)
		_:
			score += Globals.step_value

func start_game() -> void:
	extras.clear()

#endregion

#region Score Code

func start_sheet() -> void:
	currentUI = scoresheetUI.instantiate()
	add_child(currentUI)
	$Sheet/PanelContainer/VBoxContainer2/Button.pressed.connect(end_score)
	$Sheet/PanelContainer/VBoxContainer/Score.text = "Your score was: " + str(score)
	$Sheet/PanelContainer/VBoxContainer2/HBoxContainer/SpinBox.value = previous_guesses[0]
	$Sheet/PanelContainer/VBoxContainer2/HBoxContainer2/SpinBox.value = previous_guesses[1]
	$Sheet/PanelContainer/VBoxContainer2/HBoxContainer3/SpinBox.value = previous_guesses[2]
	$Sheet/PanelContainer/VBoxContainer2/HBoxContainer4/SpinBox.value = previous_guesses[3]

func end_score() -> void:
	previous_guesses[0] = int($Sheet/PanelContainer/VBoxContainer2/HBoxContainer/SpinBox.value)
	previous_guesses[1] = int($Sheet/PanelContainer/VBoxContainer2/HBoxContainer2/SpinBox.value)
	previous_guesses[2] = int($Sheet/PanelContainer/VBoxContainer2/HBoxContainer3/SpinBox.value)
	previous_guesses[3] = int($Sheet/PanelContainer/VBoxContainer2/HBoxContainer4/SpinBox.value)
	
	if previous_guesses == Globals.to_array():
		state = GameState.Done
	else:
		state = GameState.Over

func game_done() -> void:
	currentUI = doneUI.instantiate()
	add_child(currentUI)
	if number_of_games > 1:
		$Done/PanelContainer/VBoxContainer/Games.text = "You've guessed the rewards in " + str(number_of_games) + " games"
	else:
		$Done/PanelContainer/VBoxContainer/Games.text = "You've guessed the rewards in " + str(number_of_games) + " game"
#endregion

#region Game Over Code

func end_game() -> void:
	currentUI = gameoverUI.instantiate()
	add_child(currentUI)
	$GameOver/PanelContainer/VBoxContainer/Button.pressed.connect(reset)
	$GameOver/PanelContainer/VBoxContainer/Button2.pressed.connect(restart)
	if score > highscore:
		highscore = score
		$GameOver/PanelContainer/VBoxContainer/New.visible = true
		$GameOver/PanelContainer/VBoxContainer/High.text = "Current Highscore: " + str(highscore)
	else:
		$GameOver/PanelContainer/VBoxContainer/New.visible = false
	$GameOver/PanelContainer/VBoxContainer/Score.text = str(score)

#endregion

#region Policy Code

func set_policy_dir(dir: Directions.Dir) -> void:
	if current_tile:
		current_tile.toggle_direction(dir)

func tiles_to_policy() -> Dictionary:
	var policy = {}
	for x in tiles.size():
		for y in tiles[0].size():
			policy[Policy.vector_to_pos(Vector2i(x, y))] = tile_to_prob(tiles[x][y])
	return policy

func tile_to_prob(tile: Tile) -> Array[float]:
	var to_return: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for dir in tile.policy:
		to_return[dir] = 1.0 / tile.policy.size()
	return to_return

func policy_to_tiles(policy: Dictionary) -> void:
	for tile in policy.keys():
		var prob = policy[tile]
		var pos = Policy.pos_to_vector(tile)
		if pos == end:
			continue
		if prob != [0.0, 0.0, 0.0, 0.0]:
			set_tile_probs(tiles[pos.x][pos.y], prob)

func set_tile_probs(tile: Tile, probs: Array[float]) -> void:
	tile.clear_policy()
	for x in range(4):
		if probs[x] > 0.05:
			tile.toggle_direction(x)

func start_policy() -> void:
	currentUI = policy_buttonsUI.instantiate()
	add_child(currentUI)
	player = player_start_pos
	extras.set_cell(end, 0, Vector2i.ONE)
	show_good_and_bad()
	extras.modulate = Color(1, 1, 1, 0.5)
	pi_policy = Policy.policy_iteration(Policy.random_policy(), 0.001, 0.75)
	$PolicyButtons/Buttons/PolicyBoxes/SP.pressed.connect(set_policy_button)
	$PolicyButtons/Buttons/PolicyBoxes/CP.pressed.connect(clear_tile_directions)
	$PolicyButtons/Buttons/PolicyBoxes/MC.pressed.connect(apply_MC)
	$PolicyButtons/Buttons/PolicyBoxes/PI.pressed.connect(show_pi_policy)
	$PolicyButtons/Buttons/CreatPolicy/Up.pressed.connect(set_policy_dir.bind(0))
	$PolicyButtons/Buttons/CreatPolicy/Right.pressed.connect(set_policy_dir.bind(1))
	$PolicyButtons/Buttons/CreatPolicy/Down.pressed.connect(set_policy_dir.bind(2))
	$PolicyButtons/Buttons/CreatPolicy/Left.pressed.connect(set_policy_dir.bind(3))

func clear_tile_directions() -> void:
	for x in tiles.size():
		for y in tiles[0].size():
			tiles[x][y].clear_policy()

func end_setting_policy() -> void:
	sm_policy = tiles_to_policy()
	$PolicyButtons/Buttons/CreatPolicy.visible = false
	$PolicyButtons/Buttons/PolicyBoxes.visible = true

func set_policy_button() -> void:
	$PolicyButtons/Buttons/CreatPolicy.visible = true
	$PolicyButtons/Buttons/PolicyBoxes.visible = false
	clear_tile_directions()
	policy_to_tiles(sm_policy)

func show_pi_policy() -> void:
	clear_tile_directions()
	policy_to_tiles(pi_policy)

func policy_button() -> void:
	extras.clear()
	state = GameState.Policy
	policy_to_tiles(sm_policy)
	$PolicyButtons/Buttons/CreatPolicy.visible = false

func apply_MC() -> void:
	clear_tile_directions()
	await $Timer.timeout
	var mc_policy = Policy.on_policy_mc(5000, 2000, 0.5)
	policy_to_tiles(mc_policy)

#endregion

#region Policy Testing Code

func begin_policy_test() -> void:
	state = GameState.TestPolicy

func policy_completion_check() -> bool:
	for x in tiles.size():
		for y in tiles[0].size():
			if Vector2i(x, y) == end:
				continue
			if not tiles[x][y].has_policy():
				return false
	return true

func start_test_policy() -> void:
	score = 0
	clear_tile_directions()
	policy_to_tiles(sm_policy)
	if policy_completion_check():
		extras.modulate = Color(1, 1, 1, 0.8)
		var episode = Policy.sample_episode(sm_policy, 50)
		play_episode(episode)
	else:
		clear_tile_directions()
		currentUI = no_policyUI.instantiate()
		add_child(currentUI)
		$NoPolicy/PanelContainer/VBoxContainer/Button3.pressed.connect(policy_button)

func play_episode(episode: Array[Array]) -> void:
	restart()
	for step in episode:
		player = Policy.pos_to_vector(step[0])
		if player != player_start_pos:
			update_score()
		await $Timer.timeout
	player = Policy.pos_to_vector(int(Policy.step(Policy.vector_to_pos(player), episode.back()[1]).x))
	update_score()
	await $Timer.timeout
	state = GameState.OverTestPol


func start_OTP() -> void:
	currentUI = overPolicyTestUI.instantiate()
	add_child(currentUI)
	$GameOver/PanelContainer/VBoxContainer/Button.pressed.connect(free)
	$GameOver/PanelContainer/VBoxContainer/Button2.pressed.connect(begin_policy_test)
	$GameOver/PanelContainer/VBoxContainer/Button3.pressed.connect(policy_button)
	if score > highscore:
		highscore = score
	$GameOver/PanelContainer/VBoxContainer/High.text = "Current Highscore: " + str(highscore)
	$GameOver/PanelContainer/VBoxContainer/Score.text = str(score)

#region Miscellaneous Code

func _unhandled_input(event: InputEvent) -> void:
	# Then we check if we can move the player again, by checking the the input event is a button being presses
	var check_input: bool = event.is_pressed() 
	# This is done by first checking if the event is the same as the event of the last frame
	if event.is_echo():
		# If that is true then we check if the timer has stopped 
		check_input = check_input and $Timer.is_stopped()

	# If the player can't move then we return since there is no other input we need to check
	if not check_input:
		return
	match state:
		GameState.Playing:
			# We set the direction to be this mess of a value
			var direction: Vector2i = Vector2i.ZERO + (Vector2i.RIGHT * int(event.is_action("ui_right"))) + (Vector2i.UP * int(event.is_action("ui_up"))) + \
									(Vector2i.LEFT * int(event.is_action("ui_left"))) + (Vector2i.DOWN * int(event.is_action("ui_down")))
			if direction == Vector2i.ZERO:
				return
			player += direction
			update_score()
			$Timer.start()
		GameState.Policy:
			if $PolicyButtons/Buttons/PolicyBoxes.visible:
				if event.is_action_pressed("ui_accept"):
					begin_policy_test()
			else:
				if event.is_action_pressed("click"):
					current_tile = get_tile(Navigation.world_to_grid(event.position))
					current_sprite.visible = true
					current_sprite.position = current_tile.position
					$Timer.start()
					return
				elif event.is_action_pressed("ui_accept"):
					end_setting_policy()
					$Timer.start()
					return
				if current_tile:
					if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_down"):
						set_policy_dir(int(event.is_action_pressed("ui_right")) * 1 + int(event.is_action_pressed("ui_down")) * 2\
										+ int(event.is_action_pressed("ui_left")) * 3 as Directions.Dir)

func get_tile(tile: Vector2i) -> Tile:
	return tiles[tile.x][tile.y]

func delete_current_UI() -> void:
	if currentUI:
		currentUI.queue_free()
		currentUI = null

#endregion
