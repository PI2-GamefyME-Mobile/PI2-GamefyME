from django.urls import path
from .views import DesafioListView, UsuarioDesafioListView

urlpatterns = [
    path('', DesafioListView.as_view(), name='desafio-list'),
    path('meus-desafios/', UsuarioDesafioListView.as_view(), name='usuario-desafio-list'),
]