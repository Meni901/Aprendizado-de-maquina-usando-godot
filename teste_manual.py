from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
import time
import numpy as np

# Cria o ambiente (sem env_path = usa o editor do Godot)
env = StableBaselinesGodotEnv(
    env_path=None,
    show_window=True,
    seed=42,
    n_parallel=1,
    speedup=1,
    action_repeat=1,
)

print("Ambiente criado! Aguardando conexão...")
obs = env.reset()
print(f"Observação inicial: {obs}")

# Testa ações manuais
for i in range(50):
    # AÇÃO CORRETA: array 2D com shape (1, 2)
    action = np.array([[np.random.uniform(-1, 1), np.random.uniform(-1, 1)]])
    
    print(f"Passo {i}: Enviando ação {action}")
    obs, reward, done, info = env.step(action)
    
    print(f"  Reward: {reward}, Done: {done}")
    
    if done:
        print("Episódio terminou! Resetando...")
        obs = env.reset()
    
    time.sleep(0.1)

env.close()
print("Teste finalizado!")