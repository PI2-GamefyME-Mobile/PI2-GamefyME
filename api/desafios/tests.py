from django.test import TestCase, override_settings
from rest_framework.test import APIClient
from usuarios.models import Usuario, TipoUsuario
from django.utils import timezone
from datetime import timedelta
from .models import Desafio, TipoDesafio


SQLITE_TEST_DB = {
	'default': {
		'ENGINE': 'django.db.backends.sqlite3',
		'NAME': ':memory:',
	}
}


@override_settings(DATABASES=SQLITE_TEST_DB)
class AdminPermissaoDesafiosTests(TestCase):
	def setUp(self):
		self.client = APIClient()
		self.url_admin_list = '/api/desafios/admin/'

		self.user_admin = Usuario.objects.create_user(
			emailusuario='admin@example.com',
			senha='Senha@123',
			nmusuario='Admin',
			tipousuario=TipoUsuario.ADMIN,
			is_staff=True
		)
		self.user_comum = Usuario.objects.create_user(
			emailusuario='user@example.com',
			senha='Senha@123',
			nmusuario='User',
			tipousuario=TipoUsuario.COMUM
		)

	def test_admin_pode_listar_desafios(self):
		self.client.force_authenticate(user=self.user_admin)
		resp = self.client.get(self.url_admin_list)
		self.assertNotIn(resp.status_code, [401, 403], f"Esperado acesso permitido, obtido {resp.status_code} - {resp.content}")

	def test_usuario_comum_nao_pode_listar_desafios_admin(self):
		self.client.force_authenticate(user=self.user_comum)
		resp = self.client.get(self.url_admin_list)
		self.assertEqual(resp.status_code, 403)


@override_settings(DATABASES=SQLITE_TEST_DB)
class DesafioListagemAtivosTests(TestCase):
	def setUp(self):
		self.client = APIClient()
		self.url_public_list = '/api/desafios/'

		self.user = Usuario.objects.create_user(
			emailusuario='user3@example.com',
			senha='Senha@123',
			nmusuario='User3',
			tipousuario=TipoUsuario.COMUM
		)

	def test_listagem_retorna_apenas_ativos(self):
		agora = timezone.now()
		# Desafio único ATIVO (janela atual)
		Desafio.objects.create(
			nmdesafio='Unico Ativo',
			dsdesafio='Janela atual',
			tipo=TipoDesafio.UNICO,
			dtinicio=agora - timedelta(days=1),
			dtfim=agora + timedelta(days=1),
			expdesafio=100,
			tipo_logica='atividades_concluidas',
			parametro=1,
		)
		# Desafio único INATIVO (fora da janela)
		Desafio.objects.create(
			nmdesafio='Unico Inativo',
			dsdesafio='Janela passada',
			tipo=TipoDesafio.UNICO,
			dtinicio=agora - timedelta(days=10),
			dtfim=agora - timedelta(days=5),
			expdesafio=100,
			tipo_logica='atividades_concluidas',
			parametro=1,
		)
		# Desafio diário sem janela (sempre ativo)
		Desafio.objects.create(
			nmdesafio='Diario Sempre',
			dsdesafio='Sem janela',
			tipo=TipoDesafio.DIARIO,
			dtinicio=None,
			dtfim=None,
			expdesafio=50,
			tipo_logica='atividades_concluidas',
			parametro=1,
		)

		self.client.force_authenticate(user=self.user)
		resp = self.client.get(self.url_public_list)
		self.assertEqual(resp.status_code, 200)
		data = resp.json()
		# Esperamos 2 ativos: 'Unico Ativo' e 'Diario Sempre'
		nomes = [d['nmdesafio'] for d in data]
		self.assertIn('Unico Ativo', nomes)
		self.assertIn('Diario Sempre', nomes)
		self.assertNotIn('Unico Inativo', nomes)


@override_settings(DATABASES=SQLITE_TEST_DB)
class DesafioProgressoTests(TestCase):
	def setUp(self):
		from atividades.models import Atividade, AtividadeConcluidas
		self.Atividade = Atividade
		self.AtividadeConcluidas = AtividadeConcluidas
		self.user = Usuario.objects.create_user(
			emailusuario='user4@example.com',
			senha='Senha@123',
			nmusuario='User4',
			tipousuario=TipoUsuario.COMUM
		)

		self.desafio = Desafio.objects.create(
			nmdesafio='Complete 5 hoje',
			dsdesafio='Metas do dia',
			tipo=TipoDesafio.DIARIO,
			expdesafio=20,
			tipo_logica='atividades_criadas',
			parametro=5,
		)

		agora = timezone.now()
		for i in range(3):
			a = self.Atividade.objects.create(
				idusuario=self.user,
				nmatividade=f'A{i}',
				dsatividade='',
				dificuldade='facil',
				situacao='ativa',
				recorrencia='unica',
				dtatividade=agora,
				tpestimado=25,
				expatividade=5,
			)
			self.AtividadeConcluidas.objects.create(
				idusuario=self.user,
				idatividade=a,
				dtconclusao=agora,
			)

	def test_progresso_diario_bate_meta_parcial(self):
		# Usa o endpoint real para garantir o mesmo caminho de execução da API
		client = APIClient()
		client.force_authenticate(user=self.user)
		resp = client.get('/api/desafios/')
		self.assertEqual(resp.status_code, 200)
		itens = resp.json()
		alvo = next((d for d in itens if d['iddesafio'] == self.desafio.iddesafio), None)
		self.assertIsNotNone(alvo)
		self.assertEqual(alvo['progresso'], 3)
		self.assertEqual(alvo['meta'], 5)
		self.assertFalse(alvo['completado'])
