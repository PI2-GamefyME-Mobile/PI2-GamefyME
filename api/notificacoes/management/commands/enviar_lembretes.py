from django.core.management.base import BaseCommand
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from usuarios.models import Usuario
from atividades.models import AtividadeConcluidas
from notificacoes.services import criar_notificacao

# TODO: Agendar este comando para rodar diariamente via cron ou serviço similar
class Command(BaseCommand):
    help = "Envia lembretes por e-mail para usuários que ainda não concluíram atividades hoje e registra notificação."

    def handle(self, *args, **options):
        hoje = timezone.now().date()
        enviados = 0
        for usuario in Usuario.objects.filter(flsituacao=True):
            concluiu_hoje = AtividadeConcluidas.objects.filter(
                idusuario=usuario,
                dtconclusao__date=hoje
            ).exists()
            if concluiu_hoje:
                continue

            criar_notificacao(
                usuario,
                'Lembrete: registre suas atividades de hoje para manter sua constância!',
                'aviso'
            )

            try:
                subject = 'Lembrete GamefyME: Registre seus hábitos hoje'
                message = (
                    f'Olá {usuario.nmusuario},\n\n'
                    'Não se esqueça de registrar suas atividades de hoje no GamefyME.\n'
                    'Manter a constância é essencial para suas conquistas e desafios!\n\n'
                    'Bons hábitos!\nEquipe GamefyME'
                )
                send_mail(subject, message, getattr(settings, 'EMAIL_HOST_USER', None), [usuario.emailusuario])
                enviados += 1
            except Exception:
                pass

        self.stdout.write(self.style.SUCCESS(f'Lembretes processados. E-mails enviados: {enviados}'))
