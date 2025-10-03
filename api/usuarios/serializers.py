from rest_framework import serializers
from .models import Usuario
from core.services import get_streak_data 
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from atividades.models import AtividadeConcluidas
from django.utils import timezone
from datetime import timedelta

class UsuarioSerializer(serializers.ModelSerializer):
    exp_total_nivel = serializers.SerializerMethodField()
    streak_data = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = [
            'idusuario', 'nmusuario', 'emailusuario',
            'nivelusuario', 'expusuario', 'imagem_perfil',
            'exp_total_nivel', 'streak_data'
        ]

    def get_exp_total_nivel(self, obj):
        # Exemplo fixo (pode ser alterado para cálculo real futuramente)
        return 1000

    def get_streak_data(self, obj):
        return get_streak_data(obj)

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def validate_email(self, value):
        if not Usuario.objects.filter(emailusuario=value).exists():
            raise serializers.ValidationError("Não existe um usuário com este e-mail.")
        return value

class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    token = serializers.CharField(max_length=6) # 'token' agora é o código
    new_password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError("As senhas não coincidem.")
        try:
            validate_password(data['new_password'])
        except DjangoValidationError as e:
            raise serializers.ValidationError({'new_password': list(e.messages)})
        return data
    
class LeaderboardSerializer(serializers.ModelSerializer):
    atividades_semana = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = [
            'idusuario',
            'nmusuario',
            'nivelusuario',
            'expusuario',
            'imagem_perfil',
            'atividades_semana'
        ]

    def get_atividades_semana(self, obj):
        hoje = timezone.now().date()
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        return AtividadeConcluidas.objects.filter(
            idusuario=obj,
            dtconclusao__date__gte=inicio_semana
        ).count()