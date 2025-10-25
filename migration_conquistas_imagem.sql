-- Migração para suportar URLs de imagens em conquistas
-- Este script verifica se o campo nmimagem já é TEXT e garante que pode armazenar URLs

-- O campo nmimagem já deve ser TEXT, mas vamos garantir
-- que não há constraints que impeçam armazenar URLs

-- Verificar se há conquistas existentes e criar backup
-- NOTA: Execute este comando primeiro para backup (opcional)
-- CREATE TABLE conquistas_backup AS SELECT * FROM conquistas;

-- Não precisa alterar o tipo do campo pois já é TEXT
-- Mas vamos garantir que permite NULL para novas conquistas sem imagem
ALTER TABLE conquistas ALTER COLUMN nmimagem DROP NOT NULL;

-- Comentários para documentação
COMMENT ON COLUMN conquistas.nmimagem IS 'Caminho relativo ou URL da imagem da conquista. Pode ser usado com ImageField do Django.';

-- Fim da migração
