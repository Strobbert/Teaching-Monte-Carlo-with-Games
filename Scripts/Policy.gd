class_name Polciy
extends Node

var grid: Array[int]
var region: Rect2i
var size
var start_pos: Vector2i

func create_grid(_region: Rect2i, player, end: Vector2i, good: Array[Vector2i], bad: Array[Vector2i]) -> void:
	region = _region
	grid = []
	size = region.get_area()
	grid.resize(size)
	grid.fill(Globals.step_value)
	start_pos = player
	grid[vector_to_pos(end)] = Globals.end_value
	for cell in good:
		grid[vector_to_pos(cell)] = Globals.yellow_value
	for cell in bad:
		grid[vector_to_pos(cell)] = Globals.red_value
	# In case you wanna print the grid:
	# print_dubble_array(resize_array(grid))

func vector_to_pos(pos: Vector2i) -> int:
	return pos.y * region.size.x + pos.x

func pos_to_vector(pos: int) -> Vector2i:
	return Vector2i(pos % region.size.x, int(float(pos) / region.size.x))

func print_dubble_array(a: Array[Array]) -> void:
	for x in a:
		print(x)

func random_policy() -> Dictionary:
	var rand_pol = {}
	for x in range(size):
		rand_pol[x] = [0.25, 0.25, 0.25, 0.25]
	return rand_pol

func resize_array(a: Array) -> Array[Array]:
	var array_size = region.size
	if a.size() != array_size.x * array_size.y:
		return [[]]
	var to_return: Array[Array] = []
	for x in range(array_size.y):
		to_return.append(a.slice(0, array_size.x))
		a = a.slice(array_size.x, a.size())
	return to_return

func step(state: int, action: Directions.Dir, step_grid: Array[int] = grid, update_grid: bool = false) -> Vector2:
	var new_state = vector_to_pos(Navigation.clamp_to_grid(pos_to_vector(state) + Directions.to_vector(action)))
	var value = step_grid[new_state]
	if update_grid and (value != Globals.step_value and value != Globals.end_value):
		step_grid[new_state] = Globals.step_value
	if new_state == state and value != Globals.step_value:
		value = Globals.step_value
	return Vector2(new_state, value)

#############################
#        Policy Iter        #
#############################

func policy_evaluation(policy: Dictionary, threshold: float = 0.001, discount_factor:float = 0.1) -> Array[float]:
	var values: Array[float] = []
	values.resize(size)
	values.fill(0)
	while true:
		var delta = 0
		var temp_values: Array[float] = []
		temp_values.resize(size)
		temp_values.fill(0)
		for s in range(size):
			if grid[s] == Globals.end_value:
				continue
			var v_s: float = 0.0
			var prob = policy[s]
			for a in Directions.Dir.values():
				a = a as Directions.Dir
				var prime_reward = step(s, a)
				v_s += prob[a] * (prime_reward.y + discount_factor * values[prime_reward.x])
			delta = max(delta, abs(values[s]-v_s))
			temp_values[s] = v_s
		values = temp_values
		if delta < threshold:
			return values

	return []

func policy_improvement(values: Array[float], discount_factor: float = 0.1) -> Dictionary:
	var new_policy = {}
	for s in range(size):
		var new_best: Array[float] = []
		var best_val = -INF
		var new_prob: Array[float] = [0.0, 0.0, 0.0, 0.0]
		for a in Directions.Dir.values():
			a = a as Directions.Dir
			var p_r: Vector2 = step(s, a)
			var new_val = p_r.y + discount_factor*values[p_r.x]
			if new_val == best_val:
				new_best.append(a)
			elif new_val > best_val:
				new_best = [a]
				best_val = new_val
			
		for a in new_best:
			new_prob[a] = float(1.0 / new_best.size())
		new_policy[s] = new_prob
	return new_policy

func policy_iteration(policy, threshold = 0.001, discount_factor = 0.1) -> Dictionary:
	while true:
		var values = policy_evaluation(policy, threshold, discount_factor)
		var new_policy = policy_improvement(values, discount_factor)
		if policy == new_policy:
			break
		policy = new_policy
	return policy

#############################
#        Monte-Carlo        #
#############################

## Creates a random episode, which is one full run based on the given policy
func sample_episode(policy: Dictionary, max_depth: int) -> Array[Array]:
	var random = RandomNumberGenerator.new()
	var grid_copy: Array[int] = grid.duplicate(true)
	var player: int = vector_to_pos(start_pos)
	var to_return: Array[Array] = []
	var steps = 0
	while steps < max_depth:
		var random_action = Directions.Dir.values()[random.rand_weighted(policy[player])] as Directions.Dir
		var p_r = step(player, random_action, grid_copy, true)
		to_return.append([player, random_action, p_r.y])
		player = p_r.x
		if p_r.y == Globals.end_value:
			break
		steps += 1
	return to_return

## creates a policy based on Monte Carlo
func on_policy_mc(max_depth: int, MAX_EPISODES = 1000, discount_factor: float = 1.0) -> Dictionary:
	var q:Dictionary = {}
	var returns: Dictionary = {}
	for s in size:
		for a in Directions.Dir.values():
			a = a as Directions.Dir
			q[[s, a]] = 0.0
			returns[[s, a]] = []

	var policy: Dictionary = random_policy()
	for i in range(MAX_EPISODES):
		var epsilon: float = max(1.0/(i+1), 0.05)
		var visited: Array[Array] = []
		var episode: Array[Array] = sample_episode(policy, max_depth)
		episode.reverse()
		var g: float = 0.0
		for t in episode:
			var s_t : int = t[0]
			var a_t: Directions.Dir = t[1]
			var r_t1: float = t[2]
			g = discount_factor * g + r_t1
			if [s_t, a_t] in visited:
				continue
			visited.append([s_t, a_t])
			returns[[s_t, a_t]].append(g)
			q[[s_t, a_t]] = returns[[s_t, a_t]].reduce(
				func(mean, num):
					mean += num / returns[[s_t, a_t]].size()
					return mean
			, 0)
			var a_star: Array[float] = argmax(q, s_t)
			var new_probs: Array[float] = []
			if i < MAX_EPISODES - 1: 
				for a in Directions.Dir.values():
					new_probs.append(float(a_star[a] * (1.0 - epsilon) + epsilon / Directions.Dir.values().size()))
			else:
				new_probs = a_star.duplicate(true)
			policy[s_t] = new_probs
	return policy 

## sets the policy for the state s, based on the values in Q
func argmax(q, s) -> Array[float]:
	var current_best: float = -INF
	var best: Array[Directions.Dir] = []
	var new_probs: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for a in Directions.Dir.values():
		a = a as Directions.Dir
		var q_s: float = q[[s, a]]
		if q_s > current_best:
			current_best = q_s
			best = [a]
		elif q_s == current_best:
			best.append(a)
	for a in best:
		new_probs[a] = 1.0/best.size()
	return new_probs
