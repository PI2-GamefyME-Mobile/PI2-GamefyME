from django.test import TestCase, override_settings
from rest_framework.test import APIClient
from usuarios.models import Usuario, TipoUsuario
from .models import Conquista


SQLITE_TEST_DB = {
	'default': {
		'ENGINE': 'django.db.backends.sqlite3',
		'NAME': ':memory:',
	}
}


@override_settings(DATABASES=SQLITE_TEST_DB)
class AdminPermissaoConquistasTests(TestCase):
	def setUp(self):
		self.client = APIClient()
		self.url_admin_list = '/api/conquistas/admin/'

		self.user_admin = Usuario.objects.create_user(
			emailusuario='admin2@example.com',
			senha='Senha@123',
			nmusuario='Admin2',
			tipousuario=TipoUsuario.ADMIN,
			is_staff=True
		)
		self.user_comum = Usuario.objects.create_user(
			emailusuario='user2@example.com',
			senha='Senha@123',
			nmusuario='User2',
			tipousuario=TipoUsuario.COMUM
		)

	def test_admin_pode_listar_conquistas(self):
		self.client.force_authenticate(user=self.user_admin)
		resp = self.client.get(self.url_admin_list)
		self.assertNotIn(resp.status_code, [401, 403], f"Esperado acesso permitido, obtido {resp.status_code} - {resp.content}")

	def test_usuario_comum_nao_pode_listar_conquistas_admin(self):
		self.client.force_authenticate(user=self.user_comum)
		resp = self.client.get(self.url_admin_list)
		self.assertEqual(resp.status_code, 403)


@override_settings(DATABASES=SQLITE_TEST_DB)
class ConquistaListagemTests(TestCase):
	def setUp(self):
		self.client = APIClient()
		self.url_public_list = '/api/conquistas/'
		self.user = Usuario.objects.create_user(
			emailusuario='user3@example.com',
			senha='Senha@123',
			nmusuario='User3',
			tipousuario=TipoUsuario.COMUM
		)

	def test_listagem_conquistas_sem_historico(self):
		Conquista.objects.create(
			nmconquista='Primeira',
			dsconquista='Primeira conquista',
			nmimagem='medalha.png',
			expconquista=10,
		)
		self.client.force_authenticate(user=self.user)
		resp = self.client.get(self.url_public_list)
		self.assertEqual(resp.status_code, 200)
		data = resp.json()
		self.assertGreaterEqual(len(data), 1)
		primeira = next((c for c in data if c['nmconquista'] == 'Primeira'), None)
		self.assertIsNotNone(primeira)
		# Não completada por padrão
		self.assertFalse(primeira['completada'])
		# Imagem deve apontar para /media/conquistas/<arquivo>
		self.assertIn('/media/conquistas/medalha.png', primeira['imagem_url'])


@override_settings(DATABASES=SQLITE_TEST_DB)
class PremiacoesSignalsTests(TestCase):
	def setUp(self):
		# Garante que os signals estão carregados
		import atividades.signals  # noqa: F401
		from atividades.models import Atividade
		from desafios.models import Desafio, TipoDesafio
		from conquistas.models import Conquista, TipoRegraConquista
		from django.utils import timezone

		self.Atividade = Atividade
		self.Desafio = Desafio
		self.TipoDesafio = TipoDesafio
		self.Conquista = Conquista
		self.TipoRegraConquista = TipoRegraConquista
		self.now = timezone.now()

		self.user = Usuario.objects.create_user(
			emailusuario='user-sinal@example.com',
			senha='Senha@123',
			nmusuario='UserSignal',
			tipousuario=TipoUsuario.COMUM
		)

		# Desafio ativo e conquista que serão atingidos com 1 conclusão
		self.desafio = self.Desafio.objects.create(
			nmdesafio='1 conclusão hoje',
			dsdesafio='Teste sinal',
			tipo=self.TipoDesafio.DIARIO,
			expdesafio=15,
			tipo_logica='atividades_concluidas',
			parametro=1,
		)
		self.conquista = self.Conquista.objects.create(
			nmconquista='Primeiro passo',
			dsconquista='Concluir 1 atividade',
			expconquista=10,
			regra=self.TipoRegraConquista.ATIVIDADES_CONCLUIDAS_TOTAL,
			parametro=1,
		)

	def test_conclusao_atividade_dispara_premios(self):
		from atividades.models import AtividadeConcluidas
		from desafios.models import UsuarioDesafio
		from conquistas.models import UsuarioConquista

		a = self.Atividade.objects.create(
			idusuario=self.user,
			nmatividade='A-sinal',
			dsatividade='',
			dificuldade='facil',
			situacao='ativa',
			recorrencia='unica',
			dtatividade=self.now,
			tpestimado=25,
			expatividade=5,
		)
		# Criar conclusão dispara o signal
		AtividadeConcluidas.objects.create(
			idusuario=self.user,
			idatividade=a,
			dtconclusao=self.now,
		)

		self.assertTrue(UsuarioDesafio.objects.filter(idusuario=self.user, iddesafio=self.desafio).exists())
		self.assertTrue(UsuarioConquista.objects.filter(idusuario=self.user, idconquista=self.conquista).exists())
