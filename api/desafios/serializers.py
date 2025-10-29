from rest_framework import serializers
from .models import Desafio, UsuarioDesafio, TipoDesafio
from atividades.signals import get_date_range, get_datetime_range
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
        """Indica se o usuário já concluiu o desafio no ciclo vigente.

        Mantém a mesma noção de janela usada em get_date_range para evitar
        divergências (diário/semanal/mensal). Para desafios únicos, basta
        existir qualquer registro de conclusão.
        """
        request = self.context.get('request')
        if not (request and hasattr(request, 'user') and request.user.is_authenticated):
            return False

        user = request.user

        qs = UsuarioDesafio.objects.filter(idusuario=user, iddesafio=obj)
        if not qs.exists():
            return False

        # Desafios únicos: se já concluiu alguma vez, continua marcado
        if obj.tipo == TipoDesafio.UNICO:
            return True

        # Para diário/semanal/mensal, considera o intervalo atual
        inicio_dt, fim_dt = get_datetime_range(obj.tipo)
        if inicio_dt is None:
            # Se por algum motivo não há intervalo (tipo inesperado),
            # considerar não completado para evitar falsos positivos
            return False
        return qs.filter(dtpremiacao__range=[inicio_dt, fim_dt]).exists()

    def get_meta(self, obj):
        """ Retorna o parâmetro do desafio, que é a meta a ser atingida. """
        return obj.parametro

    def get_progresso(self, obj):
        """ Calcula o progresso atual do usuário para um desafio específico. """
        request = self.context.get('request')
        user = request.user
        
        inicio_dt, fim_dt = get_datetime_range(obj.tipo)
        if inicio_dt is None:
            return 0

        logicas_de_progresso = {
            'atividades_concluidas': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, dtconclusao__range=[inicio_dt, fim_dt]).count(),
            'recorrentes_concluidas': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, idatividade__recorrencia='recorrente', dtconclusao__range=[inicio_dt, fim_dt]).count(),
            'min_dificeis': lambda u, d: AtividadeConcluidas.objects.filter(idusuario=u, idatividade__dificuldade__in=['dificil', 'muito_dificil'], dtconclusao__range=[inicio_dt, fim_dt]).values('idatividade').distinct().count(),
            'desafios_concluidos': lambda u, d: UsuarioDesafio.objects.filter(idusuario=u, dtpremiacao__range=[inicio_dt, fim_dt]).count(),
            'atividades_criadas': lambda u, d: Atividade.objects.filter(idusuario=u, dtatividade__range=[inicio_dt, fim_dt]).count(),
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