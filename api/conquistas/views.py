from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from .models import Conquista, UsuarioConquista
from .serializers import ConquistaSerializer, UsuarioConquistaSerializer, ConquistaCreateSerializer
import os
from django.conf import settings

class IsAdmin(permissions.BasePermission):
    """
    Permissão customizada para verificar se o usuário é administrador.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.tipousuario == 'admin'

class ConquistaListView(generics.ListAPIView):
    """
    Endpoint para listar todas as conquistas disponíveis no sistema.
    """
    queryset = Conquista.objects.all()
    serializer_class = ConquistaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

class UsuarioConquistaListView(generics.ListAPIView):
    """
    Endpoint para listar o histórico de conquistas que o usuário logado já obteve.
    """
    serializer_class = UsuarioConquistaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UsuarioConquista.objects.filter(idusuario=self.request.user).order_by('-dtconcessao')

# Views de Administração
class ConquistaAdminListCreateView(generics.ListCreateAPIView):
    """
    Endpoint para administradores listarem todas as conquistas e criarem novas.
    """
    queryset = Conquista.objects.all().order_by('-idconquista')
    permission_classes = [IsAdmin]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ConquistaCreateSerializer
        return ConquistaSerializer
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

class ConquistaAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Endpoint para administradores visualizarem, editarem ou excluírem uma conquista.
    """
    queryset = Conquista.objects.all()
    serializer_class = ConquistaCreateSerializer
    permission_classes = [IsAdmin]
    lookup_field = 'idconquista'
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context

class ConquistaImageUploadView(APIView):
    """
    Endpoint para upload de imagens de conquistas.
    """
    permission_classes = [IsAdmin]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, *args, **kwargs):
        if 'image' not in request.FILES:
            return Response(
                {'error': 'Nenhuma imagem fornecida'},
                status=status.HTTP_400_BAD_REQUEST
            )

        image = request.FILES['image']
        
        # Validar extensão
        allowed_extensions = ['.png', '.jpg', '.jpeg']
        file_ext = os.path.splitext(image.name)[1].lower()
        if file_ext not in allowed_extensions:
            return Response(
                {'error': 'Formato de imagem inválido. Use PNG, JPG ou JPEG'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validar tamanho (max 5MB)
        if image.size > 5 * 1024 * 1024:
            return Response(
                {'error': 'Imagem muito grande. Tamanho máximo: 5MB'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Salvar temporariamente no modelo para obter a URL
        # Criar uma conquista temporária apenas para gerar a URL correta
        conquista_temp = Conquista(nmimagem=image)
        conquista_temp.save()
        
        # Pegar a URL completa da imagem
        imagem_url = request.build_absolute_uri(conquista_temp.nmimagem.url)
        filename = os.path.basename(conquista_temp.nmimagem.name)
        
        # Deletar a conquista temporária (mas manter o arquivo)
        filepath = conquista_temp.nmimagem.path
        conquista_temp.delete()
        
        return Response(
            {
                'success': True,
                'filename': filename,
                'url': imagem_url,
                'message': 'Imagem salva com sucesso'
            },
            status=status.HTTP_201_CREATED
        )