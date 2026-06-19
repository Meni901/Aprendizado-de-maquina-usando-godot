extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var ai_controller: AIController3D = $AIController3D

func _physics_process(delta: float) -> void:
	
	velocity.x = ai_controller.move.x
	velocity.z = ai_controller.move.y
	print(ai_controller.move)

	move_and_slide()


func _on_target_body_entered(body: Node3D) -> void:
	position = Vector3(0, 0.574, 3.094)
	ai_controller.reward += 1.0
	


func _on_wall_body_entered(body: Node3D) -> void:
	position = Vector3(0, 0.574, 3.094)
	ai_controller.reward -= 1.0
	ai_controller.reset()
	
