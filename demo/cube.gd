extends CharacterBody3D

const SPEED = 5.0

@onready var ai_controller: AIController3D = $AIController3D
@onready var particula: GPUParticles3D = $"../Target/GPUParticles3D"

func _physics_process(delta: float) -> void:
	velocity.x = ai_controller.move.x * SPEED
	velocity.z = ai_controller.move.y * SPEED
	move_and_slide()

func _on_target_body_entered(body: Node3D) -> void:
	position = Vector3(0, 0.574, 3.094)
	particula.emitting = true
	print("🎯 ALCANÇOU O ALVO! Resetando...")

func _on_wall_body_entered(body: Node3D) -> void:
	position = Vector3(0, 0.574, 3.094)
	print("🧱 BATEU NA PAREDE! Penalidade aplicada.")
	ai_controller.near_wall_count += 5  # Penalidade extra
