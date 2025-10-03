from rest_framework import serializers
from django.utils import timezone
from .models import Desafio, UsuarioDesafio, TipoDesafio

class DesafioSerializer(serializers.ModelSerializer):
    # Campo que retorna o nome de exibição do 'tipo' (Ex: "Diário" ao invés de "diario")
    tipo_display = serializers.CharField(source='get_tipo_display', read_only=True)
    
    # Novo campo para verificar se o desafio foi completado pelo usuário
    completado = serializers.SerializerMethodField()

    class Meta:
        model = Desafio
        # Adicionamos os novos campos à lista
        fields = ['iddesafio', 'nmdesafio', 'dsdesafio', 'expdesafio', 'tipo', 'tipo_display', 'completado']

    def get_completado(self, obj):
        """
        Verifica se o desafio já foi concluído pelo usuário.
        Para desafios recorrentes (diário, semanal, mensal), a conclusão é resetada a cada novo período.
        """
        request = self.context.get('request')
        if not (request and hasattr(request, 'user') and request.user.is_authenticated):
            return False

        user = request.user
        
        try:
            # Busca o registro de conclusão do desafio para o usuário
            usuario_desafio = UsuarioDesafio.objects.get(idusuario=user, iddesafio=obj)
        except UsuarioDesafio.DoesNotExist:
            return False # Se não existe, não foi completado

        # Se o desafio é do tipo 'Único', basta que ele tenha sido completado uma vez.
        if obj.tipo == TipoDesafio.UNICO:
            return usuario_desafio.flsituacao

        # Para desafios recorrentes, precisamos verificar a data da última premiação.
        if not usuario_desafio.dtpremiacao:
            return False

        now = timezone.now()
        last_completed_date = usuario_desafio.dtpremiacao.date()
        today = now.date()

        # Verifica se a data da última conclusão está dentro do período corrente
        if obj.tipo == TipoDesafio.DIARIO:
            return last_completed_date == today
        elif obj.tipo == TipoDesafio.SEMANAL:
            start_of_week = today - timezone.timedelta(days=today.weekday())
            return last_completed_date >= start_of_week
        elif obj.tipo == TipoDesafio.MENSAL:
            return last_completed_date.year == today.year and last_completed_date.month == today.month
        
        return False


class UsuarioDesafioSerializer(serializers.ModelSerializer):
    # Aninha os detalhes do desafio para ter o contexto completo
    desafio = DesafioSerializer(source='iddesafio', read_only=True)

    class Meta:
        model = UsuarioDesafio
        fields = ['idusuariodesafio', 'dtpremiacao', 'flsituacao', 'desafio']