# Atlas CRM — ERD e Modelo Conceitual do Banco

**Versão:** 0.1  
**Status:** Modelo conceitual inicial  
**Data:** Agosto de 2026

## 1. O que é o ERD?

ERD significa **Entity-Relationship Diagram** (Diagrama Entidade-Relacionamento).

É o mapa visual do banco de dados. Antes de criarmos as tabelas no PostgreSQL, usamos o ERD para representar:

- quais entidades existem;
- quais informações cada entidade guarda;
- como as entidades se relacionam;
- a cardinalidade dessas relações;
- quais informações pertencem a cada contexto do negócio.

No Atlas, o ERD representa o funcionamento real do processo comercial.

---

# 2. Princípios do modelo

1. **O banco representa o negócio, não a interface.**
2. **Pessoa é uma entidade persistente e pode assumir diferentes papéis.**
3. **Jornada representa um atendimento comercial específico.**
4. **Uma pessoa pode participar de várias jornadas ao longo do tempo.**
5. **Uma jornada pode envolver várias pessoas e vários cursos.**
6. **Interações registram o que aconteceu.**
7. **Atividades registram o que precisa ser feito.**
8. **Compromissos representam eventos agendados.**
9. **Diagnóstico concentra o conhecimento adquirido sobre os alunos durante a jornada.**
10. **O histórico não deve ser apagado para esconder o que aconteceu.**
11. **Dados estruturados devem existir quando tiverem valor operacional, de consulta ou filtragem.**
12. **A evolução estrutural do banco será feita por migrações.**

---

# 3. Visão geral do ERD

```text
                         ┌─────────────────┐
                         │     PESSOA      │
                         ├─────────────────┤
                         │ id PK           │
                         │ nome            │
                         │ telefone        │
                         │ email           │
                         │ cidade          │
                         │ created_at      │
                         │ updated_at      │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
             relacionamentos              participa de
                    │                           │
                    ▼                           ▼
             ┌──────────────┐          ┌─────────────────┐
             │ RELAÇÃO      │          │    JORNADA      │
             │ ENTRE PESSOAS│          ├─────────────────┤
             └──────────────┘          │ id PK           │
                                       │ opened_at       │
                                       │ closed_at       │
                                       │ etapa           │
                                       │ status          │
                                       │ alto_potencial  │
                                       │ buyer_journey   │
                                       │ investimento    │
                                       │ rec_triagem     │
                                       │ valor_ofertado  │
                                       │ responsavel_id  │
                                       └────────┬────────┘
                                                │
                         ┌──────────────────────┼─────────────────────┐
                         │                      │                     │
                        1:N                    1:N                   N:N
                         │                      │                     │
                         ▼                      ▼                     ▼
                  ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
                  │  INTERAÇÕES   │     │  ATIVIDADES   │     │    CURSOS     │
                  └───────────────┘     └───────────────┘     └───────┬───────┘
                                                                      │ 1:N
                                                                      ▼
                                                                 ┌───────────────┐
                                                                 │     NÍVEL     │
                                                                 └───────┬───────┘
                                                                         │ 1:N
                                                                         ▼
                                                                  ┌───────────────┐
                                                                  │     TURMA     │
                                                                  └───────┬───────┘
                                                                          │ 1:N
                                                                          ▼
                                                                 ┌────────────────┐
                                                                 │ HORÁRIO TURMA  │
                                                                 └────────────────┘

                         JORNADA
                            │
                            ├── 1:N → DIAGNÓSTICOS
                            │
                            └── 1:N → COMPROMISSOS
```

---

# 4. Pessoa

## Objetivo

`Pessoa` representa qualquer indivíduo conhecido pelo Atlas.

Uma pessoa pode ser:

- responsável por um ou mais alunos;
- aluno;
- responsável e aluno simultaneamente;
- participante de várias jornadas.

### Exemplo

Carlliane pode ser responsável por Manoela e Carolina e posteriormente tornar-se aluna. Não criamos uma segunda Carlliane: a mesma pessoa assume outro papel em outra jornada.

### Campos iniciais

```text
id
nome
telefone
email
cidade
created_at
updated_at
```

---

# 5. Relacionamento entre pessoas

Representa relações entre pessoas.

Exemplo:

```text
Carlliane
   ├── RESPONSÁVEL → Manoela
   └── RESPONSÁVEL → Carolina
```

### Campos conceituais

```text
pessoa_origem_id
pessoa_destino_id
tipo_relacionamento
```

---

# 6. Jornada

## Objetivo

Uma `Jornada` representa um atendimento comercial específico.

Uma jornada começa em determinado momento, pode durar dias ou semanas, possui interações, atividades e compromissos, permanece aberta enquanto houver sentido comercial e eventualmente é encerrada.

Uma pessoa pode ter várias jornadas em momentos diferentes.

### Campos conceituais

```text
id
opened_at
closed_at
etapa
status
alto_potencial
buyer_journey
investimento
recuperacao_triagem
valor_ofertado
responsavel_id
motivo_perda_id
created_at
updated_at
```

