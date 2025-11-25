# api/usuarios/views.py

import random
import string
import logging
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from django.db import IntegrityError, transaction
from django.contrib.auth.hashers import make_password
from .models import Usuario, TipoUsuario
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import UsuarioSerializer, PasswordResetRequestSerializer, PasswordResetConfirmSerializer, LeaderboardSerializer, AdminUsuarioSerializer
from django.core.mail import send_mail
from api.settings import EMAIL_HOST_USER
from django.core.cache import cache
from google.oauth2 import id_token
from google.auth.transport import requests
from django.conf import settings
import requests as http_requests
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError

logger = logging.getLogger(__name__)

# --- Helpers internos para reduzir duplicações em endpoints administrativos ---
def _ensure_admin(request):
    """Retorna Response 403 se usuário não for admin; caso contrário, None."""
    if request.user.tipousuario != TipoUsuario.ADMIN:
        return Response(
            {'erro': 'Apenas administradores podem executar esta ação.'},
            status=status.HTTP_403_FORBIDDEN
        )
    return None


def _get_usuario_or_404(user_id):
    """Obtém Usuario por idusuario ou retorna None se não encontrado."""
    try:
        return Usuario.objects.get(idusuario=user_id)
    except Usuario.DoesNotExist:
        return None


def _prevent_self_action(request, usuario, message):
    """Bloqueia ação administrativa sobre si mesmo com mensagem específica."""
    if usuario.idusuario == request.user.idusuario:
        return Response({'erro': message}, status=status.HTTP_400_BAD_REQUEST)
    return None

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

        # RN 06: Validar senha com validadores do Django (incluindo o customizado)
        try:
            validate_password(senha)
        except DjangoValidationError as e:
            return Response({"erro": "; ".join(e.messages)},
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

        # Pré-checagem: se a conta correspondente ao e-mail estiver inativa, retornar 403 imediatamente
        # Isso evita que o authenticate() retorne None por causa de is_active=False (Django) e perca o motivo real.
        try:
            usuario_email = Usuario.objects.get(emailusuario=email)
            if (not getattr(usuario_email, 'flsituacao', True)) or (not getattr(usuario_email, 'is_active', True)):
                return Response(
                    {"erro": "Sua conta está inativa. Para reativá-la, solicite uma nova senha na tela 'Esqueceu a senha?'."},
                    status=status.HTTP_403_FORBIDDEN
                )
        except Usuario.DoesNotExist:
            # Prossegue para autenticação para manter mesma resposta em caso de usuário inexistente
            pass

        usuario = authenticate(request, emailusuario=email, password=password)

        if usuario is None:
            return Response(
                {"erro": "Credenciais inválidas."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Segurança adicional: caso algum backend retorne usuário inativo, ainda bloqueia
        if (not getattr(usuario, 'flsituacao', True)) or (not getattr(usuario, 'is_active', True)):
            return Response(
                {"erro": "Sua conta está inativa. Para reativá-la, solicite uma nova senha na tela 'Esqueceu a senha?'."},
                status=status.HTTP_403_FORBIDDEN
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

class InativarContaView(APIView):
    """Inativa logicamente a conta do usuário autenticado (soft delete)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        try:
            user.flsituacao = False
            user.is_active = False
            user.save(update_fields=["flsituacao", "is_active"])
            return Response({"message": "Conta inativada com sucesso."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"erro": str(e)}, status=status.HTTP_400_BAD_REQUEST)

class ReativacaoSolicitarView(APIView):
    """Envia um código por e-mail para reativar a conta (AllowAny)."""
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({"error": "E-mail é obrigatório."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            usuario = Usuario.objects.get(emailusuario=email)
        except Usuario.DoesNotExist:
            return Response({"error": "Usuário não encontrado."}, status=status.HTTP_404_NOT_FOUND)

        # Gera e armazena código temporário (10 minutos)
        code = ''.join(random.choices(string.digits, k=6))
        cache.set(f'reactivate_code_{email}', code, timeout=600)

        subject = "Reativação de Conta - GamefyME"
        message = f"""
        Olá {usuario.nmusuario},

        Recebemos uma solicitação para reativar sua conta no GamefyME. 
        Utilize o código abaixo para confirmar a reativação:

        Código: {code}

        Este código expira em 10 minutos.

        Se você não solicitou, ignore este e-mail.
        """
        try:
            send_mail(subject, message, EMAIL_HOST_USER, [email])
            return Response({"message": "E-mail de reativação enviado."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": f"Falha ao enviar e-mail: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ReativacaoConfirmarView(APIView):
    """Confirma o código e reativa a conta (AllowAny)."""
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('token')
        if not email or not code:
            return Response({"error": "E-mail e código são obrigatórios."}, status=status.HTTP_400_BAD_REQUEST)

        stored = cache.get(f'reactivate_code_{email}')
        if stored is None:
            return Response({"error": "Código expirado ou inválido."}, status=status.HTTP_400_BAD_REQUEST)
        if stored != code:
            return Response({"error": "Código inválido."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            usuario = Usuario.objects.get(emailusuario=email)
            usuario.flsituacao = True
            usuario.is_active = True
            usuario.save(update_fields=["flsituacao", "is_active"])
            cache.delete(f'reactivate_code_{email}')
            return Response({"message": "Conta reativada com sucesso."}, status=status.HTTP_200_OK)
        except Usuario.DoesNotExist:
            return Response({"error": "Usuário não encontrado."}, status=status.HTTP_404_NOT_FOUND)

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
                # Redefine a senha
                user.password = make_password(new_password)
                # Reativa a conta automaticamente, conforme a regra solicitada
                if getattr(user, 'flsituacao', True) is False or getattr(user, 'is_active', True) is False:
                    user.flsituacao = True
                    user.is_active = True
                user.save(update_fields=["password", "flsituacao", "is_active"])  # salva tudo de uma vez
                cache.delete(f'reset_code_{email}')
                return Response({"message": "Senha redefinida e conta reativada com sucesso."}, status=status.HTTP_200_OK)
            except Usuario.DoesNotExist:
                return Response({"error": "Usuário não encontrado."}, status=status.HTTP_404_NOT_FOUND)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LeaderboardView(generics.ListAPIView):
    serializer_class = LeaderboardSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # ALTERAÇÃO AQUI: Adicionado filtro por tipousuario
        return Usuario.objects.filter(tipousuario=TipoUsuario.COMUM).order_by('-nivelusuario', '-expusuario')


# ===== GOOGLE AUTHENTICATION =====

def verify_google_token(token):
    """
    Verifica um token do Google (idToken ou accessToken)
    Retorna as informações do usuário se válido
    """
    # Primeiro, tenta verificar como idToken
    try:
        idinfo = id_token.verify_oauth2_token(
            token, 
            requests.Request(), 
            settings.GOOGLE_CLIENT_ID
        )
        return {
            'success': True,
            'email': idinfo.get('email'),
            'given_name': idinfo.get('given_name', ''),
            'family_name': idinfo.get('family_name', ''),
            'google_id': idinfo.get('sub'),
        }
    except ValueError:
        # Se falhar, tenta como accessToken
        try:
            response = http_requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {token}'}
            )
            
            if response.status_code == 200:
                userinfo = response.json()
                return {
                    'success': True,
                    'email': userinfo.get('email'),
                    'given_name': userinfo.get('given_name', ''),
                    'family_name': userinfo.get('family_name', ''),
                    'google_id': userinfo.get('id'),
                }
            else:
                return {'success': False, 'error': 'Token inválido'}
        except Exception as e:
            logger.error(f"Erro ao verificar accessToken: {str(e)}")
            return {'success': False, 'error': str(e)}


def get_tokens_for_user(user):
    """Gera tokens JWT para um usuário"""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """
    Login com Google OAuth
    POST /api/usuarios/login/google/
    Body: { "token": "GOOGLE_ID_TOKEN ou ACCESS_TOKEN" }
    """
    try:
        data = request.data
        # Aceita múltiplos nomes de campo vindos do app web/mobile
        token = data.get('id_token') or data.get('token') or data.get('access_token')
        
        if not token:
            return Response(
                {'error': 'Token é obrigatório'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar o token com Google (idToken ou accessToken)
        verification_result = verify_google_token(token)
        
        if not verification_result.get('success'):
            return Response(
                {'error': verification_result.get('error', 'Token inválido')},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        email = verification_result.get('email')
        google_id = verification_result.get('google_id')
        
        if not email:
            return Response(
                {'error': 'Email não encontrado no token'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Buscar por google_id primeiro
        user = None
        if google_id:
            user = Usuario.objects.filter(google_id=google_id).first()
        # Se não achou por google_id, buscar por email e vincular se necessário
        if user is None and email:
            user = Usuario.objects.filter(emailusuario=email).first()
            if user:
                # Vincula a conta Google se ainda não estiver vinculado
                if not user.google_id:
                    user.google_id = google_id
                    user.save(update_fields=["google_id"]) 
        
        if not user:
            return Response(
                {'error': 'Usuário não encontrado. Por favor, registre-se primeiro.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Bloqueia login caso conta esteja inativa
        if (not getattr(user, 'flsituacao', True)) or (not getattr(user, 'is_active', True)):
            return Response(
                {"erro": "Sua conta está inativa. Para reativá-la, solicite uma nova senha na tela 'Esqueceu a senha?'."},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Gerar tokens JWT
        tokens = get_tokens_for_user(user)
        
        return Response({
            'message': 'Login realizado com sucesso',
            'user': {
                'idusuario': user.idusuario,
                'nmusuario': user.nmusuario,
                'emailusuario': user.emailusuario,
            },
            'tokens': tokens
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Erro no login Google: {str(e)}")
        return Response(
            {'error': 'Erro interno do servidor'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def google_register(request):
    """
    Registro com Google OAuth
    POST /api/usuarios/cadastro/google/
    Body: { "token": "GOOGLE_ID_TOKEN ou ACCESS_TOKEN" }
    """
    try:
        data = request.data
        token = data.get('id_token') or data.get('token') or data.get('access_token')
        
        if not token:
            return Response(
                {'error': 'Token é obrigatório'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar o token com Google (idToken ou accessToken)
        verification_result = verify_google_token(token)
        
        if not verification_result.get('success'):
            return Response(
                {'error': verification_result.get('error', 'Token inválido')},
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        email = verification_result.get('email')
        given_name = verification_result.get('given_name', '')
        family_name = verification_result.get('family_name', '')
        google_id = verification_result.get('google_id')
        
        if not email:
            return Response(
                {'error': 'Email não encontrado no token'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar se usuário já existe
        existing_by_google = None
        if google_id:
            existing_by_google = Usuario.objects.filter(google_id=google_id).first()
        existing_by_email = Usuario.objects.filter(emailusuario=email).first()

        if existing_by_google:
            # Já existe conta vinculada a este Google
            tokens = get_tokens_for_user(existing_by_google)
            return Response({
                'message': 'Conta Google já vinculada. Login realizado.',
                'user': {
                    'idusuario': existing_by_google.idusuario,
                    'nmusuario': existing_by_google.nmusuario,
                    'emailusuario': existing_by_google.emailusuario,
                },
                'tokens': tokens
            }, status=status.HTTP_200_OK)

        if existing_by_email:
            # Email já existe: vincular a conta Google se ainda não estiver
            if not existing_by_email.google_id:
                existing_by_email.google_id = google_id
                existing_by_email.save(update_fields=["google_id"])
                tokens = get_tokens_for_user(existing_by_email)
                return Response({
                    'message': 'Conta existente vinculada ao Google com sucesso. Login realizado.',
                    'linked': True,
                    'user': {
                        'idusuario': existing_by_email.idusuario,
                        'nmusuario': existing_by_email.nmusuario,
                        'emailusuario': existing_by_email.emailusuario,
                    },
                    'tokens': tokens
                }, status=status.HTTP_200_OK)
            else:
                return Response(
                    {
                        'error': 'Já existe uma conta com este e-mail vinculada a outro Google. Use login com Google.',
                        'code': 'email_already_linked',
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Criar novo usuário
        display_name = (given_name + (' ' + family_name if family_name else '')).strip() or email.split('@')[0]
        user = Usuario.objects.create(
            nmusuario=display_name,
            emailusuario=email,
            google_id=google_id,
            flsituacao=True,
        )
        # Define senha inutilizável (login sempre via Google)
        user.set_unusable_password()
        user.save()
        
        logger.info(f"Novo usuário criado via Google: {email}")
        
        # Gerar tokens JWT
        tokens = get_tokens_for_user(user)
        
        return Response({
            'message': 'Cadastro realizado com sucesso',
            'user': {
                'idusuario': user.idusuario,
                'nmusuario': user.nmusuario,
                'emailusuario': user.emailusuario,
            },
            'tokens': tokens
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        logger.error(f"Erro no registro Google: {str(e)}")
        return Response(
            {'error': 'Erro interno do servidor'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ===== ADMINISTRAÇÃO DE USUÁRIOS (RN 07) =====

class IsAdmin(permissions.BasePermission):
    """
    Permissão customizada para verificar se o usuário é administrador.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.tipousuario == 'administrador'


class ListarUsuariosAdminView(generics.ListAPIView):
    """
    Lista todos os usuários do sistema (apenas para administradores).
    GET /api/usuarios/admin/usuarios/
    """
    serializer_class = AdminUsuarioSerializer
    permission_classes = [IsAdmin]
    
    def get_queryset(self):
        return Usuario.objects.all().order_by('-date_joined')


class PromoverUsuarioAdminView(APIView):
    """
    RN 07: Apenas o administrador do sistema pode definir outros usuários como administradores.
    POST /api/usuarios/admin/promover/<int:user_id>/
    """
    permission_classes = [IsAdmin]
    
    def post(self, request, user_id):
        # Verifica se o solicitante é admin
        err = _ensure_admin(request)
        if err:
            # Mensagem específica para esta rota
            err.data = {'erro': 'Apenas administradores podem promover usuários.'}
            return err

        try:
            usuario = _get_usuario_or_404(user_id)
            if not usuario:
                return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

            # Não permite que um admin promova a si mesmo (redundante mas explícito)
            err = _prevent_self_action(request, usuario, 'Você já é administrador.')
            if err:
                return err

            # Verifica se já é admin
            if usuario.tipousuario == TipoUsuario.ADMIN:
                return Response({'message': f'{usuario.nmusuario} já é administrador.'}, status=status.HTTP_200_OK)

            # Promove o usuário
            usuario.tipousuario = TipoUsuario.ADMIN
            usuario.is_staff = True
            usuario.save()

            logger.info(f"Usuário {usuario.emailusuario} promovido a admin por {request.user.emailusuario}")

            return Response({
                'message': f'{usuario.nmusuario} foi promovido a administrador com sucesso!',
                'usuario': {
                    'idusuario': usuario.idusuario,
                    'nmusuario': usuario.nmusuario,
                    'emailusuario': usuario.emailusuario,
                    'tipousuario': usuario.tipousuario
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erro ao promover usuário: {str(e)}")
            return Response({'erro': f'Erro ao promover usuário: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class RebaixarUsuarioAdminView(APIView):
    """
    Remove privilégios de administrador de um usuário.
    POST /api/usuarios/admin/rebaixar/<int:user_id>/
    """
    permission_classes = [IsAdmin]
    
    def post(self, request, user_id):
        err = _ensure_admin(request)
        if err:
            err.data = {'erro': 'Apenas administradores podem rebaixar usuários.'}
            return err

        try:
            usuario = _get_usuario_or_404(user_id)
            if not usuario:
                return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

            # RN 09: Não permite que um admin rebaixe a si mesmo
            err = _prevent_self_action(request, usuario, 'Você não pode remover seus próprios privilégios de administrador.')
            if err:
                return err

            # Verifica se é admin
            if usuario.tipousuario != TipoUsuario.ADMIN:
                return Response({'message': f'{usuario.nmusuario} já é usuário comum.'}, status=status.HTTP_200_OK)

            # Rebaixa o usuário
            usuario.tipousuario = TipoUsuario.COMUM
            usuario.is_staff = False
            usuario.save()

            logger.info(f"Privilégios de admin removidos de {usuario.emailusuario} por {request.user.emailusuario}")

            return Response({
                'message': f'{usuario.nmusuario} foi rebaixado a usuário comum.',
                'usuario': {
                    'idusuario': usuario.idusuario,
                    'nmusuario': usuario.nmusuario,
                    'emailusuario': usuario.emailusuario,
                    'tipousuario': usuario.tipousuario
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erro ao rebaixar usuário: {str(e)}")
            return Response({'erro': f'Erro ao rebaixar usuário: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class DesativarUsuarioAdminView(APIView):
    """
    RN 09: Um administrador pode desativar contas de outros usuários exceto a sua.
    POST /api/usuarios/admin/desativar/<int:user_id>/
    """
    permission_classes = [IsAdmin]
    
    def post(self, request, user_id):
        err = _ensure_admin(request)
        if err:
            err.data = {'erro': 'Apenas administradores podem desativar usuários.'}
            return err

        try:
            usuario = _get_usuario_or_404(user_id)
            if not usuario:
                return Response({'erro': 'Usuário não encontrado.'}, status=status.HTTP_404_NOT_FOUND)

            # RN 09: Não permite que um admin desative a si mesmo
            err = _prevent_self_action(
                request,
                usuario,
                'Você não pode desativar sua própria conta. Use a opção de inativação na sua conta.'
            )
            if err:
                return err

            # Desativa o usuário
            usuario.flsituacao = False
            usuario.is_active = False
            usuario.save()

            logger.info(f"Usuário {usuario.emailusuario} desativado por admin {request.user.emailusuario}")

            return Response({
                'message': f'Conta de {usuario.nmusuario} foi desativada com sucesso.',
                'usuario': {
                    'idusuario': usuario.idusuario,
                    'nmusuario': usuario.nmusuario,
                    'emailusuario': usuario.emailusuario,
                    'flsituacao': usuario.flsituacao
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erro ao desativar usuário: {str(e)}")
            return Response({'erro': f'Erro ao desativar usuário: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
