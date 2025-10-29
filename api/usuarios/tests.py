from django.test import TestCase
from rest_framework.test import APIClient
from django.core.cache import cache
from django.urls import reverse
from .models import Usuario


class ContaInativaTests(TestCase):
	def setUp(self):
		self.client = APIClient()
		self.email = 'teste@example.com'
		# Cria usuário inativo
		self.user = Usuario.objects.create_user(
			emailusuario=self.email,
			senha='Senha@123',
			nmusuario='Teste'
		)
		self.user.flsituacao = False
		self.user.is_active = False
		self.user.save(update_fields=["flsituacao", "is_active"])

	def test_login_bloqueado_para_inativo(self):
		url = reverse('login')
		resp = self.client.post(url, {
			'emailusuario': self.email,
			'password': 'Senha@123'
		}, format='json')
		self.assertEqual(resp.status_code, 403)
		self.assertIn('inativa', resp.data.get('erro', '').lower())

	def test_reset_senha_reativa_conta(self):
		# Prepara código no cache como se tivesse sido enviado por email
		code = '123456'
		cache.set(f'reset_code_{self.email}', code, timeout=600)

		url = reverse('password-reset-confirm')
		resp = self.client.post(url, {
			'email': self.email,
			'token': code,
			'new_password': 'NovaSenha@123',
			'confirm_password': 'NovaSenha@123'
		}, format='json')
		self.assertEqual(resp.status_code, 200)

		# Recarrega usuário e verifica reativação
		self.user.refresh_from_db()
		self.assertTrue(self.user.flsituacao)
		self.assertTrue(self.user.is_active)