`buyer_journey`, `investimento` e `recuperacao_triagem` pertencem à jornada porque são informações relativas àquela oportunidade específica.

---

# 7. Pessoas participantes da Jornada

Uma jornada pode envolver várias pessoas e cada uma pode desempenhar um papel diferente.

Exemplo:

```text
Jornada #1

Carlliane → RESPONSÁVEL
Manoela   → ALUNA
Carolina  → ALUNA
```

Outra jornada:

```text
Jornada #2

Carlliane → ALUNA
```

Conceitualmente:

```text
JORNADA N:N PESSOA
```

por meio de:

```text
jornada_pessoas
---------------
jornada_id
pessoa_id
papel
```

---

# 8. Diagnóstico

## Objetivo

Registrar o conhecimento adquirido durante a triagem e o diagnóstico de cada aluno dentro de uma jornada.

### Informações estruturadas

Devem virar campos quando tiverem valor para consulta e filtragem.

Exemplos:

- escola;
- período em que estuda;
- outras informações recorrentes e úteis para filtros.

### Informações livres

Devem permanecer em texto longo quando forem ricas, variáveis e difíceis de padronizar.

Exemplos:

- interesses;
- aptidões;
- necessidades;
- objetivos;
- contexto relevante;
- observações do atendimento.

### Estrutura conceitual

```text
diagnosticos
------------
id
jornada_id
pessoa_id
escola
periodo_estudo
observacoes
created_at
updated_at
```

`pessoa_id` representa o aluno ao qual o diagnóstico se refere.

---

# 9. Cursos, níveis, turmas e horários

A estrutura educacional será:

```text
CURSO
  │
  └── NÍVEL
        │
        └── TURMA
              │
              └── HORÁRIOS
```

## Curso

Representa o catálogo de cursos oferecidos pela escola.

A lista é relativamente fixa, mas pode ser expandida.

## Nível

Representa um nível dentro de um curso.

## Turma

Representa uma oferta concreta de um determinado nível.

## Horário

Representa os dias e horários em que uma turma ocorre.

Uma turma pode ter vários horários.

Exemplo:

```text
Turma X
├── terça-feira — 16h
└── quinta-feira — 16h
```

---

# 10. Jornada e cursos

Uma jornada pode ter vários cursos de interesse.

```text
JORNADA N:N CURSO
```

por meio de:

```text
jornada_cursos
-------------
jornada_id
curso_id
```

Curso de interesse não significa matrícula. É apenas uma possibilidade identificada durante a jornada.

---

# 11. Interações

## Objetivo

Uma `Interação` é um registro contextual de um ou mais acontecimentos relevantes durante uma jornada.

Não existe uma regra de “uma conversa = uma interação”.

Uma interação pode ser simples:

> “Nova tentativa de contato realizada. Lead não respondeu.”

Ou muito rica:

> “Ligação telefônica de 40 minutos na qual foram realizadas triagem, diagnóstico e oferta.”

Uma única interação pode gerar múltiplas consequências:

- alteração da etapa;
- atualização de informações;
- criação de atividades;
- criação ou atualização de compromissos;
- inclusão de cursos de interesse;
- geração de resumo para o closer.

### Campos conceituais

```text
id
jornada_id
atividade_id
tipo
subtipo
descricao
origem
data_hora
responsavel_id
created_at
```

`atividade_id` é opcional, pois uma interação também pode acontecer espontaneamente, sem atividade prévia.

---

# 12. Atividades

## Objetivo

Uma `Atividade` representa uma ação que precisa ser realizada dentro de uma jornada.

### Tipos inicialmente definidos

```text
TC — Tentativa de Contato
CF — Confirmação de Reunião de Fit
CM — Confirmação de Reunião de Matrícula
FD — Follow-up Diário
FS — Follow-up Semanal
FM — Follow-up Mensal
```

A sequência é um atributo, não um tipo separado.

Por exemplo:

```text
tipo = FD
sequencia = 3
```

representa `FD3`.

### Estrutura conceitual

```text
id
jornada_id
tipo
sequencia
descricao
data_prevista
status
responsavel_id
atividade_anterior_id
created_at
completed_at
```

Uma atividade relevante concluída deve gerar um registro histórico, normalmente uma interação.

---

# 13. Compromissos

## Objetivo

Um `Compromisso` representa um evento agendado dentro de uma jornada.

Uma jornada pode ter vários compromissos.

### Tipos inicialmente definidos

```text
AULA_EXPERIMENTAL
REUNIAO_FIT
REUNIAO_MATRICULA
```

### Reunião de Fit

É uma reunião relativamente inicial na jornada, destinada a aprofundar o entendimento e apresentar a proposta da escola.

### Reunião de Matrícula

É uma reunião mais avançada, voltada a resolver objeções e alinhar os últimos pontos necessários para concretizar a matrícula.

A jornada não precisa seguir uma sequência rígida entre esses compromissos.

### Estrutura conceitual

```text
id
jornada_id
tipo
inicio
fim
status
responsavel_id
observacao
calendar_event_id
created_at
updated_at
```

O Google Calendar é uma integração externa. O Atlas permanece como fonte do contexto comercial do compromisso.

