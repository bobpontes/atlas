# Atlas CRM — Database Design

**Versão:** 0.1  
**Status:** Especificação relacional inicial  
**Banco de dados:** PostgreSQL

---

## 1. Objetivo

Este documento especifica a estrutura relacional do banco de dados do Atlas CRM.

Ele traduz o modelo conceitual definido no ERD para uma especificação técnica, servindo como referência para a implementação do `schema.sql`.

O documento define:

- tabelas;
- colunas;
- tipos de dados;
- chaves primárias;
- chaves estrangeiras;
- restrições de integridade;
- índices;
- regras de exclusão e atualização;
- decisões de modelagem.

O modelo deve ser tratado como uma **planta técnica viva**: alterações futuras são permitidas quando casos reais do negócio justificarem uma mudança, mas devem ser avaliadas antes de alterar o banco.

---

# 2. Princípios do modelo

## 2.1 Pessoa é a entidade humana central

O Atlas não trata `Lead`, `Aluno` e `Responsável` como pessoas diferentes.

Existe uma única entidade `pessoas`.

Uma pessoa pode:

- ser responsável por outras pessoas;
- ser aluna;
- exercer os dois papéis;
- participar de várias jornadas.

## 2.2 Jornada representa um atendimento

Uma `jornada` representa um ciclo comercial específico.

A mesma pessoa pode iniciar diferentes jornadas em momentos diferentes.

Exemplo:

```text
Carlliane
├── Jornada #1 — conversa referente às filhas
└── Jornada #2 — conversa referente à própria matrícula
```

## 2.3 Histórico deve ser preservado

O Atlas deve registrar a evolução da jornada.

Interações, atividades e compromissos relevantes não devem ser apagados apenas para manter o estado atual.

## 2.4 Dados estruturados e dados livres

Informações que precisam ser filtradas, consultadas ou usadas sistematicamente devem ser estruturadas.

Informações ricas, variáveis e difíceis de padronizar devem permanecer em campos de texto livre quando isso fizer mais sentido.

Exemplo:

```text
periodo_estudo → estruturado
escola → estruturado
observacoes do diagnóstico → texto livre
```

## 2.5 Configuração versus regra de negócio

Valores que podem ser alterados pela operação, marketing ou configuração do sistema devem ser representados como dados configuráveis quando apropriado.

Por isso, opções de formulário como `buyer_journey` e faixas de investimento serão armazenadas em tabelas próprias.

---

# 3. Convenções técnicas

## 3.1 Identificadores

As entidades principais utilizarão `UUID` como chave primária.

## 3.2 Datas e horários

Instantes específicos serão armazenados como `TIMESTAMPTZ`.

Exemplo:

> Uma ligação ocorreu em 27/08/2026 às 10:30.

Horários recorrentes serão armazenados separadamente.

Exemplo:

> Uma turma acontece às terças e quintas às 16h.

Nesse caso, será utilizado `TIME` para o horário.

## 3.3 Nomenclatura

Tabelas e colunas utilizarão `snake_case`.

Exemplos:

```text
jornada_pessoas
periodo_estudo
hora_inicio
```

## 3.4 Exclusão

Quando um registro fizer parte do histórico comercial, deve-se preferir desativação ou encerramento à exclusão física.

Exemplo:

```text
curso.ativo = false
```

em vez de apagar um curso utilizado em jornadas antigas.

---

# 4. Entidades

## 4.1 `pessoas`

### Objetivo

Representar qualquer indivíduo conhecido pelo Atlas.

Uma pessoa pode ser responsável, aluna ou exercer ambos os papéis.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador único |
| `nome` | `VARCHAR(150)` | Não | | Nome da pessoa |
| `telefone` | `VARCHAR(30)` | Sim | | Telefone |
| `email` | `VARCHAR(254)` | Sim | | E-mail |
| `cidade` | `VARCHAR(100)` | Sim | | Cidade |
| `created_at` | `TIMESTAMPTZ` | Não | | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Data da última atualização |

### Regras

- `nome` é obrigatório.
- Telefone é texto, não número.
- Uma pessoa não deve ser duplicada apenas porque mudou de papel.
- Não haverá tabelas separadas para `leads`, `alunos` ou `responsáveis`.

