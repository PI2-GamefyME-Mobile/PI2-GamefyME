from rest_framework import serializers
from .models import Atividade

class AtividadeSerializer(serializers.ModelSerializer):
    # Usa PrimaryKeyRelatedField para tornar mais robusto
    idusuario = serializers.PrimaryKeyRelatedField(read_only=True)
    expatividade = serializers.ReadOnlyField()

    class Meta:
        model = Atividade
        fields = '__all__'
