from django.db import transaction
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from datetime import timedelta, datetime, time
from .models import Atividade, AtividadeConcluidas
from desafios.models import Desafio, UsuarioDesafio
from django.db.models import Q
from conquistas.models import Conquista, UsuarioConquista, TipoRegraConquista
from notificacoes.services import criar_notificacao

# Helper para XP / level up centralizado
def adicionar_xp(usuario, xp):
    """
    Adiciona XP ao usuário e realiza level-up se necessário.
    Retorna tupla (nivel_anterior, nivel_atual).
    """
    if not xp:
        return usuario.nivelusuario, usuario.nivelusuario

    nivel_anterior = usuario.nivelusuario
    usuario.expusuario = (usuario.expusuario or 0) + xp

    # Normalize caso expusuario seja None
    if usuario.expusuario is None:
        usuario.expusuario = xp

    # Faz o level up enquanto necessario (1000 por level)
    while usuario.expusuario >= 1000:
        usuario.expusuario -= 1000
        usuario.nivelusuario = (usuario.nivelusuario or 0) + 1

    usuario.save()
    nivel_atual = usuario.nivelusuario

    if nivel_atual > nivel_anterior:
        criar_notificacao(usuario, f'🎉 Incrível! Você alcançou o nível {nivel_atual}!', 'sucesso')

    return nivel_anterior, nivel_atual

# --- GATILHOS (SIGNALS) ---

@receiver(post_save, sender=AtividadeConcluidas, dispatch_uid='on_atividade_concluida_signal')
def on_atividade_concluida(sender, instance, created, **kwargs):
    """
    Gatilho para quando uma ATIVIDADE É CONCLUÍDA.
    """
    if not created:
        return

    usuario = instance.idusuario
    atividade = instance.idatividade
    exp_ganha = getattr(atividade, 'expatividade', 0)

    # Notificação de conclusão de atividade
    criar_notificacao(
        usuario,
        f'Parabéns! Você completou a atividade "{getattr(atividade, "nmatividade", "")}" e ganhou {exp_ganha} XP!',
        'sucesso'
    )

    # Aplique XP da atividade (centralizado)
    adicionar_xp(usuario, exp_ganha)

    # Chama as verificações dentro de transação para evitar estados parciais
    with transaction.atomic():
        _verificar_e_premiar_desafios(usuario)
        _verificar_e_premiar_conquistas(usuario)

@receiver(post_save, sender=Atividade, dispatch_uid='on_atividade_criada_signal')
def on_atividade_criada(sender, instance, created, **kwargs):
    """
    Gatilho para quando uma NOVA ATIVIDADE É CRIADA.
    """
    if not created:
        return

    usuario = instance.idusuario
    # Verificações em transação
    with transaction.atomic():
        _verificar_e_premiar_desafios(usuario)
        _verificar_e_premiar_conquistas(usuario)

# --- VERIFICAÇÃO DE DESAFIOS ---
def _verificar_e_premiar_desafios(usuario):
    agora = timezone.now()
    hoje = agora.date()
    # Todos os desafios podem ter janela dtinicio/dtfim opcional.
    # Se dtinicio/dtfim estiverem definidos, só validar dentro da janela.
    # Se não estiverem definidos, validar sempre (exceto únicos que precisam obrigatoriamente).
    desafios_ativos = Desafio.objects.filter(Q(dtinicio__isnull=True, dtfim__isnull=True) | Q(dtinicio__lte=agora, dtfim__gte=agora))

    logicas = {
        'recorrentes_concluidas': verificar_recorrentes_concluidas,
        'atividades_concluidas': verificar_atividades_concluidas,
        'desafios_concluidos': verificar_desafios_concluidos,
        'atividades_criadas': verificar_atividades_criadas,
        'min_dificeis': verificar_min_dificeis,
        'min_atividades_por_dificuldade': verificar_min_atividades_media_facil,
        'todas_muito_faceis': verificar_todas_muito_faceis,
        'streak_diario': verificar_streak_diario,
        'percentual_concluido': verificar_percentual_concluido,
    }

    for desafio in desafios_ativos:
        if _ja_premiado_no_ciclo(usuario, desafio, hoje):
            continue

        funcao_verificacao = logicas.get(desafio.tipo_logica)
        if funcao_verificacao and funcao_verificacao(usuario, desafio):
            # Cria premiação
            UsuarioDesafio.objects.create(
                idusuario=usuario, iddesafio=desafio, flsituacao=True, dtpremiacao=agora
            )

            # Notifica e aplica XP com level-up centralizado
            criar_notificacao(
                usuario,
                f'Desafio Cumprido: "{getattr(desafio, "nmdesafio", "")}"! Você ganhou {getattr(desafio, "expdesafio", 0)} XP!',
                'sucesso'
            )
            adicionar_xp(usuario, getattr(desafio, 'expdesafio', 0))

