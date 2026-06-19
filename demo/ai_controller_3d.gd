extends AIController3D

var move = Vector2.ZERO
var step_count = 0
var start_position = Vector3.ZERO
var last_distance = 0.0
var best_distance = 0.0
var episode_steps = 0
var max_steps_per_episode = 500  # Limite de passos por episódio
var near_wall_count = 0

@onready var cube: CharacterBody3D = $".."
@onready var target: Area3D = $"../../Target"

func _ready() -> void:
	print("=== AI CONTROLLER INICIADO ===")
	start_position = cube.global_transform.origin
	last_distance = start_position.distance_to(target.global_transform.origin)
	best_distance = last_distance
	print("Distância inicial do alvo:", last_distance)

func get_obs() -> Dictionary:
	var cube_pos = cube.global_transform.origin
	var target_pos = target.global_transform.origin
	
	var obs := [
		cube_pos.x,
		cube_pos.z,
		target_pos.x,
		target_pos.z,
		cube_pos.distance_to(target_pos),
		cube.velocity.length(),
	]
	return {"obs": obs}

func get_reward() -> float:
	var cube_pos = cube.global_transform.origin
	var target_pos = target.global_transform.origin
	var current_distance = cube_pos.distance_to(target_pos)
	
	# ========== RECOMPENSA POR PROGRESSO ==========
	var progress_reward = 0.0
	if current_distance < last_distance:
		# Quanto mais perto, maior a recompensa (multiplicador maior)
		var improvement = (last_distance - current_distance)
		progress_reward = improvement * 10.0  # Aumentado de 2 para 10
		
		# Bônus extra por chegar MUITO perto
		if current_distance < 1.0:
			progress_reward += 5.0
	
	# ========== PENALIDADE POR FICAR PARADO ==========
	var speed_penalty = 0.0
	if cube.velocity.length() < 0.1 and step_count > 10:
		speed_penalty = -0.5  # Penalidade por ficar parado
	
	# ========== RECOMPENSA POR VELOCIDADE ==========
	var speed_bonus = cube.velocity.length() * 0.2
	
	# ========== PENALIDADE POR TEMPO (mais forte) ==========
	var time_penalty = step_count * 0.02  # Aumentado de 0.01 para 0.02
	
	# ========== RECOMPENSA POR CHEGAR AO ALVO ==========
	var target_reward = 0.0
	if current_distance < 0.3:
		target_reward = 50.0  # Recompensa GRANDE por chegar ao alvo!
		print("🎯 ALVO ALCANÇADO! +50 de bônus!")
	
	# ========== PENALIDADE POR BATER NA PAREDE (agora é BEM pior!) ==========
	var wall_penalty = 0.0
	if near_wall_count > 0:
		wall_penalty = -5.0 * near_wall_count  # Penalidade multiplicada!
		near_wall_count = 0  # Reseta o contador
	
	# ========== RECOMPENSA FINAL ==========
	reward = progress_reward + speed_bonus - time_penalty - speed_penalty + target_reward + wall_penalty
	
	# Limita a recompensa
	reward = clamp(reward, -20.0, 100.0)
	
	# Atualiza a última distância
	last_distance = current_distance
	
	# Atualiza melhor distância
	if current_distance < best_distance:
		best_distance = current_distance
	
	# Mostra progresso a cada 100 passos
	if step_count % 100 == 0:
		print("Passo", step_count, "| Dist:", "%.2f" % current_distance, 
			  "| Best:", "%.2f" % best_distance, 
			  "| Reward:", "%.2f" % reward)
	
	# ========== LIMITE DE PASSOS POR EPISÓDIO ==========
	episode_steps += 1
	if episode_steps > max_steps_per_episode:
		# Se demorou muito, penaliza e reseta
		reward -= 10.0
		print("⏰ TEMPO ESGOTADO! -10 de penalidade")
		reset()
	
	return reward

func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 2,
			"action_type": "continuous"
		}
	}

func set_action(action) -> void:
	step_count += 1
	
	if action is Dictionary and action.has("move"):
		var arr = action["move"]
		if arr.size() >= 2:
			move.x = float(arr[0])
			move.y = float(arr[1])
			
			# Verifica se está perto da parede (para penalizar)
			var cube_pos = cube.global_transform.origin
			if abs(cube_pos.x) > 4.0 or abs(cube_pos.z) > 4.0:
				near_wall_count += 1

func reset() -> void:
	print("=== RESETANDO EPISÓDIO ===")
	print("Passos:", step_count, "| Melhor distância:", "%.2f" % best_distance)
	
	cube.global_transform.origin = start_position
	cube.velocity = Vector3.ZERO
	move = Vector2.ZERO
	reward = 0.0
	step_count = 0
	episode_steps = 0
	last_distance = start_position.distance_to(target.global_transform.origin)
	best_distance = last_distance
	near_wall_count = 0
