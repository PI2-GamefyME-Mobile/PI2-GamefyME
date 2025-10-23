"""
Validadores customizados para o modelo de usuário.
RN 06: A senha deve possuir no mínimo 6 caracteres, 
sendo ao menos um maiúsculo e um caractere especial.
"""
import re
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _


class CustomPasswordValidator:
    """
    Validador customizado que garante:
    - Mínimo de 6 caracteres
    - Pelo menos uma letra maiúscula
    - Pelo menos um caractere especial
    """
    
    def validate(self, password, user=None):
        if len(password) < 6:
            raise ValidationError(
                _("A senha deve ter no mínimo 6 caracteres."),
                code='password_too_short',
            )
        
        if not re.search(r'[A-Z]', password):
            raise ValidationError(
                _("A senha deve conter pelo menos uma letra maiúscula."),
                code='password_no_upper',
            )
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;/]', password):
            raise ValidationError(
                _("A senha deve conter pelo menos um caractere especial (!@#$%^&*(),.?\":{}|<>-_=+[];/)."),
                code='password_no_special',
            )
    
    def get_help_text(self):
        return _(
            "Sua senha deve conter no mínimo 6 caracteres, "
            "incluindo pelo menos uma letra maiúscula e um caractere especial."
        )
