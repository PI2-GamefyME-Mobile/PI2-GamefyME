-- Atualização de esquema para conquistas (PostgreSQL)
-- Data: 2025-10-28
-- Objetivo:
--  - Remover coluna "periodo" da tabela conquistas (conquistas são marcos permanentes)
--  - Garantir a existência das colunas dinâmicas e defaults
--  - Garantir unicidade de (idusuario, idconquista) em usuario_conquistas
--  - (Opcional) Popular regras para conquistas conhecidas por nome

BEGIN;

-- 1) Remover a coluna "periodo" (se existir)
ALTER TABLE IF EXISTS public.conquistas
  DROP COLUMN IF EXISTS periodo;

-- 2) Garantir colunas dinâmicas de conquistas
ALTER TABLE IF EXISTS public.conquistas
  ADD COLUMN IF NOT EXISTS regra VARCHAR(50),
  ADD COLUMN IF NOT EXISTS parametro SMALLINT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS dificuldade_alvo VARCHAR(20),
  ADD COLUMN IF NOT EXISTS tipo_desafio_alvo VARCHAR(10),
  ADD COLUMN IF NOT EXISTS pomodoro_minutos SMALLINT DEFAULT 60;

-- 2.1) Garantir defaults e valores não nulos onde faz sentido
UPDATE public.conquistas SET parametro = 1 WHERE parametro IS NULL;
UPDATE public.conquistas SET pomodoro_minutos = 60 WHERE pomodoro_minutos IS NULL;

-- NOT NULL para campos que no modelo são obrigatórios (parametro)
ALTER TABLE IF EXISTS public.conquistas
  ALTER COLUMN parametro SET NOT NULL;

-- 3) Unicidade (usuario, conquista) em usuario_conquistas
-- Observação: se já existir uma constraint unique, este índice não atrapalha.
CREATE UNIQUE INDEX IF NOT EXISTS ux_usuario_conquistas_user_conq
  ON public.usuario_conquistas (idusuario, idconquista);

-- 4) (Opcional) Popular regras por nomes de conquistas conhecidas
-- Estes updates são idempotentes e não afetam linhas já configuradas.
-- Ajuste conforme a necessidade ou remova esta seção.
UPDATE public.conquistas
  SET regra = 'atividades_concluidas_total', parametro = COALESCE(parametro, 1)
  WHERE UPPER(nmconquista) = 'ATIVIDADE CUMPRIDA' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'atividades_concluidas_total', parametro = 10
  WHERE UPPER(nmconquista) = 'PRODUTIVIDADE EM ALTA' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'recorrentes_concluidas_total', parametro = 5
  WHERE UPPER(nmconquista) = 'RECORRÊNCIA - DE NOVO!' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'dificuldade_concluidas_total', parametro = 5, dificuldade_alvo = 'muito_dificil'
  WHERE UPPER(nmconquista) = 'USUÁRIO HARDCORE' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'desafios_concluidos_total', parametro = 1
  WHERE UPPER(nmconquista) = 'DESAFIANTE AMADOR' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'desafios_concluidos_por_tipo', parametro = 1, tipo_desafio_alvo = 'semanal'
  WHERE UPPER(nmconquista) = 'CAMPEÃO SEMANAL' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'desafios_concluidos_por_tipo', parametro = 1, tipo_desafio_alvo = 'mensal'
  WHERE UPPER(nmconquista) = 'MISSÃO CUMPRIDA' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'desafios_concluidos_total', parametro = 50
  WHERE UPPER(nmconquista) = 'DESAFIANTE MESTRE' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'streak_conclusao', parametro = 5
  WHERE UPPER(nmconquista) = 'UM DIA APÓS O OUTRO' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'streak_criacao', parametro = 7
  WHERE UPPER(nmconquista) = 'RITUAL SEMANAL' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'streak_conclusao', parametro = 15
  WHERE UPPER(nmconquista) = 'CONSISTÊNCIA INABALÁVEL' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'pomodoro_concluidas_total', parametro = 1, pomodoro_minutos = 60
  WHERE UPPER(nmconquista) = 'POMODORO INICIANTE' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'pomodoro_concluidas_total', parametro = 5, pomodoro_minutos = 60
  WHERE UPPER(nmconquista) = 'POMODORO DEDICADO' AND (regra IS NULL OR regra = '');

UPDATE public.conquistas
  SET regra = 'pomodoro_concluidas_total', parametro = 20, pomodoro_minutos = 60
  WHERE UPPER(nmconquista) = 'POMODORO MESTRE' AND (regra IS NULL OR regra = '');

COMMIT;
