from django.urls import path
from .views import (
    DesafioListView, 
    UsuarioDesafioListView,
    DesafioAdminListCreateView,
    DesafioAdminDetailView
)

urlpatterns = [
    path('', DesafioListView.as_view(), name='desafio-list'),
    path('meus-desafios/', UsuarioDesafioListView.as_view(), name='usuario-desafio-list'),
    # URLs de administração
    path('admin/', DesafioAdminListCreateView.as_view(), name='desafio-admin-list-create'),
    path('admin/<int:iddesafio>/', DesafioAdminDetailView.as_view(), name='desafio-admin-detail'),
]