from django.db import transaction
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from datetime import timedelta
from .models import Atividade, AtividadeConcluidas
from desafios.models import Desafio, UsuarioDesafio
from conquistas.models import Conquista, UsuarioConquista
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
    desafios_ativos = Desafio.objects.filter(dtinicio__lte=agora, dtfim__gte=agora)

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
    conquistas_nao_obtidas = Conquista.objects.exclude(usuarioconquista__idusuario=usuario)

    for conquista in conquistas_nao_obtidas:
        atingiu_criterio = False
        nome_conquista = (conquista.nmconquista or "").upper()

        # Mapeamento da lógica de conquistas
        if nome_conquista == "ATIVIDADE CUMPRIDA":
            atingiu_criterio = AtividadeConcluidas.objects.filter(idusuario=usuario).count() >= 1
        elif nome_conquista == "PRODUTIVIDADE EM ALTA":
            atingiu_criterio = AtividadeConcluidas.objects.filter(idusuario=usuario).count() >= 10
        elif nome_conquista == "RECORRÊNCIA - DE NOVO!":
            atingiu_criterio = AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__recorrencia='recorrente').count() >= 5
        elif nome_conquista == "USUÁRIO HARDCORE":
            atingiu_criterio = AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__dificuldade='muito_dificil').count() >= 5
        elif nome_conquista == "DESAFIANTE AMADOR":
            atingiu_criterio = UsuarioDesafio.objects.filter(idusuario=usuario).count() >= 1
        elif nome_conquista == "CAMPEÃO SEMANAL":
            desafios_semanais_vencidos = UsuarioDesafio.objects.filter(idusuario=usuario, iddesafio__tipo='semanal').values('iddesafio').distinct().count()
            total_desafios_semanais = Desafio.objects.filter(tipo='semanal', dtinicio__lte=timezone.now(), dtfim__gte=timezone.now()).count()
            atingiu_criterio = total_desafios_semanais > 0 and desafios_semanais_vencidos == total_desafios_semanais
        elif nome_conquista == "MISSÃO CUMPRIDA":
            atingiu_criterio = UsuarioDesafio.objects.filter(idusuario=usuario, iddesafio__tipo='mensal').exists()
        elif nome_conquista == "DESAFIANTE MESTRE":
            atingiu_criterio = UsuarioDesafio.objects.filter(idusuario=usuario).count() >= 50
        elif nome_conquista == "UM DIA APÓS O OUTRO":
            atingiu_criterio = calcular_streak_conclusao(usuario) >= 5
        elif nome_conquista == "RITUAL SEMANAL":
            atingiu_criterio = calcular_streak_criacao_atividades(usuario) >= 7
        elif nome_conquista == "CONSISTÊNCIA INABALÁVEL":
            atingiu_criterio = calcular_streak_conclusao(usuario) >= 15

        # --- Conquistas baseadas em Pomodoro (atividades longas >= 60 min) ---
        elif nome_conquista == "POMODORO INICIANTE":
            pomodoro_count = AtividadeConcluidas.objects.filter(
                idusuario=usuario,
                idatividade__tpestimado__gte=60
            ).count()
            atingiu_criterio = pomodoro_count >= 1
        elif nome_conquista == "POMODORO DEDICADO":
            pomodoro_count = AtividadeConcluidas.objects.filter(
                idusuario=usuario,
                idatividade__tpestimado__gte=60
            ).count()
            atingiu_criterio = pomodoro_count >= 5
        elif nome_conquista == "POMODORO MESTRE":
            pomodoro_count = AtividadeConcluidas.objects.filter(
                idusuario=usuario,
                idatividade__tpestimado__gte=60
            ).count()
            atingiu_criterio = pomodoro_count >= 20

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
    hoje = timezone.now().date()
    if periodo == 'diario':
        return hoje, hoje
    elif periodo == 'semanal':
        inicio_semana = hoje - timedelta(days=hoje.weekday())
        fim_semana = inicio_semana + timedelta(days=6)
        return inicio_semana, fim_semana
    elif periodo == 'mensal':
        primeiro_dia_mes = hoje.replace(day=1)
        # calcula ultimo dia do mês
        if primeiro_dia_mes.month == 12:
            proximo_mes = primeiro_dia_mes.replace(year=primeiro_dia_mes.year + 1, month=1)
        else:
            proximo_mes = primeiro_dia_mes.replace(month=primeiro_dia_mes.month + 1)
        ultimo_dia_mes = proximo_mes - timedelta(days=1)
        return primeiro_dia_mes, ultimo_dia_mes
    # Retorna None para sinalizar uso incorreto
    return None, None

# (o resto das funções verificar_* mantém a mesma lógica, mas é recomendável checar inicio/fim != (None, None) antes de usá-las)
# ... (mantém verificar_atividades_concluidas, verificar_recorrentes_concluidas, etc., inalteradas)
# lembre-se de manter as funções auxiliares abaixo exatamente como tinha, ou adapte pequenas guardas de None.

def verificar_atividades_concluidas(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    return AtividadeConcluidas.objects.filter(idusuario=usuario, dtconclusao__date__range=[inicio, fim]).count() >= desafio.parametro

def verificar_recorrentes_concluidas(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    return AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__recorrencia='recorrente', dtconclusao__date__range=[inicio, fim]).count() >= desafio.parametro

def verificar_min_dificeis(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    return AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__dificuldade__in=['dificil', 'muito_dificil'], dtconclusao__date__range=[inicio, fim]).values('idatividade').distinct().count() >= desafio.parametro

def verificar_desafios_concluidos(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    # +1 pois estamos verificando ANTES de registrar o desafio atual
    return (UsuarioDesafio.objects.filter(idusuario=usuario, dtpremiacao__date__range=[inicio, fim]).count() + 1) >= desafio.parametro

def verificar_atividades_criadas(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    return Atividade.objects.filter(idusuario=usuario, dtatividade__date__range=[inicio, fim]).count() >= desafio.parametro

def verificar_min_atividades_media_facil(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    return AtividadeConcluidas.objects.filter(idusuario=usuario, idatividade__dificuldade__in=['medio', 'facil', 'muito_facil'], dtconclusao__date__range=[inicio, fim]).count() >= desafio.parametro

def verificar_todas_muito_faceis(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    atividades_do_dia = Atividade.objects.filter(idusuario=usuario, dificuldade='muito_facil', dtatividade__date__range=[inicio, fim])
    if not atividades_do_dia.exists():
        return False
    concluidas_do_dia = AtividadeConcluidas.objects.filter(
        idusuario=usuario, idatividade__in=atividades_do_dia
    ).values('idatividade').distinct().count()
    return atividades_do_dia.count() == concluidas_do_dia

def verificar_streak_diario(usuario, desafio):
    return calcular_streak_conclusao(usuario) >= desafio.parametro

def verificar_percentual_concluido(usuario, desafio):
    inicio, fim = get_date_range(desafio.tipo)
    if inicio is None:
        return False
    total_atividades = Atividade.objects.filter(idusuario=usuario, dtatividade__date__range=[inicio, fim]).count()
    if total_atividades == 0:
        return False
    concluidas = AtividadeConcluidas.objects.filter(idusuario=usuario, dtconclusao__date__range=[inicio, fim]).count()
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