---

## 4.2 `usuarios`

### Objetivo

Representar os usuários internos que operam o Atlas.

Usuários são diferentes de `pessoas`: `pessoas` representam indivíduos envolvidos nos atendimentos comerciais, enquanto `usuarios` representam membros da equipe que utilizam o sistema para registrar e acompanhar as jornadas.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `usuario_id` | `UUID` | Não | PK | Identificador único |
| `nome` | `VARCHAR(150)` | Não | | Nome do usuário |
| `email` | `VARCHAR(254)` | Não | UNIQUE | E-mail de acesso |
| `ativo` | `BOOLEAN` | Não | | Indica se o usuário está ativo |
| `created_at` | `TIMESTAMPTZ` | Não | | Data de criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Data da última atualização |

### Regras

- Um usuário representa uma pessoa que opera o Atlas.
- Usuários não devem ser confundidos com participantes de uma jornada.
- O usuário responsável pelo registro de uma interação ou atividade será referenciado por `usuario_id`.
- Usuários inativos não devem ser apagados quando possuírem registros históricos.

---

## 4.3 `relacionamentos_pessoas`

### Objetivo

Representar relações entre pessoas.

Exemplo:

```text
Carlliane
├── RESPONSÁVEL → Manoela
└── RESPONSÁVEL → Carolina
```

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `pessoa_origem_id` | `UUID` | Não | PK/FK | Pessoa que origina a relação |
| `pessoa_destino_id` | `UUID` | Não | PK/FK | Pessoa relacionada |
| `tipo_relacionamento` | `VARCHAR(50)` | Não | PK | Tipo da relação |
| `created_at` | `TIMESTAMPTZ` | Não | | Data de criação |

### Restrições

```text
PRIMARY KEY (pessoa_origem_id, pessoa_destino_id, tipo_relacionamento)
```

As duas pessoas devem existir em `pessoas`.

---

## 4.4 `jornadas`

### Objetivo

Representar um atendimento comercial específico.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `status` | `VARCHAR(30)` | Não | | Estado atual |
| `etapa` | `VARCHAR(50)` | Não | | Etapa atual |
| `buyer_journey_opcao_id` | `UUID` | Sim | FK | Opção de buyer journey |
| `investimento_opcao_id` | `UUID` | Sim | FK | Faixa de investimento |
| `recuperacao_triagem_opcao_id` | `UUID` | Sim | FK | Opção de recuperação |
| `alto_potencial` | `BOOLEAN` | Não | | Percepção comercial |
| `valor_ofertado` | `NUMERIC(12,2)` | Sim | | Valor ofertado |
| `motivo_perda_id` | `UUID` | Sim | FK | Motivo do encerramento |
| `opened_at` | `TIMESTAMPTZ` | Não | | Início |
| `closed_at` | `TIMESTAMPTZ` | Sim | | Encerramento |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

### Regras

- A jornada não possui `lead_id`.
- Os participantes são definidos por `jornada_pessoas`.
- Uma jornada pode possuir múltiplos responsáveis.
- `closed_at` deve ser preenchido quando a jornada for encerrada.
- O estado atual não substitui o histórico.

---

## 4.5 `jornada_pessoas`

### Objetivo

Associar pessoas a uma jornada e registrar o papel de cada uma naquele atendimento.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `jornada_id` | `UUID` | Não | PK/FK | Jornada |
| `pessoa_id` | `UUID` | Não | PK/FK | Pessoa |
| `papel` | `VARCHAR(30)` | Não | PK | Papel na jornada |
| `created_at` | `TIMESTAMPTZ` | Não | | Data da associação |

### Papéis iniciais

```text
RESPONSAVEL
ALUNO
```

Uma pessoa pode ter mais de um papel na mesma jornada.

---

## 4.6 `buyer_journey_opcoes`

### Objetivo

Armazenar as opções utilizadas pelo formulário para indicar o momento de compra percebido pelo lead.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `descricao` | `VARCHAR(255)` | Não | | Texto exibido |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `ordem` | `INTEGER` | Não | | Ordem de exibição |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

