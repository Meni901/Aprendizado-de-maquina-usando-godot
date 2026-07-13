================================================================================
GUIA COMPLETO: CONFIGURANDO AMBIENTE VIRTUAL RL PARA GODOT RL AGENTS
================================================================================

Este guia explica como configurar um ambiente virtual Python para treinar
agentes de Reinforcement Learning com Godot RL Agents, onde o ambiente demonstra
um agente de Reinforcement Learning aprendendo a navegar até um alvo em um 
espaço 3D simples usando o Godot RL Agents. A cena é composta por um Cube 
(o agente, controlado pelo nó AIController3D do plugin), um Floor (a plataforma
onde o agente se movimenta) e um Target (o objetivo a ser alcançado). A cada 
episódio de treinamento, o agente parte de uma posição inicial e recebe como 
observação sua posição e a distância relativa até o alvo. Com base nessa
observação, o modelo treinado com PPO (via Stable Baselines3) decide uma ação 
contínua de movimento, aplicada ao cubo a cada passo de física. O agente recebe 
recompensas negativas a cada passo, incentivando eficiência, e uma recompensa 
positiva ao tocar o alvo, encerrando o episódio com sucesso. Repetindo esse 
processo por milhares de episódios, a rede neural ajusta seus pesos para 
maximizar a recompensa acumulada, fazendo o cubo aprender sozinho, por tentativa
e erro, a se deslocar até o Target de forma consistente, sem que o comportamento
de navegação tenha sido programado manualmente.

================================================================================
PRÉ-REQUISITOS
================================================================================

- Python 3.8 ou superior instalado
- Godot 4.x instalado
- Plugin Godot RL Agents instalado no projetoNo começo, as ações são praticamente aleatórias (o cubo anda sem rumo). Mas como o PPO ajusta os pesos da rede neural pra maximizar a recompensa acumulada, ao longo de muitos episódios o cubo começa a associar "andar na direção do alvo" com recompensa maior, até convergir num comportamento consistente de navegação — sem que ninguém tenha programado explicitamente "vá até lá", como aconteceria com uma FSM tradicional.

Isso bate exatamente com o que vimos no artigo original: é praticamente o mesmo conceito do ambiente de referência Ball Chase (agente 2D navegando até um alvo), só que aqui adaptado pra 3D com um cubo simples.

Se quiser, posso te ajudar a olhar o conteúdo do cube.gd, ai_controller_3d.gd e target.gd pra confirmar exatamente como get_obs, get_reward e set_action foram implementados — aí a explicação fica 100% fiel ao seu código em vez de inferida pela estrutura da cena.

================================================================================
PASSO 1: CRIAR O AMBIENTE VIRTUAL
================================================================================

1. Abra o terminal/CMD/PowerShell

2. Navegue até a pasta do seu projeto:
   cd caminho/para/seu/projeto

3. Crie o ambiente virtual:
   python -m venv venv

   > Uma pasta "venv" será criada no diretório do projeto

================================================================================
PASSO 2: ATIVAR O AMBIENTE VIRTUAL
================================================================================

Windows (CMD):
   venv\Scripts\activate

Windows (PowerShell):
   .\venv\Scripts\Activate.ps1

Linux / Mac:
   source venv/bin/activate

CONFIRMAÇÃO: O terminal mostrará (venv) no início da linha:
   (venv) C:\seu_projeto>

================================================================================
PASSO 3: INSTALAR AS BIBLIOTECAS
================================================================================

Com o ambiente ativado, instale:

   pip install godot-rl-agents
   pip install stable-baselines3
   pip install numpy gymnasium tensorboard

Opcional (para exportar modelos para ONNX):
   pip install onnx onnxruntime

Para verificar a instalação:
   pip show godot-rl-agents
   pip list

================================================================================
PASSO 4: ESTRUTURA DO PROJETO
================================================================================

Seu projeto deve ter a seguinte estrutura:

   meu_projeto_rl/
   ├── venv/                  # Ambiente virtual (criado automaticamente)
   ├── godot_projeto/         # Seu projeto Godot
   │   ├── addons/
   │   │   └── godot_rl_agents/  # Plugin
   │   └── project.godot
   ├── scripts/               # Scripts Python
   │   ├── treino.py
   │   └── teste.py
   └── logs/                  # Logs do treinamento

================================================================================
PASSO 5: SCRIPT DE TESTE (teste.py)
================================================================================

from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
import time
import numpy as np

# Cria o ambiente
env = StableBaselinesGodotEnv(
    env_path=None,        # None = usa o editor do Godot
    show_window=True,     # Mostra a janela
    seed=42,
    n_parallel=1,
    speedup=1,
    action_repeat=1,
)

print("Aguardando conexão do Godot...")
obs = env.reset()
print("Conectado!", obs)

