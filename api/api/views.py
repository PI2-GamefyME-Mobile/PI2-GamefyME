from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from google.oauth2 import id_token
from google.auth.transport import requests
from django.conf import settings
import logging
from usuarios.models import Usuario
import requests as http_requests


logger = logging.getLogger(__name__)
UserModel = get_user_model()

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
        given_name = verification_result.get('given_name', '')
        family_name = verification_result.get('family_name', '')
        google_id = verification_result.get('google_id')
        
        if not email:
            return Response(
                {'error': 'Email não encontrado no token'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Buscar por google_id primeiro
        user = None
        if google_id:
            user = UserModel.objects.filter(google_id=google_id).first()
        # Se não achou por google_id, buscar por email e vincular se necessário
        if user is None and email:
            user = UserModel.objects.filter(emailusuario=email).first()
            if user:
                # Vincula a conta Google se ainda não estiver vinculado
                if not user.google_id:
                    user.google_id = google_id
                    user.save(update_fields=["google_id"]) 
        
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
            existing_by_google = UserModel.objects.filter(google_id=google_id).first()
        existing_by_email = UserModel.objects.filter(emailusuario=email).first()

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
        
        # Criar novo usuário (com nosso modelo customizado)
        display_name = (given_name + (' ' + family_name if family_name else '')).strip() or email.split('@')[0]
        user = UserModel.objects.create(
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