As opções podem ser alteradas ou desativadas sem modificar a estrutura de `jornadas`.

---

## 4.7 `investimento_opcoes`

### Objetivo

Armazenar as faixas de investimento utilizadas pelo formulário.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `descricao` | `VARCHAR(255)` | Não | | Texto da opção |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `ordem` | `INTEGER` | Não | | Ordem de exibição |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

---

## 4.8 `recuperacao_triagem_opcoes`

### Objetivo

Armazenar as opções apresentadas quando o lead indica não estar disposto a investir inicialmente.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `descricao` | `VARCHAR(255)` | Não | | Texto da opção |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `ordem` | `INTEGER` | Não | | Ordem de exibição |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

---

## 4.9 `motivos_perda`

### Objetivo

Armazenar os motivos disponíveis para o encerramento de uma jornada como perdida.

Os motivos são dados configuráveis e podem ser adicionados, alterados ou desativados sem modificar a estrutura da tabela `jornadas`.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `descricao` | `VARCHAR(255)` | Não | | Texto do motivo |
| `ativo` | `BOOLEAN` | Não | | Disponível para novos registros |
| `ordem` | `INTEGER` | Não | | Ordem de exibição |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

---

## 4.10 `cursos`

### Objetivo

Representar o catálogo de cursos oferecidos pela escola.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `nome` | `VARCHAR(150)` | Não | | Nome |
| `descricao` | `TEXT` | Sim | | Descrição |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

Cursos antigos devem preferencialmente ser desativados, não apagados.

---

## 4.11 `niveis`

### Objetivo

Representar níveis dentro de um curso.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `curso_id` | `UUID` | Não | FK | Curso |
| `nome` | `VARCHAR(100)` | Não | | Nome |
| `ordem` | `INTEGER` | Não | | Ordem pedagógica |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

Relacionamento:

```text
CURSO 1:N NIVEIS
```

---

## 4.12 `turmas`

### Objetivo

Representar uma oferta concreta de um determinado nível.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `nivel_id` | `UUID` | Não | FK | Nível |
| `nome` | `VARCHAR(100)` | Não | | Identificação |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

---

## 4.13 `horarios_turma`

### Objetivo

Representar os horários recorrentes de uma turma.

Uma turma pode ocorrer em mais de um dia por semana.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `turma_id` | `UUID` | Não | FK | Turma |
| `week_day` | `SMALLINT` | Não | | 1 a 7 |
| `start_time` | `TIME` | Não | | Início |
| `end_time` | `TIME` | Não | | Fim |

### Convenção

```text
1 = segunda-feira
2 = terça-feira
3 = quarta-feira
4 = quinta-feira
5 = sexta-feira
6 = sábado
7 = domingo
```

### Restrições

```text
week_day BETWEEN 1 AND 7
end_time > start_time
```

---

## 4.14 `jornada_cursos`

### Objetivo

Representar os cursos de interesse de uma jornada.

Interesse não significa matrícula.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `jornada_id` | `UUID` | Não | PK/FK | Jornada |
| `curso_id` | `UUID` | Não | PK/FK | Curso |
| `created_at` | `TIMESTAMPTZ` | Não | | Data da associação |

### Chave

```text
PRIMARY KEY (jornada_id, curso_id)
```

---

## 4.15 `diagnosticos`

### Objetivo

Registrar o entendimento construído sobre um aluno durante uma jornada.

O diagnóstico combina dados objetivos e observações livres.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `diagnostico_id` | `UUID` | Não | PK | Identificador |
| `jornada_id` | `UUID` | Não | FK | Jornada |
| `pessoa_id` | `UUID` | Não | FK | Aluno |
| `escola` | `VARCHAR(200)` | Sim | | Escola |
| `observacoes` | `TEXT` | Sim | | Observações livres |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

O período de estudo é relacionado por meio de `periodos_estudo`.

O banco deverá garantir que o aluno do diagnóstico esteja associado à respectiva jornada.

---

## 4.16 `periodos_estudo`

### Objetivo

