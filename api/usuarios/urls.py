from django.urls import path
from .views import (
    CadastroAPIView,
    LoginAPIView,
    UsuarioDetailView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    LeaderboardView,
    InativarContaView,
    ReativacaoSolicitarView,
    ReativacaoConfirmarView,
)

from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('cadastro/', CadastroAPIView.as_view(), name='cadastro'),
    path('login/', LoginAPIView.as_view(), name='login'),
    path('me/', UsuarioDetailView.as_view(), name='usuario-detail'),
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('inativar/', InativarContaView.as_view(), name='inativar-conta'),
    path('reativar/solicitar/', ReativacaoSolicitarView.as_view(), name='reativar-solicitar'),
    path('reativar/confirmar/', ReativacaoConfirmarView.as_view(), name='reativar-confirmar'),
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
