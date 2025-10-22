from django.urls import path
from .views import (
    ConquistaListView, 
    UsuarioConquistaListView,
    ConquistaAdminListCreateView,
    ConquistaAdminDetailView,
    ConquistaImageUploadView
)

urlpatterns = [
    # Rota para o app listar todas as conquistas existentes
    # Ex: GET /api/conquistas/
    path('', ConquistaListView.as_view(), name='conquista-list'),
    
    # Rota para o app listar as conquistas que o usuário já desbloqueou
    # Ex: GET /api/conquistas/usuario/
    path('usuario/', UsuarioConquistaListView.as_view(), name='usuario-conquista-list'),
    
    # URLs de administração
    path('admin/', ConquistaAdminListCreateView.as_view(), name='conquista-admin-list-create'),
    path('admin/<int:idconquista>/', ConquistaAdminDetailView.as_view(), name='conquista-admin-detail'),
    path('admin/upload-image/', ConquistaImageUploadView.as_view(), name='conquista-upload-image'),
]
