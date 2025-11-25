-- Inserção de dados iniciais nas tabelas conquistas e desafios

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







