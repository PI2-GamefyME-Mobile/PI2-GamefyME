from django.db import models
from usuarios.models import Usuario
from django.conf import settings


class TipoRegraConquista(models.TextChoices):
    ATIVIDADES_CONCLUIDAS_TOTAL = 'atividades_concluidas_total', 'Atividades concluídas (total)'
    RECORRENTES_CONCLUIDAS_TOTAL = 'recorrentes_concluidas_total', 'Atividades recorrentes concluídas (total)'
    DIFICULDADE_CONCLUIDAS_TOTAL = 'dificuldade_concluidas_total', 'Atividades concluídas por dificuldade (total)'
    DESAFIOS_CONCLUIDOS_TOTAL = 'desafios_concluidos_total', 'Desafios concluídos (total)'
    DESAFIOS_CONCLUIDOS_POR_TIPO = 'desafios_concluidos_por_tipo', 'Desafios concluídos por tipo'
    STREAK_CONCLUSAO = 'streak_conclusao', 'Streak de conclusão de atividades'
    STREAK_CRIACAO = 'streak_criacao', 'Streak de criação de atividades'
    POMODORO_CONCLUIDAS_TOTAL = 'pomodoro_concluidas_total', 'Atividades (>= min) concluídas (total)'


class PeriodoConquista(models.TextChoices):
    DIARIO = 'diario', 'Diário'
    SEMANAL = 'semanal', 'Semanal'
    MENSAL = 'mensal', 'Mensal'

class Conquista(models.Model):
    idconquista = models.AutoField(primary_key=True)
    nmconquista = models.CharField(max_length=100)
    dsconquista = models.TextField()
    nmimagem = models.CharField(max_length=255, blank=True, null=True)
    expconquista = models.SmallIntegerField(default=0)
    # Regras dinâmicas
    regra = models.CharField(max_length=50, choices=TipoRegraConquista.choices, null=True, blank=True)
    parametro = models.SmallIntegerField(default=1)
    periodo = models.CharField(max_length=10, choices=PeriodoConquista.choices, null=True, blank=True)
    # Campos auxiliares (usados dependendo da regra)
    dificuldade_alvo = models.CharField(max_length=20, null=True, blank=True)
    tipo_desafio_alvo = models.CharField(max_length=10, null=True, blank=True)
    pomodoro_minutos = models.SmallIntegerField(default=60)

    class Meta:
        db_table = 'conquistas'

    def __str__(self):
        return self.nmconquista
    
    def get_imagem_url(self, request=None):
        """Retorna a URL completa da imagem"""
        if not self.nmimagem:
            return None
        
        # Se já é uma URL completa, retornar como está
        if self.nmimagem.startswith('http'):
            return self.nmimagem
        
        # Construir URL baseada no MEDIA_URL
        imagem_path = self.nmimagem
        if not imagem_path.startswith('/'):
            imagem_path = f'{settings.MEDIA_URL}{imagem_path}'
        
        if request:
            return request.build_absolute_uri(imagem_path)
        
        return imagem_path

class UsuarioConquista(models.Model):
    idusuarioconquista = models.AutoField(primary_key=True)
    idusuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, db_column='idusuario')
    idconquista = models.ForeignKey(Conquista, on_delete=models.CASCADE, db_column='idconquista')
    dtconcessao = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'usuario_conquistas'
        unique_together = ('idusuario', 'idconquista')

    def __str__(self):
        return f"{self.idusuario.nmusuario} - {self.idconquista.nmconquista}"