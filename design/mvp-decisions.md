# MVP Decisions - Rat Trainer

## Document Status
- **Created:** 2026-11-12
- **Confidence:** High (based on Princess Maker 2 analysis)
- **Source:** Sumário Executivo (alta confiança), inspiração PM2 (moderada)

---

## Item 1: Faixa etária do jogo
- **Resposta:** Opção B - 12–18 anos
- **Motivo:** Equilíbrio entre fidelidade original e escopo maduro
- **Evidência:** Sumário original (10–18), MVP proposto (12–20 ou 6–8)

## Item 2: Valor da mesada/pensão anual
- **Resposta:** Opção C - 200 créditos/ano
- **Motivo:** Equilíbrio entre escopo e gestão de recursos
- **Evidência:** 500 ouro/mês (original), 100 créditos (MVP baixo)

## Item 3: Sistema de estresse
- **Resposta:** Opção B - Atributo independente (Stress)
- **Motivo:** Simples de implementar, visualização clara
- **Regra:** Se Stress > Constituição = doença
- **Evidência:** Stress derivado (Sumário), atributo separado (pseudocódigo)

## Item 4: Substituição Moral/Fé
- **Resposta:** Opção A - Ética (ETH) substitui Moral+Fé
- **Motivo:** Atributo único, fácil de entender, adequado ao cyberpunk
- **Faixa:** 0–100
- **Evidência:** Sumário: Moral+Fé separados; MVP: não definido

## Item 5: Reputações para finais
- **Resposta:** Opção A - 3 reputações principais
  - Fighter Rep (combate)
  - Social Rep (carisma/etiqueta)
  - Hacker Rep (inteligência técnica)
- **Motivo:** Simplicidade para MVP, cobre necessidades
- **Evidência:** CombatRep, CharismaRep, CriminalRep (não definidas)

## Item 6: Corrigir "Líder Corporativa"
- **Resposta:** Opção A - Hacker Rep == max && ETH < 30
- **Motivo:** Usa atributos definidos para MVP
- **Pseudocódigo corrigido:**
  ```
  if (HackerRep == max && ETH < 30) then final = "Líder Corporativa"
  ```

## Item 7: Ordem de avaliação dos finais
- **Resposta:** Opção B - Progressão lógica
  1. Finais de carreira (combate, técnica, social)
  2. Finais sociais (casamentos, influência)
  3. Finais criminosos/sombrios
- **Motivo:** Ordem lógica de desenvolvimento
- **Evidência:** Pseudocódigo if/else (condições conflitantes)

## Item 8: Definição "3 turnos/mês"
- **MVP:** 36 atividades por ano (3 por mês)
- **Melhoria pós-MVP:** 108 atividades (3 turnos x 9 períodos)
- **Motivo:** MVP focado em núcleo, expansão possível

---

## Atributos da Persona (MVP)

| Atributo | Faixa | Valor Inicial | Descrição |
|----------|-------|---------------|-----------|
| Força (STR) | 0–100 | 10–20 | Força física, ataque |
| Inteligência (INT) | 0–100 | 10–20 | Habilidade técnica, hacking |
| Carisma (CHA) | 0–100 | 10–20 | Influência social |
| Refinamento (EGG) | 0–100 | 10–20 | Elegância, etiqueta |
| Energia (STA) | 0–100 | 15–25 | Saúde/fadiga |
| Ética (ETH) | 0–100 | 50–70 | Moralidade, evita delinquência |
| **Stress** | 0–100 | 0 | Fadiga acumulada |

---

## Recursos do MVP

| Categoria | Quantidade | Escopo |
|-----------|------------|--------|
| Atividades | 4 (estudo, trabalho, missão, lazer) | Núcleo |
| Cursos | 3 | Estudo básico |
| Empregos | 3 | Trabalho doméstico |
| Missões | 3 | Mini-aventuras |
| Lazer | 2 | Descanso/recuperação |
| Eventos | 12 | Fixos + aleatórios |
| Lojas | 3 | Armas, roupas, itens |
| Finais | 15–20 | Matriz de condições |

