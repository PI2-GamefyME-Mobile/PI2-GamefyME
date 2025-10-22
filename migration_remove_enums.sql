-- Script de migração para remover ENUMs e substituir por VARCHAR
-- Execute este script no seu banco de dados PostgreSQL existente

-- IMPORTANTE: Faça backup do banco antes de executar!

-- 1. Alterar coluna tipousuario
ALTER TABLE usuarios 
    ALTER COLUMN tipousuario TYPE VARCHAR(20) USING tipousuario::text;

-- 2. Alterar colunas de atividades
ALTER TABLE atividades 
    ALTER COLUMN dificuldade TYPE VARCHAR(20) USING dificuldade::text,
    ALTER COLUMN situacao TYPE VARCHAR(20) USING situacao::text,
    ALTER COLUMN recorrencia TYPE VARCHAR(20) USING recorrencia::text;

-- 3. Alterar coluna tipo de desafios
ALTER TABLE desafios 
    ALTER COLUMN tipo TYPE VARCHAR(20) USING tipo::text;

-- 4. Alterar coluna fltipo de notificacoes (se ainda estiver usando ENUM)
-- Verificar se a coluna já é VARCHAR(50), se for ENUM, executar:
-- ALTER TABLE notificacoes 
--     ALTER COLUMN fltipo TYPE VARCHAR(50) USING fltipo::text;

-- 5. Remover os tipos ENUM (opcional, mas recomendado)
-- Isso só funciona se não houver mais nenhuma referência aos tipos
DROP TYPE IF EXISTS tipo_usuario_enum CASCADE;
DROP TYPE IF EXISTS dificuldade_enum CASCADE;
DROP TYPE IF EXISTS situacao_atividade_enum CASCADE;
DROP TYPE IF EXISTS recorrencia_enum CASCADE;
DROP TYPE IF EXISTS tipo_desafio_enum CASCADE;
DROP TYPE IF EXISTS tipo_notificacao_enum CASCADE;

-- 6. Adicionar valor padrão para tipousuario (se necessário)
ALTER TABLE usuarios 
    ALTER COLUMN tipousuario SET DEFAULT 'comum';

-- Verificar as alterações
SELECT 
    table_name, 
    column_name, 
    data_type, 
    character_maximum_length
FROM information_schema.columns
WHERE table_name IN ('usuarios', 'atividades', 'desafios', 'notificacoes')
    AND column_name IN ('tipousuario', 'dificuldade', 'situacao', 'recorrencia', 'tipo', 'fltipo')
ORDER BY table_name, column_name;
