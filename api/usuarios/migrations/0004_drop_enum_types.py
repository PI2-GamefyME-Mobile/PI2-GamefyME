# Script para remover completamente os tipos ENUM do PostgreSQL
# Execute APÓS rodar todas as migrations do Django

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('usuarios', '0003_remove_enum_types'),
        ('atividades', '0003_remove_enum_types'),
        ('desafios', '0003_remove_enum_types'),
    ]

    operations = [
        migrations.RunSQL(
            # Forward: Remover tipos ENUM do banco
            sql="""
                -- Remover os tipos ENUM se existirem
                DROP TYPE IF EXISTS tipo_usuario_enum CASCADE;
                DROP TYPE IF EXISTS dificuldade_enum CASCADE;
                DROP TYPE IF EXISTS situacao_atividade_enum CASCADE;
                DROP TYPE IF EXISTS recorrencia_enum CASCADE;
                DROP TYPE IF EXISTS tipo_desafio_enum CASCADE;
                DROP TYPE IF EXISTS tipo_notificacao_enum CASCADE;
            """,
            # Reverse: Recriar ENUMs (se necessário rollback)
            reverse_sql="""
                -- Recriar os tipos ENUM
                CREATE TYPE tipo_usuario_enum AS ENUM ('comum', 'admin');
                CREATE TYPE dificuldade_enum AS ENUM ('muito_facil', 'facil', 'medio', 'dificil', 'muito_dificil');
                CREATE TYPE situacao_atividade_enum AS ENUM ('ativa', 'realizada', 'cancelada');
                CREATE TYPE recorrencia_enum AS ENUM ('unica', 'recorrente');
                CREATE TYPE tipo_desafio_enum AS ENUM ('diario', 'semanal', 'mensal', 'unico');
                CREATE TYPE tipo_notificacao_enum AS ENUM ('info', 'sucesso', 'aviso', 'erro');
            """
        ),
    ]
