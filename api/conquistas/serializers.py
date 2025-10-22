from rest_framework import serializers
from .models import Conquista, UsuarioConquista

class ConquistaSerializer(serializers.ModelSerializer):
    completada = serializers.SerializerMethodField()

    class Meta:
        model = Conquista
        fields = ['idconquista', 'nmconquista', 'dsconquista', 'nmimagem', 'expconquista', 'completada']

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
    class Meta:
        model = Conquista
        fields = ['idconquista', 'nmconquista', 'dsconquista', 'nmimagem', 'expconquista']
        read_only_fields = ['idconquista']

    def validate_nmimagem(self, value):
        """
        Valida se o nome da imagem tem extensão.
        """
        if not value.endswith(('.png', '.jpg', '.jpeg')):
            raise serializers.ValidationError(
                "O nome da imagem deve ter uma extensão válida (.png, .jpg, .jpeg)."
            )
        return value