---

## Fora do Escopo do MVP

- Dieta/peso/medidas
- Vestuário customizável
- Diálogos longos
- Minigames
- Combate manual
- Multi-idioma
- Sistema de peso dinâmico
- Roupas com bônus complexos

---

## Premissa de Mundo (3 parágrafos)

**Parágrafo 1:** Em 2087, a cidade de Neo-Arcadia flutua entre o controle corporativo e os subúrbios hacker. A protagonista, uma jovem garota-rato chamada **Nyx**, vive sob a tutela do **Pai-robô ORAC**, um sistema de IA responsável por sua educação e sobrevivência após a morte de seus genitores humanos.

**Parágrafo 2:** Nyx deve gerenciar seu tempo, habilidades e recursos para se preparar para os desafios que a cidade oferece. Entre as opções de atividades: hacking em redes corporativas, estudos de biotecnologia, missões de resgate de dados, e interações sociais com a comunidade underground. Cada escolha molda sua trajetória e determina quais habilidades se desenvolverão.

**Parágrafo 3:** O futuro de Nyx depende de suas decisões: pode se tornar uma Hacker Elite, a Heroína das Ruas, ou talvez a Rainha Corporativa. Ou pode cair na escuridão, tornando-se uma figura do submundo. Sua jornada dura 6 anos de jogo (idade 12 a 18), com 36 decisões estratégicas que definirão seu destino.

---

## Nome da Protagonista

**Nyx Volt** - garota-rato, hacker, protagonista

---

## Regras de Conteúdo

| Regra | Status |
|-------|--------|
| Protagonista menor de idade (12–18) | ✅ |
| Sem conteúdo sexual/sexualizado | ✅ |
| Sem roupa reveladora | ✅ |
| Sem romance com protagonista menor | ✅ |
| Finais só profissionais/familiares/sociais | ✅ |
| Finais "dark" não são explícitos | ✅ |
| Finais sombrios = crime, caos, isolamento | ✅ |

---

## Matriz de Finais (MVP - 15)

1. **Heroína de Armas** - STR≥150, FighterRep=max
2. **Maga Suprema** - INT≥150, HackerRep=max  
3. **Artista Estelar** - EGG≥150, SocialRep=max
4. **Rainha Corporativa** - HackerRep=max, ETH<30
5. **Empresária de Gangue** - INT≥120, ETH<40
6. **Rainha das Ruas** - ETH≤20, (flags: criminal_record)
7. **Escritora Fama** - INT≥140, sem combate
8. **Zen do Deserto** - ETH≥180, INT<50
9. **Cidadã Comum** - equilíbrio geral
10. **Mestre dos Cyborgs** - INT≥160, HackerRep=max, EGG≥80
11. **Líder da Favela** - SocialRep=max, (flags: community_help)
12. **Técnica da Cidade** - INT≥170, missões_hack_concluídas≥5
13. **Guardiã da Rede** - ETH≥150, HackerRep=max
14. **Alquimista Cibernético** - INT≥130, (flags: tech_experiments)
15. **Anônima** - (flags: disappear_from_society)

---

## Fontes e Confiança

| Fonte | Confiança | Uso |
|-------|-----------|-----|
| Princess Maker 2 (Wikipedia) | Alta | Estrutura básica de calendário |
| Guia Fís Detalhado | Alta | Fórmulas de atributos |
| Análises CRPGAddict | Alta | Finais (74 totais) |
| Design próprio | Moderada | Adaptação cyberpunk |
| Inspiração PM2 | Alta | Sistema de agendamento |

---

## Próximos Passos

1. Definir sistema de eventos (12 finais) ✅
2. Criar templates de salas de estudo/trabalho
3. Configurar sistema de salário mensal
4. Implementar sistema de doença (Stress > STA)
5. Criar matriz de condições de finais