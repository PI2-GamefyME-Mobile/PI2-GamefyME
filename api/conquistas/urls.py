from django.urls import path
from .views import (
    ConquistaListView, 
    UsuarioConquistaListView,
    ConquistaAdminListCreateView,
    ConquistaAdminDetailView,
    ConquistaImageUploadView,
    TrofeusUsuarioListView,
    TrofeusUsuarioPublicListView,
)

urlpatterns = [
    path('', ConquistaListView.as_view(), name='conquista-list'),
    path('usuario/', UsuarioConquistaListView.as_view(), name='usuario-conquista-list'),
    path('usuario/trofeus/', TrofeusUsuarioListView.as_view(), name='usuario-trofeus-list'),
    path('usuario/<int:idusuario>/trofeus/', TrofeusUsuarioPublicListView.as_view(), name='usuario-trofeus-public-list'),
    
    # URLs de administração
    path('admin/', ConquistaAdminListCreateView.as_view(), name='conquista-admin-list-create'),
    path('admin/<int:idconquista>/', ConquistaAdminDetailView.as_view(), name='conquista-admin-detail'),
    path('admin/upload-image/', ConquistaImageUploadView.as_view(), name='conquista-upload-image'),
]
