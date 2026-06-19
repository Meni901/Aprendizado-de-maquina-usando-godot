extends AIController3D

var move = Vector2.ZERO

@onready var cube: CharacterBody3D = $".."
@onready var target: Area3D = $"../../Target"


func get_obs() -> Dictionary:
	var obs := [
		cube.position.x,
		cube.position.z,
		target.position.x,
		target.position.z,
	]
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"move" : {
			"size": 2,
			"action_type": "continuous"
		},
	}
	
func set_action(action) -> void:	
	move.x = action["move"][0]
	move.y = action["move"][1]
# -----------------------------------------------------------------------------#

#-- Methods that can be overridden if needed --#

#func get_obs_space() -> Dictionary:
# May need overriding if the obs space is complex
#	var obs = get_obs()
#	return {
#		"obs": {
#			"size": [len(obs["obs"])],
#			"space": "box"
#		},
#	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
