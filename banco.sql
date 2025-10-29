CREATE TABLE usuarios (
    idusuario SERIAL PRIMARY KEY,
    nmusuario VARCHAR(100) NOT NULL,
    emailusuario VARCHAR(100) NOT NULL UNIQUE,
    flsituacao BOOLEAN DEFAULT true,
    nivelusuario INTEGER DEFAULT 1,
    expusuario SMALLINT DEFAULT 0 CHECK (expusuario >= 0 AND expusuario <= 1000),
    tipousuario VARCHAR(20) NOT NULL DEFAULT 'comum',
    imagem_perfil VARCHAR(100) DEFAULT 'avatar1.png',
    ultima_atividade TIMESTAMPTZ,
    date_joined TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL,
    is_staff BOOLEAN NOT NULL,
    is_superuser BOOLEAN NOT NULL,
    last_login TIMESTAMPTZ,
    password VARCHAR(128) NOT NULL,
    google_id VARCHAR(255)
);


CREATE TABLE atividades (
    idatividade SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    nmatividade VARCHAR(100) NOT NULL,
    dificuldade VARCHAR(20) NOT NULL,
    situacao VARCHAR(20) NOT NULL,
    recorrencia VARCHAR(20) NOT NULL,
    dtatividade TIMESTAMP WITH TIME ZONE NOT NULL,
    dtatividaderealizada TIMESTAMP WITH TIME ZONE ,
    tpestimado INT NOT NULL,
    dsatividade TEXT,
    expatividade SMALLINT DEFAULT 0
);

CREATE TABLE desafios (
    iddesafio SERIAL PRIMARY KEY,
    nmdesafio VARCHAR(100) NOT NULL,
    dsdesafio TEXT,
    dtinicio TIMESTAMP WITH TIME ZONE ,
    dtfim TIMESTAMP WITH TIME ZONE,
    tipo VARCHAR(20) NOT NULL,
    expdesafio SMALLINT DEFAULT 0,
    tipo_logica VARCHAR(50),
    parametro INTEGER
);


CREATE TABLE usuario_desafios (
    idusuariodesafio SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    iddesafio INT NOT NULL REFERENCES desafios(iddesafio),
    flsituacao BOOLEAN DEFAULT TRUE,
    dtpremiacao TIMESTAMP WITH TIME ZONE 
);

CREATE TABLE notificacoes (
    idnotificacao SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    dsmensagem TEXT NOT NULL,
    fltipo VARCHAR(50),
    dtcriacao TIMESTAMP WITH TIME ZONE,
    flstatus BOOLEAN DEFAULT FALSE
);

CREATE TABLE conquistas (
    idconquista SERIAL PRIMARY KEY,
    nmconquista VARCHAR(100) NOT NULL,
    dsconquista TEXT,
    nmimagem TEXT,
    expconquista SMALLINT DEFAULT 0,
    regra TEXT,
    parametro SMALLINT,
    dificuldade_alvo VARCHAR(20)
    tipo_desafio_alvo VARCHAR(10),
    pomodoro_minutos SMALLINT
);

CREATE TABLE usuario_conquistas (
    idusuarioconquista SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    idconquista INT NOT NULL REFERENCES conquistas(idconquista),
    dtconcessao TIMESTAMP WITH TIME ZONE 
);

