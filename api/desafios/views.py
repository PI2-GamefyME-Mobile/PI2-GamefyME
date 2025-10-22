from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Desafio, UsuarioDesafio
from .serializers import DesafioSerializer, UsuarioDesafioSerializer, DesafioCreateSerializer

class IsAdmin(permissions.BasePermission):
    """
    Permissão customizada para verificar se o usuário é administrador.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.tipousuario == 'admin'

class DesafioListView(generics.ListAPIView):
    """
    Endpoint para listar todos os desafios ativos que um usuário pode ver.
    """
    serializer_class = DesafioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Filtra para retornar apenas os desafios que estão ativos no momento
        return [desafio for desafio in Desafio.objects.all() if desafio.is_ativo()]

class UsuarioDesafioListView(generics.ListAPIView):
    """
    Endpoint para listar o histórico de desafios que o usuário logado já completou.
    """
    serializer_class = UsuarioDesafioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UsuarioDesafio.objects.filter(idusuario=self.request.user).order_by('-dtpremiacao')

# Views de Administração
class DesafioAdminListCreateView(generics.ListCreateAPIView):
    """
    Endpoint para administradores listarem todos os desafios e criarem novos.
    """
    queryset = Desafio.objects.all().order_by('-iddesafio')
    permission_classes = [IsAdmin]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return DesafioCreateSerializer
        return DesafioSerializer

class DesafioAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Endpoint para administradores visualizarem, editarem ou excluírem um desafio.
    """
    queryset = Desafio.objects.all()
    serializer_class = DesafioCreateSerializer
    permission_classes = [IsAdmin]
    lookup_field = 'iddesafio'
    