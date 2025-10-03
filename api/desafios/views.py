from rest_framework import generics, permissions
from .models import Desafio, UsuarioDesafio
from .serializers import DesafioSerializer, UsuarioDesafioSerializer

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
    
class DesafioGeralListView(generics.ListAPIView):
    """
    Endpoint para listar TODOS os desafios ativos, indicando quais já foram 
    concluídos pelo usuário no período corrente.
    """
    serializer_class = DesafioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Filtra para retornar apenas desafios que estão "ativos"
        # A lógica is_ativo() do seu model será implicitamente usada se você filtrar por data
        return Desafio.objects.all().order_by('tipo', 'nmdesafio')

    def get_serializer_context(self):
        # Essencial para passar o 'request' (e o usuário) para o serializer
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context