# --- VERIFICAÇÃO DE CONQUISTAS ---
def _verificar_e_premiar_conquistas(usuario):
    """
    Conquistas são marcos permanentes. Avaliamos sempre no histórico completo
    do usuário, sem janelas de período.
    """
    conquistas_nao_obtidas = Conquista.objects.exclude(usuarioconquista__idusuario=usuario)

    for conquista in conquistas_nao_obtidas:
        atingiu_criterio = False

        regra = getattr(conquista, 'regra', None)
        parametro = getattr(conquista, 'parametro', 1) or 1

        # Avaliação genérica com base na regra (sem períodos)
        if regra == TipoRegraConquista.ATIVIDADES_CONCLUIDAS_TOTAL:
            qs = AtividadeConcluidas.objects.filter(idusuario=usuario)
            atingiu_criterio = qs.count() >= parametro

        elif regra == TipoRegraConquista.RECORRENTES_CONCLUIDAS_TOTAL:
            qs = AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__recorrencia='recorrente')
            atingiu_criterio = qs.count() >= parametro

        elif regra == TipoRegraConquista.DIFICULDADE_CONCLUIDAS_TOTAL:
            dificuldade = getattr(conquista, 'dificuldade_alvo', None)
            if dificuldade:
                qs = AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__dificuldade=dificuldade)
                atingiu_criterio = qs.count() >= parametro

        elif regra == TipoRegraConquista.DESAFIOS_CONCLUIDOS_TOTAL:
            qs = UsuarioDesafio.objects.filter(idusuario=usuario)
            atingiu_criterio = qs.count() >= parametro

        elif regra == TipoRegraConquista.DESAFIOS_CONCLUIDOS_POR_TIPO:
            tipo_alvo = getattr(conquista, 'tipo_desafio_alvo', None)
            if tipo_alvo:
                qs = UsuarioDesafio.objects.filter(idusuario=usuario, iddesafio__tipo=tipo_alvo)
                atingiu_criterio = qs.count() >= parametro

        elif regra == TipoRegraConquista.STREAK_CONCLUSAO:
            atingiu_criterio = calcular_streak_conclusao(usuario) >= parametro

        elif regra == TipoRegraConquista.STREAK_CRIACAO:
            atingiu_criterio = calcular_streak_criacao_atividades(usuario) >= parametro

        elif regra == TipoRegraConquista.POMODORO_CONCLUIDAS_TOTAL:
            minutos = getattr(conquista, 'pomodoro_minutos', 60) or 60
            qs = AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__tpestimado__gte=minutos)
            atingiu_criterio = qs.count() >= parametro

        # Se atingiu o critério, concede a conquista
        if atingiu_criterio:
            UsuarioConquista.objects.create(idusuario=usuario, idconquista=conquista)
            criar_notificacao(
                usuario,
                f'Conquista Desbloqueada: "{getattr(conquista, "nmconquista", "")}"! Você ganhou {getattr(conquista, "expconquista", 0)} XP!',
                'sucesso'
            )
            adicionar_xp(usuario, getattr(conquista, 'expconquista', 0))

