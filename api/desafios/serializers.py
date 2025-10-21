# api/desafios/serializers.py

from rest_framework import serializers
from django.utils import timezone
from .models import Desafio, UsuarioDesafio, TipoDesafio
# Importamos apenas o helper necessário para calcular o intervalo de datas
from atividades.signals import get_date_range
from atividades.models import AtividadeConcluidas, Atividade

class DesafioSerializer(serializers.ModelSerializer):
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    completado = serializers.SerializerMethodField()
    # Novos campos para a barra de progresso
    progresso = serializers.SerializerMethodField()
    meta = serializers.SerializerMethodField()

    class Meta:
        model = Desafio
        fields = [
            'iddesafio', 'nmdesafio', 'dsdesafio', 'expdesafio', 
            'tipo', 'tipo_display', 'completado', 'progresso', 'meta'
        ]

    def get_completado(self, obj):
        request = self.context.get('request')
        if not (request and hasattr(request, 'user') and request.user.is_authenticated):
            return False

        user = request.user
        
        # Filtra pelas conclusões do desafio para o usuário
        conclusoes = UsuarioDesafio.objects.filter(idusuario=user, iddesafio=obj)
        if not conclusoes.exists():
            return False

        # Pega a conclusão mais recente
        ultima_conclusao = conclusoes.latest('dtpremiacao')

        if obj.tipo == TipoDesafio.UNICO:
            return True # Se existe qualquer registro, já foi.

        if not ultima_conclusao.dtpremiacao:
            return False

        now = timezone.now()
        last_completed_date = ultima_conclusao.dtpremiacao.date()
        today = now.date()

        if obj.tipo == TipoDesafio.DIARIO:
            return last_completed_date == today
        elif obj.tipo == TipoDesafio.SEMANAL:
            # A semana começa no Domingo (weekday 6) para o usuário, mas no Django é Segunda (0)
            start_of_week = today - timezone.timedelta(days=(today.weekday() + 1) % 7)
            return last_completed_date >= start_of_week
        elif obj.tipo == TipoDesafio.MENSAL:
            return last_completed_date.year == today.year and last_completed_date.month == today.month
        
        return False

    def get_meta(self, obj):
        """ Retorna o parâmetro do desafio, que é a meta a ser atingida. """
        return obj.parametro

    def get_progresso(self, obj):
        """ Calcula o progresso atual do usuário para um desafio específico. """
        request = self.context.get('request')
        user = request.user
        
        inicio, fim = get_date_range(obj.tipo)
        if inicio is None:
            return 0

        # Mapeia o tipo de lógica para uma função que retorna a contagem atual
        logicas_de_progresso = {
            'atividades_concluidas': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, dtconclusao__date__range=[inicio, fim]).count(),
            'recorrentes_concluidas': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, idatividade__recorrencia='recorrente', dtconclusao__date__range=[inicio, fim]).count(),
            'min_dificeis': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, idatividade__dificuldade__in=['dificil', 'muito_dificil'], dtconclusao__date__range=[inicio, fim]).values('idatividade').distinct().count(),
            'desafios_concluidos': lambda u, d: UsuarioDesafio.objects.filter(idusuario=u, dtpremiacao__date__range=[inicio, fim]).count(),
            'atividades_criadas': lambda u, d: Atividade.objects.filter(idusuario=u, dtatividade__date__range=[inicio, fim]).count(),
        }

        funcao_progresso = logicas_de_progresso.get(obj.tipo_logica)
        
        if funcao_progresso:
            # Retorna o progresso, mas não deixa passar da meta
            return min(funcao_progresso(user, obj), obj.parametro)
        
        return 0


class UsuarioDesafioSerializer(serializers.ModelSerializer):
    desafio = DesafioSerializer(source='iddesafio', read_only=True)

    class Meta:
        model = UsuarioDesafio
        fields = ['idusuariodesafio', 'dtpremiacao', 'flsituacao', 'desafio']