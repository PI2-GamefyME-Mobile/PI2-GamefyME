from django.urls import path
from .views import CadastroAPIView, LoginAPIView, MyTokenObtainPairView
from rest_framework_simplejwt.views import TokenRefreshView

app_name = "usuarios"

urlpatterns = [
    path("cadastro/", CadastroAPIView.as_view(), name="cadastro"),
    path("login/", LoginAPIView.as_view(), name="login"),
    path("token/", MyTokenObtainPairView.as_view(), name="token_obtain_pair"),  # login JWT
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),   # renovar access token
]