# --- FUNÇÕES DE LÓGICA (DESAFIOS) ---
def get_date_range(periodo):
    """Mantida para compatibilidade com desafios e outras partes. Conquistas não usam mais período."""
    hoje = timezone.now().date()
    if periodo == 'diario':
        return hoje, hoje
    elif periodo == 'semanal':
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        fim_semana = inicio_semana + timedelta(days=6)
        return inicio_semana, fim_semana
    elif periodo == 'mensal':
        primeiro_dia_mes = hoje.replace(day=1)
        if primeiro_dia_mes.month == 12:
            proximo_mes = primeiro_dia_mes.replace(year=primeiro_dia_mes.year + 1, month=1)
        else:
            proximo_mes = primeiro_dia_mes.replace(month=primeiro_dia_mes.month + 1)
        ultimo_dia_mes = proximo_mes - timedelta(days=1)
        return primeiro_dia_mes, ultimo_dia_mes
    return None, None

def get_datetime_range(periodo):
    """Retorna um intervalo de datetimes AWARE (inicio_dt, fim_dt) baseado no timezone atual.

    Em vez de converter a partir de datas (que podem ser ingênuas), calculamos
    os limites diretamente a partir do "agora" já com fuso horário (localtime),
    garantindo consistência em bancos diferentes (SQLite/PostgreSQL) e evitando
    discrepâncias por DST.
    """
    agora = timezone.localtime()

    def start_of_day(dt: datetime) -> datetime:
        return dt.replace(hour=0, minute=0, second=0, microsecond=0)

    def end_of_day(dt: datetime) -> datetime:
        return dt.replace(hour=23, minute=59, second=59, microsecond=999999)

    if periodo == 'diario':
        inicio_dt = start_of_day(agora)
        fim_dt = end_of_day(agora)
        return inicio_dt, fim_dt

    elif periodo == 'semanal':
        # Monday as start of week
        delta = timedelta(days=agora.weekday())
        inicio_semana = start_of_day(agora - delta)
        fim_semana = end_of_day(inicio_semana + timedelta(days=6))
        return inicio_semana, fim_semana

    elif periodo == 'mensal':
        primeiro_dia = agora.replace(day=1)
        # Próximo mês
        if primeiro_dia.month == 12:
            proximo_mes = primeiro_dia.replace(year=primeiro_dia.year + 1, month=1)
        else:
            proximo_mes = primeiro_dia.replace(month=primeiro_dia.month + 1)
        ultimo_dia = proximo_mes - timedelta(days=1)
        inicio_mes = start_of_day(primeiro_dia)
        fim_mes = end_of_day(ultimo_dia)
        return inicio_mes, fim_mes

    return None, None

# (o resto das funções verificar_* mantém a mesma lógica, mas é recomendável checar inicio/fim != (None, None) antes de usá-las)
# ... (mantém verificar_atividades_concluidas, verificar_recorrentes_concluidas, etc., inalteradas)
# lembre-se de manter as funções auxiliares abaixo exatamente como tinha, ou adapte pequenas guardas de None.