---

# 14. Interação, Atividade e Compromisso

Esses conceitos são diferentes:

**Interação — o que aconteceu**

> “Falei com a mãe e ela confirmou a aula.”

**Atividade — o que precisa ser feito**

> “Confirmar aula experimental.”

**Compromisso — o que foi efetivamente agendado**

> “Aula experimental — sexta-feira, 16h.”

Um fluxo pode ser:

```text
ATIVIDADE
“Confirmar aula”
      ↓
INTERAÇÃO
“Confirmei com a mãe.”
      ↓
COMPROMISSO
“Aula experimental — sexta às 16h”
```

---

# 15. Jornada como centro da história comercial

A estrutura pode ser resumida assim:

```text
                         PESSOA
                           │
                  relacionamentos
                           │
                           ▼
                         PESSOA

                           │
                         participa
                           ▼

                        JORNADA
                           │
        ┌──────────────────┼───────────────────┐
        │                  │                   │
        ▼                  ▼                   ▼
   DIAGNÓSTICOS        INTERAÇÕES          ATIVIDADES
        │                                      │
        │                                      │
        └──────────────► HISTÓRICO ◄───────────┘

                        JORNADA
                           │
                           ▼
                     COMPROMISSOS
                           │
                 ┌─────────┼─────────┐
                 ▼         ▼         ▼
               AULA       FIT      MATRÍCULA

                        JORNADA
                           │
                           ▼
                    CURSOS DE INTERESSE
                           │
                           ▼
                         NÍVEL
                           │
                           ▼
                         TURMA
                           │
                           ▼
                        HORÁRIOS
```

---

# 16. Exemplo: Carlliane

Uma pessoa:

```text
Carlliane
```

possui relações com:

```text
Manoela
Carolina
```

### Jornada 1

```text
Carlliane → RESPONSÁVEL
Manoela   → ALUNA
Carolina  → ALUNA
```

Durante essa jornada podem existir diagnósticos, cursos de interesse, interações, atividades, aulas experimentais e reuniões.

### Jornada 2

Posteriormente:

```text
Carlliane → ALUNA
```

Ela própria passa a ser o objeto da nova jornada como estudante.

O sistema não cria uma nova Carlliane.

---

# 17. Exemplo: Lidiana

A jornada pode começar com:

```text
Interesse inicial:
Xadrez
```

Durante o diagnóstico, podem surgir:

```text
Xadrez
Matemática
```

O diagnóstico registra:

- idade do aluno;
- escola;
- período de estudo;
- disponibilidade;
- aptidões;
- interesses;
- objetivos;
- observações relevantes.

A jornada pode possuir:

```text
Compromisso #1
Aula experimental
Hoje

Compromisso #2
Aula experimental
Sexta-feira
```

Uma interação pode registrar:

> “Conversei com Lidiana, realizei a triagem, identifiquei os horários disponíveis e agendei duas aulas experimentais.”

O Atlas poderá usar essa interação para atualizar o estado da jornada, criar atividades, gerar resumo para o closer e integrar os compromissos ao Google Calendar.

---

# 18. Decisões arquiteturais

## PostgreSQL

O Atlas utilizará PostgreSQL como banco principal.

A planilha atual serviu como referência do processo e não será o banco do Atlas.

## UUID

As entidades principais utilizarão UUID como identificadores.

## Timestamps

As entidades relevantes terão timestamps de criação e atualização.

## Histórico

Informações históricas importantes não devem ser apagadas simplesmente para manter o estado atual limpo.

## Migrações

Alterações futuras na estrutura do banco serão realizadas através de migrações.

## IA

A IA não deverá acessar o PostgreSQL de forma irrestrita.

Fluxo conceitual:

```text
Usuário
   ↓
IA / interpretação
   ↓
Intenção estruturada
   ↓
Regras de negócio
   ↓
Services do Atlas
   ↓
PostgreSQL / Google Calendar / outras integrações
```

---

# 19. Evolução do modelo

Este documento representa o **Atlas v0.1**.

O modelo não precisa prever todas as necessidades futuras.

Novos casos reais poderão justificar:

- novos tipos de compromisso;
- novos campos de diagnóstico;
- novos papéis de pessoas;
- novos tipos de atividade;
- novas regras comerciais;
- novas integrações.

A regra é:

> **Não adicionar complexidade porque talvez um dia seja necessária. Adicionar estrutura quando uma necessidade real justificar.**

O ERD é a planta baixa do Atlas. Se o projeto crescer, avaliamos a mudança conscientemente e atualizamos a planta antes de construir sobre ela.

---

# 20. Próximo passo técnico

Com o modelo conceitual definido:

```text
ERD / Modelo conceitual
          ↓
Especificação das tabelas
          ↓
schema.sql
          ↓
Banco PostgreSQL
          ↓
Seeds iniciais
          ↓
Migrações
          ↓
Backend Flask
          ↓
Interface do Atlas
          ↓
Integração com IA
          ↓
Integrações externas
```

O próximo artefato será a **especificação relacional detalhada**, seguida pela primeira versão do `schema.sql`.