# Teste com ações aleatórias
for i in range(50):
    action = np.array([[np.random.uniform(-1, 1), np.random.uniform(-1, 1)]])
    obs, reward, done, info = env.step(action)
    print(f"Passo {i}: Reward={reward}, Done={done}")
    
    if done:
        obs = env.reset()
    
    time.sleep(0.1)

env.close()
print("Teste finalizado!")

================================================================================
PASSO 6: SCRIPT DE TREINAMENTO (treino.py)
================================================================================

from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env.vec_monitor import VecMonitor

# Cria o ambiente
env = StableBaselinesGodotEnv(
    env_path=None,
    show_window=True,
    seed=42,
    n_parallel=1,
    speedup=1,
    action_repeat=1,
)

env = VecMonitor(env)

# Cria o modelo PPO
model = PPO(
    "MultiInputPolicy",
    env,
    verbose=2,
    n_steps=64,
    batch_size=64,
    learning_rate=0.0003,
    tensorboard_log="logs/",
)

# Treina
print("Iniciando treinamento...")
model.learn(total_timesteps=100000)

# Salva o modelo
model.save("modelo_ppo")
print("Modelo salvo como 'modelo_ppo.zip'")

env.close()

================================================================================
PASSO 7: CONFIGURAÇÃO NO GODOT
================================================================================

1. Certifique-se de que o plugin está ativado:
   Projeto → Configurações do Projeto → Plugins
   ✓ Godot RL Agents (Ativado)

2. Adicione o nó de sincronização na cena raiz:
   Clique direito → Adicionar Nó Filho → GodotRLAgentsSync

3. No script do seu personagem, adicione o grupo AGENT:
   - Selecione o nó do personagem
   - Aba "Nó" (ao lado do Inspetor)
   - Grupos → Digite "AGENT" → Adicionar

4. Seu script deve implementar os métodos obrigatórios:
   extends CharacterBody3D (ou Node3D)

   func get_obs() -> Dictionary
   func get_reward() -> float
   func get_action_space() -> Dictionary
   func set_action(action) -> void
   func reset() -> void

================================================================================
PASSO 8: EXECUÇÃO
================================================================================

IMPORTANTE: A ORDEM DE EXECUÇÃO É FUNDAMENTAL!

1. Abra o terminal e ative o ambiente virtual:
   venv\Scripts\activate

2. Execute o script Python:
   python scripts/teste.py

3. Aguarde a mensagem:
   "waiting for remote GODOT connection on port 11008"

4. Abra o Godot e aperte PLAY

5. A conexão será estabelecida e o treinamento começará

================================================================================
COMANDOS ÚTEIS
================================================================================

Ativar ambiente virtual:
   venv\Scripts\activate      # Windows CMD
   .\venv\Scripts\Activate.ps1 # Windows PowerShell
   source venv/bin/activate   # Linux/Mac

Desativar ambiente:
   deactivate

Salvar dependências:
   pip freeze > requirements.txt

Instalar dependências salvas:
   pip install -r requirements.txt

Atualizar bibliotecas:
   pip install --upgrade godot-rl-agents stable-baselines3

Ver TensorBoard:
   tensorboard --logdir logs/
   Abrir http://localhost:6006 no navegador

================================================================================
RESOLUÇÃO DE PROBLEMAS
================================================================================

ERRO: "godot_rl" não encontrado
   pip uninstall godot-rl-agents
   pip install godot-rl-agents

ERRO: Conexão recusada no Godot
   - Execute o script Python PRIMEIRO
   - Só depois aperte Play no Godot
   - Verifique se o firewall não está bloqueando a porta 11008

ERRO: O personagem não se move
   - Verifique se o nó está no grupo AGENT
   - Coloque prints no set_action() para ver se está recebendo ações
   - Verifique se o _physics_process() está rodando

ERRO: "No module named 'numpy'"
   pip install numpy

ERRO: Permissão negada no PowerShell
   Execute como administrador:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

================================================================================
CHECKLIST PARA TREINAMENTO
================================================================================

[ ] Ambiente virtual criado e ativado
[ ] godot-rl-agents instalado
[ ] stable-baselines3 instalado
[ ] Plugin Godot RL Agents instalado no Godot
[ ] Nó GodotRLAgentsSync na cena raiz
[ ] Personagem no grupo AGENT
[ ] Script com get_obs(), get_reward(), get_action_space(), set_action(), reset()
[ ] Script Python executado PRIMEIRO
[ ] Godot executado DEPOIS
[ ] Conexão estabelecida
[ ] Ações sendo recebidas
[ ] Personagem se movendo

================================================================================
RECURSOS ADICIONAIS
================================================================================

Documentação Godot RL Agents:
   https://godot-rl.github.io/

Stable Baselines3:
   https://stable-baselines3.readthedocs.io/

Godot Engine:
   https://godotengine.org/

Comunidade Discord:
   https://discord.gg/godot-rl-agents

================================================================================
FIM DO GUIA
================================================================================