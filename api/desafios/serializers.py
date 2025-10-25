from rest_framework import serializers
from django.utils import timezone
from .models import Desafio, UsuarioDesafio, TipoDesafio
from atividades.signals import get_date_range
from atividades.models import AtividadeConcluidas, Atividade

class DesafioSerializer(serializers.ModelSerializer):
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    completado = serializers.SerializerMethodField()
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
        
        conclusoes = UsuarioDesafio.objects.filter(idusuario=user, iddesafio=obj)
        if not conclusoes.exists():
            return False

        ultima_conclusao = conclusoes.latest('dtpremiacao')

        if obj.tipo == TipoDesafio.UNICO:
            return True

        if not ultima_conclusao.dtpremiacao:
            return False

        now = timezone.now()
        last_completed_date = ultima_conclusao.dtpremiacao.date()
        today = now.date()

        if obj.tipo == TipoDesafio.DIARIO:
            return last_completed_date == today
        elif obj.tipo == TipoDesafio.SEMANAL:
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

        logicas_de_progresso = {
            'atividades_concluidas': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, dtconclusao__date__range=[inicio, fim]).count(),
            'recorrentes_concluidas': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, idatividade__recorrencia='recorrente', dtconclusao__date__range=[inicio, fim]).count(),
            'min_dificeis': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, idatividade__dificuldade__in=['dificil', 'muito_dificil'], dtconclusao__date__range=[inicio, fim]).values('idatividade').distinct().count(),
            'desafios_concluidos': lambda u, d: UsuarioDesafio.objects.filter(idusuario=u, dtpremiacao__date__range=[inicio, fim]).count(),
            'atividades_criadas': lambda u, d: Atividade.objects.filter(idusuario=u, dtatividade__date__range=[inicio, fim]).count(),
        }

        funcao_progresso = logicas_de_progresso.get(obj.tipo_logica)
        
        if funcao_progresso:
            return min(funcao_progresso(user, obj), obj.parametro)
        
        return 0


class UsuarioDesafioSerializer(serializers.ModelSerializer):
    desafio = DesafioSerializer(source='iddesafio', read_only=True)

    class Meta:
        model = UsuarioDesafio
        fields = ['idusuariodesafio', 'dtpremiacao', 'flsituacao', 'desafio']

class DesafioCreateSerializer(serializers.ModelSerializer):
    """
    Serializer para criação e edição de desafios (apenas admin).
    """
    class Meta:
        model = Desafio
        fields = [
            'iddesafio', 'nmdesafio', 'dsdesafio', 'tipo', 
            'dtinicio', 'dtfim', 'expdesafio', 'tipo_logica', 'parametro'
        ]
        read_only_fields = ['iddesafio']

    def validate(self, data):
        """
        Validações customizadas.
        """
        # Para desafios únicos, dtinicio/dtfim são obrigatórios
        if data.get('tipo') == TipoDesafio.UNICO:
            if not data.get('dtinicio') or not data.get('dtfim'):
                raise serializers.ValidationError(
                    "Desafios únicos precisam de data de início e fim."
                )
            if data.get('dtinicio') >= data.get('dtfim'):
                raise serializers.ValidationError(
                    "A data de início deve ser anterior à data de fim."
                )
        
        # Para desafios diário/semanal/mensal, se dtinicio/dtfim forem fornecidos,
        # validar consistência (início < fim)
        if data.get('dtinicio') and data.get('dtfim'):
            if data.get('dtinicio') >= data.get('dtfim'):
                raise serializers.ValidationError(
                    "A data de início deve ser anterior à data de fim."
                )
        
        return data