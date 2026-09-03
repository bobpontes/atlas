-- Atlas CRM
-- Schema do banco de dados
-- Versão: 0.1

-- ==========================
-- EXTENSÕES
-- ==========================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================
-- PESSOAS
-- ==========================

CREATE TABLE pessoas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(254) UNIQUE,
    cidade VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE relacionamentos_pessoas (
    pessoa_origem_id UUID NOT NULL,
    pessoa_destino_id UUID NOT NULL,
    tipo_relacionamento VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (
        pessoa_origem_id,
        pessoa_destino_id,
        tipo_relacionamento
    ),

    FOREIGN KEY (pessoa_origem_id) REFERENCES pessoas(id),
    FOREIGN KEY (pessoa_destino_id) REFERENCES pessoas(id)
);

-- ==========================
-- USUÁRIOS DO SISTEMA
-- ==========================

CREATE TABLE usuarios (
    usuario_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(254) NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================
-- INFORMAÇÕES ESPECÍFICAS
-- ==========================

CREATE TABLE buyer_journey_opcoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descricao VARCHAR(255) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ordem INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE investimento_opcoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descricao VARCHAR(255) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ordem INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE recuperacao_triagem_opcoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descricao VARCHAR(255) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ordem INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE motivos_perda (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descricao VARCHAR(255) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ordem INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================
-- JORNADAS
-- ==========================

CREATE TABLE jornadas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status VARCHAR(30) NOT NULL,
    etapa VARCHAR(50) NOT NULL,
    buyer_journey_opcao_id UUID,
    investimento_opcao_id UUID,
    recuperacao_triagem_opcao_id UUID,
    alto_potencial BOOLEAN NOT NULL DEFAULT FALSE,
    valor_ofertado NUMERIC(12,2),
    motivo_perda_id UUID,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (buyer_journey_opcao_id) REFERENCES buyer_journey_opcoes(id),
    FOREIGN KEY (investimento_opcao_id) REFERENCES investimento_opcoes(id),
    FOREIGN KEY (recuperacao_triagem_opcao_id) REFERENCES recuperacao_triagem_opcoes(id),
    FOREIGN KEY (motivo_perda_id) REFERENCES motivos_perda(id)
);

CREATE TABLE jornada_pessoas (
    jornada_id UUID NOT NULL,
    pessoa_id UUID NOT NULL,
    papel VARCHAR(30) NOT NULL,
        CHECK (papel IN ('RESPONSAVEL', 'ALUNO')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (
        jornada_id,
        pessoa_id,
        papel
    ),

    FOREIGN KEY (jornada_id) REFERENCES jornadas(id),
    FOREIGN KEY (pessoa_id) REFERENCES pessoas(id)
);

CREATE TABLE cursos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE niveis (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    curso_id UUID NOT NULL,
    nome VARCHAR(100) NOT NULL,
    ordem INTEGER NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (curso_id) REFERENCES cursos(id)
);

CREATE TABLE turmas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nivel_id UUID NOT NULL,
    nome VARCHAR(100) NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (nivel_id) REFERENCES niveis(id)
);

CREATE TABLE horarios_turma (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    turma_id UUID NOT NULL,
    week_day SMALLINT NOT NULL
        CHECK (week_day BETWEEN 1 AND 7),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    CHECK (end_time > start_time),

    FOREIGN KEY (turma_id) REFERENCES turmas(id)
);

-- ==========================
-- DIAGNÓSTICOS E INTERAÇÕES
-- ==========================

CREATE TABLE jornada_cursos (
    jornada_id UUID NOT NULL,
    curso_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (
        jornada_id,
        curso_id
    ),

    FOREIGN KEY (jornada_id) REFERENCES jornadas(id),
    FOREIGN KEY (curso_id) REFERENCES cursos(id)
);

CREATE TABLE diagnosticos (
    diagnostico_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jornada_id UUID NOT NULL,
    pessoa_id UUID NOT NULL,
    escola VARCHAR(200),
    observacoes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (jornada_id) REFERENCES jornadas(id),
    FOREIGN KEY (pessoa_id) REFERENCES pessoas(id)
);

CREATE TABLE periodos_estudo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(50) NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    ordem INTEGER NOT NULL
);

CREATE TABLE diagnostico_periodos_estudo (
    diagnostico_id UUID NOT NULL,
    periodo_estudo_id UUID NOT NULL,

    PRIMARY KEY (
        diagnostico_id,
        periodo_estudo_id
    ),

    FOREIGN KEY (diagnostico_id) REFERENCES diagnosticos(diagnostico_id),
    FOREIGN KEY (periodo_estudo_id) REFERENCES periodos_estudo(id)
);

CREATE TABLE atividades (
    atividade_id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    jornada_id UUID NOT NULL,
    tipo VARCHAR(10) NOT NULL,
    sequencia SMALLINT,
    descricao TEXT,
    data_prevista TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL,
    usuario_id UUID NOT NULL,
    atividade_anterior_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,

    FOREIGN KEY (jornada_id) REFERENCES jornadas(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id),
    FOREIGN KEY (atividade_anterior_id) REFERENCES atividades(atividade_id)
);

CREATE TABLE interacoes (
    interacao_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jornada_id UUID NOT NULL,
    atividade_id UUID,
    tipo VARCHAR(50) NOT NULL,
    subtipo VARCHAR(50),
    descricao TEXT NOT NULL,
    origem VARCHAR(30) NOT NULL,
    data_interacao TIMESTAMPTZ NOT NULL,
    usuario_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (jornada_id) REFERENCES jornadas(id),
    FOREIGN KEY (atividade_id) REFERENCES atividades(atividade_id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

CREATE TABLE compromissos (
    compromisso_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jornada_id UUID NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL,
    observacao TEXT,
    calendar_event_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    FOREIGN KEY (jornada_id) REFERENCES jornadas(id)
);