def verificar_atividades_concluidas(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    return AtividadeConcluidas.objects.filter(idusuario=usuario, dtconclusao__range=[inicio_dt, fim_dt]).count() >= desafio.parametro

def verificar_recorrentes_concluidas(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    return AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__recorrencia='recorrente', dtconclusao__range=[inicio_dt, fim_dt]).count() >= desafio.parametro

def verificar_min_dificeis(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    return AtividadeConcluidas.objects.filter(
        idusuario=usuario,
        idatividade__dificuldade__in=['dificil', 'muito_dificil'],
        dtconclusao__range=[inicio_dt, fim_dt]
    ).values('idatividade').distinct().count() >= desafio.parametro

def verificar_desafios_concluidos(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    # +1 pois estamos verificando ANTES de registrar o desafio atual
    return (UsuarioDesafio.objects.filter(idusuario=usuario, dtpremiacao__range=[inicio_dt, fim_dt]).count() + 1) >= desafio.parametro

def verificar_atividades_criadas(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    return Atividade.objects.filter(idusuario=usuario, dtatividade__range=[inicio_dt, fim_dt]).count() >= desafio.parametro

def verificar_min_atividades_media_facil(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    return AtividadeConcluidas.objects.filter(
        idusuario=usuario,
        idatividade__dificuldade__in=['medio', 'facil', 'muito_facil'],
        dtconclusao__range=[inicio_dt, fim_dt]
    ).count() >= desafio.parametro

def verificar_todas_muito_faceis(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    atividades_do_dia = Atividade.objects.filter(idusuario=usuario, dificuldade='muito_facil', dtatividade__range=[inicio_dt, fim_dt])
    if not atividades_do_dia.exists():
        return False
    concluidas_do_dia = AtividadeConcluidas.objects.filter(
        idusuario=usuario, idatividade__in=atividades_do_dia
    ).values('idatividade').distinct().count()
    return atividades_do_dia.count() == concluidas_do_dia

def verificar_streak_diario(usuario, desafio):
    return calcular_streak_conclusao(usuario) >= desafio.parametro

def verificar_percentual_concluido(usuario, desafio):
    inicio_dt, fim_dt = get_datetime_range(desafio.tipo)
    if inicio_dt is None:
        return False
    total_atividades = Atividade.objects.filter(idusuario=usuario, dtatividade__range=[inicio_dt, fim_dt]).count()
    if total_atividades == 0:
        return False
    concluidas = AtividadeConcluidas.objects.filter(idusuario=usuario, dtconclusao__range=[inicio_dt, fim_dt]).count()
    return (concluidas / total_atividades) * 100 >= desafio.parametro

# --- FUNÇÕES AUXILIARES (mantidas) ---
def _ja_premiado_no_ciclo(usuario, desafio, hoje):
    premiacao_existente = UsuarioDesafio.objects.filter(idusuario=usuario, iddesafio=desafio)
    if desafio.tipo == 'diario':
        return premiacao_existente.filter(dtpremiacao__date=hoje).exists()
    elif desafio.tipo == 'semanal':
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        return premiacao_existente.filter(dtpremiacao__date__gte=inicio_semana).exists()
    elif desafio.tipo == 'mensal':
        return premiacao_existente.filter(dtpremiacao__year=hoje.year, dtpremiacao__month=hoje.month).exists()
    return premiacao_existente.exists()

def calcular_streak_conclusao(usuario):
    hoje = timezone.now().date()
    datas_conclusao = sorted(AtividadeConcluidas.objects.filter(idusuario=usuario).values_list('dtconclusao__date', flat=True).distinct(), reverse=True)
    if not datas_conclusao or datas_conclusao[0] < hoje - timedelta(days=1):
        return 0

    streak = 0
    dia_esperado = datas_conclusao[0]
    for data in datas_conclusao:
        if data == dia_esperado:
            streak += 1
            dia_esperado -= timedelta(days=1)
        else:
            break
    return streak

def calcular_streak_criacao_atividades(usuario):
    hoje = timezone.now().date()
    datas_criacao = sorted(Atividade.objects.filter(idusuario=usuario).values_list('dtatividade__date', flat=True).distinct(), reverse=True)
    if not datas_criacao or datas_criacao[0] < hoje - timedelta(days=1):
        return 0

    streak = 0
    dia_esperado = datas_criacao[0]
    for data in datas_criacao:
        if data == dia_esperado:
            streak += 1
            dia_esperado -= timedelta(days=1)
        else:
            break
    return streak