Representar opções estruturadas para o período em que o aluno estuda.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `id` | `UUID` | Não | PK | Identificador |
| `nome` | `VARCHAR(50)` | Não | UNIQUE | Nome |
| `ativo` | `BOOLEAN` | Não | | Disponível |
| `ordem` | `INTEGER` | Não | | Ordem |

### Valores iniciais

```text
MANHA
TARDE
NOITE
INTEGRAL
HOMESCHOOLING
```

A lista pode ser expandida.

---

## 4.17 `diagnostico_periodos_estudo`

### Objetivo

Permitir que um diagnóstico tenha um ou mais períodos de estudo.

### Estrutura

| Coluna | Tipo | Nulo? | Chave |
|---|---|---:|---|
| `diagnostico_id` | `UUID` | Não | PK/FK |
| `periodo_estudo_id` | `UUID` | Não | PK/FK |

### Chave

```text
PRIMARY KEY (diagnostico_id, periodo_estudo_id)
```

---

## 4.18 `interacoes`

### Objetivo

Registrar o que aconteceu durante uma jornada.

Uma interação pode ser simples ou conter grande quantidade de informação.

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `interacao_id` | `UUID` | Não | PK | Identificador |
| `jornada_id` | `UUID` | Não | FK | Jornada |
| `atividade_id` | `UUID` | Sim | FK | Atividade relacionada |
| `tipo` | `VARCHAR(50)` | Não | | Tipo |
| `subtipo` | `VARCHAR(50)` | Sim | | Subtipo |
| `descricao` | `TEXT` | Não | | Registro |
| `origem` | `VARCHAR(30)` | Não | | Origem |
| `data_interacao` | `TIMESTAMPTZ` | Não | | Momento |
| `usuario_id` | `UUID` | Sim | FK | Pessoa que registrou |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |

A interação pode ser registrada manualmente, automaticamente ou com auxílio da IA.

---

## 4.19 `atividades`

### Objetivo

Representar ações que precisam ser realizadas dentro de uma jornada.

### Tipos iniciais

```text
TC — Tentativa de Contato
CF — Confirmação da Reunião de Fit
CM — Confirmação da Reunião de Matrícula
FD — Follow-up Diário
FS — Follow-up Semanal
FM — Follow-up Mensal
```

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `atividade_id` | `UUID` | Não | PK | Identificador |
| `jornada_id` | `UUID` | Não | FK | Jornada |
| `tipo` | `VARCHAR(10)` | Não | | Tipo |
| `sequencia` | `SMALLINT` | Sim | | Número |
| `descricao` | `TEXT` | Sim | | Detalhes |
| `data_prevista` | `TIMESTAMPTZ` | Sim | | Prazo |
| `status` | `VARCHAR(30)` | Não | | Estado |
| `usuario_id` | `UUID` | Sim | FK | Responsável |
| `atividade_anterior_id` | `UUID` | Sim | FK | Atividade anterior |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `completed_at` | `TIMESTAMPTZ` | Sim | | Conclusão |

Exemplo:

```text
tipo = FD
sequencia = 3
```

representa `FD3`.

---

## 4.20 `compromissos`

### Objetivo

Representar eventos agendados dentro de uma jornada.

Uma jornada pode ter vários compromissos.

### Tipos iniciais

```text
AULA_EXPERIMENTAL
REUNIAO_FIT
REUNIAO_MATRICULA
```

### Estrutura

| Coluna | Tipo | Nulo? | Chave | Descrição |
|---|---|---:|---|---|
| `compromisso_id` | `UUID` | Não | PK | Identificador |
| `jornada_id` | `UUID` | Não | FK | Jornada |
| `tipo` | `VARCHAR(30)` | Não | | Tipo |
| `start_time` | `TIMESTAMPTZ` | Não | | Início |
| `end_time` | `TIMESTAMPTZ` | Sim | | Fim |
| `status` | `VARCHAR(30)` | Não | | Estado |
| `observacao` | `TEXT` | Sim | | Observações |
| `calendar_event_id` | `VARCHAR(255)` | Sim | | ID externo |
| `created_at` | `TIMESTAMPTZ` | Não | | Criação |
| `updated_at` | `TIMESTAMPTZ` | Não | | Atualização |

