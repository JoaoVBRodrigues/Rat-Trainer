# Rat Trainer - Project Setup

## Project: Rat Trainer

### Premissa
Simulador de agendamento mensal (3 períodos/mês) inspirado em Princess Maker 2, cenário cyberpunk, protagonista garota-rato criada por um(a) guardião(ã).

### Fonte de Verdade de Design
- `design/reference/sumario-executivo.pdf`
- Documentos aprovados em `design/`

**Regra de conflito:** O documento mais recente em `design/` prevalece.

### Engine
- **Engine:** Godot 4.5
- **Linguagem:** GDScript tipado (static typing sempre)
- **Dados:** JSON em `assets/data/`

### Godot no Windows / Claude Code Bash
- O projeto canônico é `C:\Users\João\Documents\rat-trainer\project.godot` (raiz do repositório); não abra `src/project.godot.legacy`.
- Editor Godot 4.5.1: `C:\Users\João\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe`
- CLI headless: `C:\Users\João\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe`
- O comando `godot` não está no PATH do Bash. No Claude Code, use `bash tools/godot.sh ...`; não misture comandos PowerShell dentro do Bash nem procure o executável novamente.
- Para outra instalação, defina `GODOT_CONSOLE_EXE` com o caminho Git Bash do executável console antes de chamar o wrapper.
- Validação de importação: `bash tools/godot.sh --headless --path . --editor --quit`
- Testes: `bash tools/godot.sh --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit`
- Simulação: `bash tools/godot.sh --headless --path . --script res://src/tools/simulation_cli.gd -- 12345`
- Só declare sucesso após conferir o exit code e os erros do comando; não esconda falhas com `| head`.

### Resolução Base
- **4:3 (1024x768)**
- Estética inspirada no layout de UI de Princess Maker 2:
  - Painel de status à direita
  - Calendário no canto superior esquerdo
  - Personagem em primeiro plano sobre cenário

### Regras de Processo
- **NUNCA** fazer commit/push sem permissão
- Ao final de cada tarefa entregar:
  1. Resumo do que mudou
  2. Checklist do que precisa revisão
  3. Mensagem de commit em Conventional Commits (em inglês)
- Uma tarefa por vez
- Não adicionar features fora do escopo MVP

### Regras de Conteúdo
- Protagonista: criança/adolescente (12–18 anos)
- **Proibido:**
  - Qualquer conteúdo sexual ou sexualizado
  - Roupas reveladoras
  - Romance envolvendo a protagonista menor de idade
  - Relacionamentos com o guardião
- Finais de relacionamento: somente platônicos/familiares/profissionais
- Todos os assets e textos devem ser adequados para a faixa etária

### Regra de Commits
- **Proibido** nas mensagens de commit: "push", "reset --hard", "clean -f"
- (As regras de permissão do template bloqueiam comandos git com esses padrões)