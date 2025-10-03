import random
import string
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from django.db import IntegrityError, transaction
from django.contrib.auth.hashers import make_password
from .models import Usuario, TipoUsuario
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UsuarioSerializer, PasswordResetRequestSerializer, PasswordResetConfirmSerializer, LeaderboardSerializer
from django.core.mail import send_mail
from api.settings import EMAIL_HOST_USER
from django.core.cache import cache

# URL da API - /api/usuarios/cadastro/
class CadastroAPIView(APIView):
    permission_classes = [AllowAny] 
    def post(self, request):
        nome = request.data.get("nmusuario")
        email = request.data.get("emailusuario")
        senha = request.data.get("senha")
        confsenha = request.data.get("confsenha")

        if not all([nome, email, senha, confsenha]):
            return Response({"erro": "Preencha todos os campos."},
                            status=status.HTTP_400_BAD_REQUEST)

        if senha != confsenha:
            return Response({"erro": "Senhas não coincidem."},
                            status=status.HTTP_400_BAD_REQUEST)

        if Usuario.objects.filter(emailusuario=email).exists():
            return Response({"erro": "Já existe um usuário com esse e-mail cadastrado."},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                usuario = Usuario.objects.create(
                    nmusuario=nome,
                    emailusuario=email,
                    password=make_password(senha),
                    flsituacao=True,
                    nivelusuario=1,
                    expusuario=0,
                    tipousuario=TipoUsuario.COMUM
                )

                refresh = RefreshToken.for_user(usuario)
                return Response({
                    "message": "Usuário cadastrado com sucesso!",
                    "user": {
                        "id": usuario.idusuario,
                        "nome": usuario.nmusuario,
                        "email": usuario.emailusuario,
                    },
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    }
                }, status=status.HTTP_201_CREATED)

        except IntegrityError:
            return Response({"erro": "Erro de integridade ao salvar."},
                            status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"erro": f"Erro inesperado: {str(e)}"},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
# URL da API - /api/usuarios/login/      
class LoginAPIView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        email = request.data.get("emailusuario")
        password = request.data.get("password")

        if not email or not password:
            return Response(
                {"erro": "Email e senha são obrigatórios."},
                status=status.HTTP_400_BAD_REQUEST
            )

        usuario = authenticate(request, emailusuario=email, password=password)

        if usuario is None:
            return Response(
                {"erro": "Credenciais inválidas."},
                status=status.HTTP_400_BAD_REQUEST
            )

        refresh = RefreshToken.for_user(usuario)

        return Response(
            {
                "message": "Login bem-sucedido!",
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }
            },
            status=status.HTTP_200_OK
        )
        
class UsuarioDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UsuarioSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        user = request.user
        serializer = UsuarioSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            user = Usuario.objects.get(emailusuario=email)

            # Gerar um código de 6 dígitos
            code = ''.join(random.choices(string.digits, k=6))

            # Armazenar o código no cache com validade de 10 minutos
            cache.set(f'reset_code_{email}', code, timeout=600)

            subject = "Seu Código de Redefinição de Senha - GamefyME"
            message = f"""
            Olá {user.nmusuario},

            Recebemos uma solicitação para redefinir sua senha. Use o código abaixo para criar uma nova senha.

            Seu código é: {code}

            Este código irá expirar em 10 minutos.

            Se você não solicitou uma redefinição de senha, pode ignorar este e-mail com segurança.

            Atenciosamente,
            Equipe GamefyME
            """
            try:
                send_mail(subject, message, EMAIL_HOST_USER, [email])
                return Response({"message": "E-mail com o código de redefinição de senha enviado."}, status=status.HTTP_200_OK)
            except Exception as e:
                 return Response({"error": f"Falha ao enviar e-mail: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            code = serializer.validated_data['token']
            new_password = serializer.validated_data['new_password']

            stored_code = cache.get(f'reset_code_{email}')

            if stored_code is None:
                return Response({"error": "Código expirado ou inválido. Por favor, solicite um novo."}, status=status.HTTP_400_BAD_REQUEST)

            if stored_code != code:
                return Response({"error": "Código inválido."}, status=status.HTTP_400_BAD_REQUEST)
            
            try:
                user = Usuario.objects.get(emailusuario=email)
                user.password = make_password(new_password)
                user.save()
                cache.delete(f'reset_code_{email}')
                return Response({"message": "Senha redefinida com sucesso."}, status=status.HTTP_200_OK)
            except Usuario.DoesNotExist:
                 return Response({"error": "Usuário não encontrado."}, status=status.HTTP_404_NOT_FOUND)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class LeaderboardView(generics.ListAPIView):
    serializer_class = LeaderboardSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Usuario.objects.order_by('-nivelusuario', '-expusuario')