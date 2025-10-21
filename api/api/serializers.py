from rest_framework import serializers
from django.contrib.auth.models import User

class GoogleAuthSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)
    
    def validate_token(self, value):
        if not value:
            raise serializers.ValidationError("Token is required")
        return value

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']