CREATE TABLE atividades_concluidas (
    idatividade_concluida SERIAL PRIMARY KEY,
    idatividade INT NOT NULL REFERENCES atividades(idatividade),
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    dtconclusao TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO conquistas (idconquista, nmconquista, dsconquista, nmimagem, expconquista, regra, parametro, dificuldade_alvo, tipo_desafio_alvo, pomodoro_minutos) VALUES
(1, 'ATIVIDADE CUMPRIDA', 'Complete sua primeira atividade.', 'conquistas/atividade_realizada.png', 50, 'atividades_concluidas_total', 1, NULL, NULL, 60),
(2, 'PRODUTIVIDADE EM ALTA', 'Complete 10 atividades.', 'conquistas/10atividades.png', 100, 'atividades_concluidas_total', 10, NULL, NULL, 60),
(3, 'RECORRÊNCIA - DE NOVO!', 'Complete uma atividade recorrente 5 vezes.', 'conquistas/recorrencia.png', 100, 'recorrentes_concluidas_total', 5, NULL, NULL, 60),
(4, 'USUÁRIO HARDCORE', 'Complete 5 atividades marcadas como muito difíceis.', 'conquistas/hardcore.png', 150, 'dificuldade_concluidas_total', 5, 'muito_dificil', NULL, 60),
(5, 'DESAFIANTE AMADOR', 'Complete seu primeiro desafio.', 'conquistas/missaocumprida.png', 50, 'desafios_concluidos_total', 1, NULL, NULL, 60),
(7, 'MISSÃO CUMPRIDA', 'Complete um desafio mensal.', 'conquistas/campeao.png', 150, 'desafios_concluidos_por_tipo', 1, NULL, 'mensal', 60),
(8, 'DESAFIANTE MESTRE', 'Complete 50 desafios.', 'conquistas/master.png', 200, 'desafios_concluidos_total', 50, NULL, NULL, 60),
(9, 'UM DIA APÓS O OUTRO', 'Mantenha uma sequência de 5 dias.', 'conquistas/umdiaaposooutro.png', 100, 'streak_conclusao', 5, NULL, NULL, 60),
(10, 'RITUAL SEMANAL', 'Cadastre uma atividade por dia por 7 dias.', 'conquistas/ritualsemana.png', 120, 'streak_criacao', 7, NULL, NULL, 60),
(11, 'CONSISTÊNCIA INABALÁVEL', 'Mantenha uma sequência de 15 dias.', 'conquistas/inabalavel.png', 200, 'streak_conclusao', 15, NULL, NULL, 60);

INSERT INTO desafios (iddesafio, nmdesafio, dsdesafio, dtinicio, dtfim, tipo, expdesafio, tipo_logica, parametro) VALUES
(1, 'Recorrência Semanal', 'Conclua atividades recorrentes por 7 dias.', '2025-05-30 00:00:00-03', '2025-12-31 00:00:00-03', 'semanal', 100, 'recorrentes_concluidas', 7),
(2, 'Semanal Produtivo', 'Conclua 10 atividades essa semana.', '2025-05-30 00:00:00-03', '2025-12-31 00:00:00-03', 'semanal', 100, 'atividades_concluidas', 10),
(3, 'Concluir 2 desafios', 'Concluir 2 desafios na semana', '2025-05-01 00:00:00-03', '2025-07-01 00:00:00-03', 'semanal', 150, 'desafios_concluidos', 2),
(4, 'Organização Diária', 'Cadastre 5 atividades no dia.', '1900-01-01 00:00:00-03:06:28', '3000-12-31 00:00:00-03', 'diario', 50, 'atividades_criadas', 5),
(5, 'Desafio Difícil', 'Realize pelo menos 1 atividade difícil.', '1900-01-01 00:00:00-03:06:28', '3000-12-31 00:00:00-03', 'diario', 50, 'min_dificeis', 1),
(6, 'Dupla Produtiva', 'Realize 2 atividades médias ou fáceis.', '1900-01-01 00:00:00-03:06:28', '3000-12-31 00:00:00-03', 'diario', 50, 'min_atividades_por_dificuldade', 2),
(7, 'Limpeza Fácil', 'Conclua todas as atividades muito fáceis do dia.', '1900-01-01 00:00:00-03:06:28', '3000-12-31 00:00:00-03', 'diario', 50, 'todas_muito_faceis', NULL),
(8, '3 Atividades', 'Completar 3 atividades distintas difíceis', '2025-05-01 00:00:00-03', '2025-07-01 00:00:00-03', 'diario', 200, 'min_dificeis', 3),
(9, 'Meta Mensal', 'Conclua 30 atividades no mês.', '2025-05-30 00:00:00-03', '2025-12-31 00:00:00-03', 'mensal', 500, 'atividades_concluidas', 30),
(10, 'Streak Mensal', 'Mantenha streak por 30 dias.', '2025-05-30 00:00:00-03', '2025-12-31 00:00:00-03', 'mensal', 500, 'streak_diario', 30),
(13, 'Check-in Diário', 'Conclua 2 atividades hoje', NULL, NULL, 'diario', 20, 'atividades_concluidas', 2),
(15, 'Ritmo Semanal', 'Conclua 5 atividades na semana', NULL, NULL, 'semanal', 60, 'atividades_concluidas', 5),
(16, 'Planejador Semanal', 'Crie 3 atividades durante a semana', NULL, NULL, 'semanal', 40, 'atividades_criadas', 3),
(18, 'Força e Foco', 'Conclua 2 atividades difíceis na semana', NULL, NULL, 'semanal', 90, 'min_dificeis', 2),
(19, 'Maratona do Mês', 'Conclua 20 atividades no mês', NULL, NULL, 'mensal', 200, 'atividades_concluidas', 20),
(20, 'Criador do Mês', 'Crie 8 atividades no mês', NULL, NULL, 'mensal', 120, 'atividades_criadas', 8),
(21, 'Elite Mensal', 'Conclua 6 atividades difíceis no mês', NULL, NULL, 'mensal', 180, 'min_dificeis', 6),
(22, 'Conquistador Mensal', 'Conclua 4 desafios no mês', NULL, NULL, 'mensal', 220, 'desafios_concluidos', 4);