Um compromisso remarcado não deve simplesmente ser apagado.

---

# 5. Relacionamentos principais

```text
PESSOA
  │
  ├── N:N → PESSOA
  │
  └── N:N → JORNADA
                │
                ├── N:N → CURSO
                │
                ├── 1:N → DIAGNÓSTICO
                │              │
                │              └── N:N → PERÍODO_ESTUDO
                │
                ├── 1:N → INTERAÇÃO
                │
                ├── 1:N → ATIVIDADE
                │
                └── 1:N → COMPROMISSO

CURSO
  │
  └── 1:N → NÍVEL
                │
                └── 1:N → TURMA
                              │
                              └── 1:N → HORÁRIO_TURMA
```

---

# 6. Fluxos conceituais

## 6.1 Jornada comercial

```text
PESSOA
   ↓
JORNADA
   ↓
TRIAGEM
   ↓
DIAGNÓSTICO
   ↓
OFERTA
   ↓
AULA EXPERIMENTAL / REUNIÃO FIT
   ↓
FOLLOW-UPS / NOVAS INTERAÇÕES
   ↓
REUNIÃO DE MATRÍCULA
   ↓
MATRÍCULA ou PERDA
```

O fluxo real pode variar conforme o atendimento.

---

## 6.2 Atividade → Interação → Compromisso

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

# 7. Integridade referencial

As chaves estrangeiras devem impedir referências a registros inexistentes.

Regras gerais:

- entidades-pai não devem ser apagadas quando isso destruiria histórico;
- registros de catálogo utilizados historicamente devem ser desativados;
- tabelas associativas devem impedir duplicações;
- relações obrigatórias devem utilizar `NOT NULL`;
- regras de `ON DELETE` serão definidas individualmente no `schema.sql`;
- quando necessário, constraints compostas serão utilizadas para garantir consistência entre entidades relacionadas.

---

# 8. Índices

Índices serão criados quando houver justificativa de consulta.

Consultas que provavelmente exigirão índices incluem:

- jornadas por status;
- jornadas por etapa;
- pessoa por telefone;
- jornadas de uma pessoa;
- interações de uma jornada;
- atividades pendentes;
- compromissos por período;
- turmas por nível;
- horários por dia da semana.

A lista definitiva será revisada durante a implementação do `schema.sql`.

---

# 9. IA e banco de dados

A IA será uma camada de interpretação e assistência, não uma porta de acesso irrestrito ao PostgreSQL.

Fluxo conceitual:

```text
Usuário
   ↓
IA
   ↓
Interpretação da intenção
   ↓
Estruturação dos dados
   ↓
Regras de negócio
   ↓
Serviços do Atlas
   ↓
PostgreSQL / Google Calendar / outras integrações
```

Exemplo futuro:

> “Acabei de falar com a mãe da Manoela. Ela prefere terça à tarde, está interessada em xadrez e confirmou a aula de sexta.”

A IA poderá interpretar a mensagem e propor operações estruturadas, mas a aplicação será responsável por validar e executar as alterações.

---

# 10. Evolução do modelo

Este documento representa o **Atlas v0.1**.

O modelo não precisa antecipar todas as necessidades futuras.

Novos casos reais poderão justificar:

- novos tipos de atividade;
- novos tipos de compromisso;
- novos papéis;
- novos campos de diagnóstico;
- novas opções de formulário;
- novas integrações;
- novas regras comerciais.

A regra de evolução é:

> **Não adicionar complexidade porque talvez um dia seja necessária. Adicionar estrutura quando uma necessidade real justificar.**

Toda mudança estrutural relevante deve ser refletida neste documento antes da alteração do banco.

---

# 11. Próximo passo

Com esta especificação relacional revisada, o próximo artefato será:

```text
database/schema.sql
```

O `schema.sql` será a implementação concreta desta especificação no PostgreSQL.

A sequência planejada é:

```text
ERD
 ↓
database_design.md
 ↓
schema.sql
 ↓
PostgreSQL
 ↓
seed.sql
 ↓
Backend Flask
```

O `database_design.md` é a especificação.  
O `schema.sql` é a construção.
