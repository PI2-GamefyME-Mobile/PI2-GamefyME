from django.contrib.auth.backends import ModelBackend
from .models import Usuario

class EmailBackend(ModelBackend):
    def authenticate(self, request, email=None, password=None, **kwargs):
        try:
            user = Usuario.objects.get(emailusuario=email)
        except Usuario.DoesNotExist:
            return None

        if user.check_password(password):
            return user
        return None
