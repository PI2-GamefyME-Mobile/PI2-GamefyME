from django.urls import path
from .views import CadastroAPIView, LoginAPIView, UsuarioDetailView, PasswordResetRequestView, PasswordResetConfirmView, LeaderboardView

from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('cadastro/', CadastroAPIView.as_view(), name='cadastro'),
    path('login/', LoginAPIView.as_view(), name='login'),
    path('me/', UsuarioDetailView.as_view(), name='usuario-detail'),
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
