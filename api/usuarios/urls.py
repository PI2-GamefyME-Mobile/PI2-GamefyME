from django.urls import path
from .views import (
    CadastroAPIView,
    LoginAPIView,
    UsuarioDetailView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    LeaderboardView,
    EstatisticasUsuarioView,
    InativarContaView,
    ReativacaoSolicitarView,
    ReativacaoConfirmarView,
    google_login,
    google_register,
    
    # Views de Administração (RN 07, RN 09)
    ListarUsuariosAdminView,
    PromoverUsuarioAdminView,
    RebaixarUsuarioAdminView,
    DesativarUsuarioAdminView,
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
    path('estatisticas/', EstatisticasUsuarioView.as_view(), name='estatisticas-usuario'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Google OAuth
    path('login/google/', google_login, name='google-login'),
    path('cadastro/google/', google_register, name='google-register'),
    
    # Administração de Usuários (RN 07, RN 09)
    path('admin/usuarios/', ListarUsuariosAdminView.as_view(), name='admin-listar-usuarios'),
    path('admin/promover/<int:user_id>/', PromoverUsuarioAdminView.as_view(), name='admin-promover-usuario'),
    path('admin/rebaixar/<int:user_id>/', RebaixarUsuarioAdminView.as_view(), name='admin-rebaixar-usuario'),
    path('admin/desativar/<int:user_id>/', DesativarUsuarioAdminView.as_view(), name='admin-desativar-usuario'),
]
