from django.urls import path
from .views import DesafioListView, UsuarioDesafioListView, DesafioGeralListView

urlpatterns = [
    path('', DesafioListView.as_view(), name='desafio-list'),
    path('meus-desafios/', UsuarioDesafioListView.as_view(), name='usuario-desafio-list'),
    path('geral/', DesafioGeralListView.as_view(), name='desafio-geral-list'),
]