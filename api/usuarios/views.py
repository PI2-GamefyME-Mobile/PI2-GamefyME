from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError, transaction
from django.contrib.auth.hashers import make_password
from .models import Usuario, TipoUsuario

class CadastroUsuarioAPI(APIView):
    def post(self, request):
        data = request.data
        nome = data.get('nmusuario')
        email = data.get('emailusuario')
        senha = data.get('senha')
        confsenha = data.get('confsenha')
        dt_nascimento = data.get('dtnascimento')

        if not all([nome, email, senha, confsenha, dt_nascimento]):
            return Response({"erro": "Preencha todos os campos."}, status=status.HTTP_400_BAD_REQUEST)

        if senha != confsenha:
            return Response({"erro": "Senhas não coincidem."}, status=status.HTTP_400_BAD_REQUEST)

        if Usuario.objects.filter(emailusuario=email).exists():
            return Response({"erro": "Já existe um usuário com esse e-mail cadastrado."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                usuario = Usuario(
                    nmusuario=nome,
                    emailusuario=email,
                    password=make_password(senha),
                    dtnascimento=dt_nascimento,
                    flsituacao=True,
                    nivelusuario=1,
                    expusuario=0,
                    tipousuario=TipoUsuario.COMUM
                )
                usuario.save()

                return Response(
                    {"mensagem": "Usuário cadastrado com sucesso!"},
                    status=status.HTTP_201_CREATED
                )

        except IntegrityError:
            return Response(
                {"erro": "Erro de integridade ao salvar. Verifique os dados e tente novamente."},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            return Response({"erro": f"Erro ao realizar cadastro: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)