from rest_framework import serializers
from .models import Conquista, UsuarioConquista, TipoRegraConquista

class ConquistaSerializer(serializers.ModelSerializer):
    completada = serializers.SerializerMethodField()
    imagem_url = serializers.SerializerMethodField()

    class Meta:
        model = Conquista
        fields = ['idconquista', 'nmconquista', 'dsconquista', 'nmimagem', 'imagem_url', 'expconquista', 'completada']

    def get_imagem_url(self, obj):
        request = self.context.get('request')
        return obj.get_imagem_url(request)

    def get_completada(self, obj):
        # Pega o usuário da requisição que está no contexto do serializer, com fallback
        request = self.context.get('request', None)
        usuario = None
        if request is not None:
            usuario = getattr(request, 'user', None)
        else:
            # fallback: se alguém passou explicitamente 'usuario' no context
            usuario = self.context.get('usuario', None)

        if usuario and getattr(usuario, 'is_authenticated', False):
            return UsuarioConquista.objects.filter(idusuario=usuario, idconquista=obj).exists()
        return False

class UsuarioConquistaSerializer(serializers.ModelSerializer):
    conquista = ConquistaSerializer(source='idconquista', read_only=True)

    class Meta:
        model = UsuarioConquista
        fields = ['idusuarioconquista', 'dtconcessao', 'conquista']

class ConquistaCreateSerializer(serializers.ModelSerializer):
    """
    Serializer para criação e edição de conquistas (apenas admin).
    """
    imagem_url = serializers.SerializerMethodField()

    class Meta:
        model = Conquista
        fields = [
            'idconquista', 'nmconquista', 'dsconquista', 'nmimagem', 'imagem_url', 'expconquista',
            'regra', 'parametro', 'dificuldade_alvo', 'tipo_desafio_alvo', 'pomodoro_minutos'
        ]
        read_only_fields = ['idconquista']

    def get_imagem_url(self, obj):
        request = self.context.get('request')
        return obj.get_imagem_url(request)
    
    def validate_nmimagem(self, value):
        """
        Garante que o caminho da imagem está no formato correto.
        """
        if value and not value.startswith('conquistas/'):
            # Se for apenas o nome do arquivo, adicionar o prefixo
            return f'conquistas/{value}'
        return value

    def validate(self, data):
        # Regras básicas de coerência dos campos dinâmicos
        regra = data.get('regra')
        if regra:
            if regra in [TipoRegraConquista.DIFICULDADE_CONCLUIDAS_TOTAL]:
                if not data.get('dificuldade_alvo'):
                    raise serializers.ValidationError('dificuldade_alvo é obrigatório para a regra de dificuldade.')
            if regra in [TipoRegraConquista.DESAFIOS_CONCLUIDOS_POR_TIPO]:
                if not data.get('tipo_desafio_alvo'):
                    raise serializers.ValidationError('tipo_desafio_alvo é obrigatório para regras de desafios por tipo.')
            if regra in [TipoRegraConquista.POMODORO_CONCLUIDAS_TOTAL]:
                if not data.get('pomodoro_minutos'):
                    data['pomodoro_minutos'] = 60
        return data


class TrofeuUsuarioSerializer(serializers.ModelSerializer):
    """
    Serializer enxuto para exibir "troféus" (conquistas desbloqueadas pelo usuário)
    com dados de imagem prontos para UI.
    """
    imagem_url = serializers.SerializerMethodField()

    class Meta:
        model = Conquista
        fields = ['idconquista', 'nmconquista', 'imagem_url']

    def get_imagem_url(self, obj):
        request = self.context.get('request')
        return obj.get_imagem_url(request)