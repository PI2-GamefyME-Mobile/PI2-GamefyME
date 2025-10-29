from django.core.management.base import BaseCommand
from django.db import transaction
from desafios.models import Desafio, TipoDesafio

EXEMPLOS = [
    # 2 Diários
    {
        "nmdesafio": "Check-in Diário",
        "dsdesafio": "Conclua 2 atividades hoje",
        "tipo": TipoDesafio.DIARIO,
        "tipo_logica": "atividades_concluidas",
        "parametro": 2,
        "expdesafio": 20,
    },
    {
        "nmdesafio": "Criador do Dia",
        "dsdesafio": "Crie 1 nova atividade hoje",
        "tipo": TipoDesafio.DIARIO,
        "tipo_logica": "atividades_criadas",
        "parametro": 1,
        "expdesafio": 15,
    },
    # 4 Semanais
    {
        "nmdesafio": "Ritmo Semanal",
        "dsdesafio": "Conclua 5 atividades na semana",
        "tipo": TipoDesafio.SEMANAL,
        "tipo_logica": "atividades_concluidas",
        "parametro": 5,
        "expdesafio": 60,
    },
    {
        "nmdesafio": "Planejador Semanal",
        "dsdesafio": "Crie 3 atividades durante a semana",
        "tipo": TipoDesafio.SEMANAL,
        "tipo_logica": "atividades_criadas",
        "parametro": 3,
        "expdesafio": 40,
    },
    {
        "nmdesafio": "Desafios da Semana",
        "dsdesafio": "Conclua 2 desafios nesta semana",
        "tipo": TipoDesafio.SEMANAL,
        "tipo_logica": "desafios_concluidos",
        "parametro": 2,
        "expdesafio": 80,
    },
    {
        "nmdesafio": "Força e Foco",
        "dsdesafio": "Conclua 2 atividades difíceis na semana",
        "tipo": TipoDesafio.SEMANAL,
        "tipo_logica": "min_dificeis",
        "parametro": 2,
        "expdesafio": 90,
    },
    # 4 Mensais
    {
        "nmdesafio": "Maratona do Mês",
        "dsdesafio": "Conclua 20 atividades no mês",
        "tipo": TipoDesafio.MENSAL,
        "tipo_logica": "atividades_concluidas",
        "parametro": 20,
        "expdesafio": 200,
    },
    {
        "nmdesafio": "Criador do Mês",
        "dsdesafio": "Crie 8 atividades no mês",
        "tipo": TipoDesafio.MENSAL,
        "tipo_logica": "atividades_criadas",
        "parametro": 8,
        "expdesafio": 120,
    },
    {
        "nmdesafio": "Elite Mensal",
        "dsdesafio": "Conclua 6 atividades difíceis no mês",
        "tipo": TipoDesafio.MENSAL,
        "tipo_logica": "min_dificeis",
        "parametro": 6,
        "expdesafio": 180,
    },
    {
        "nmdesafio": "Conquistador Mensal",
        "dsdesafio": "Conclua 4 desafios no mês",
        "tipo": TipoDesafio.MENSAL,
        "tipo_logica": "desafios_concluidos",
        "parametro": 4,
        "expdesafio": 220,
    },
]

class Command(BaseCommand):
    help = "Cria exemplos de desafios (2 diários, 4 semanais, 4 mensais) de forma idempotente."

    @transaction.atomic
    def handle(self, *args, **options):
        criados = 0
        for data in EXEMPLOS:
            obj, created = Desafio.objects.get_or_create(
                nmdesafio=data["nmdesafio"],
                defaults=data,
            )
            if created:
                criados += 1
        self.stdout.write(self.style.SUCCESS(f"Desafios de exemplo prontos. Criados: {criados}, existentes: {len(EXEMPLOS) - criados}"))
