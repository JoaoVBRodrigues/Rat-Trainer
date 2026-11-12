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