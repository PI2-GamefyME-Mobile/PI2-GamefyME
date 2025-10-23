from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db import transaction
from datetime import timedelta

from .models import Atividade, AtividadeConcluidas
from .serializers import AtividadeSerializer

class AtividadeViewSet(viewsets.ModelViewSet):
    serializer_class = AtividadeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Atividade.objects.filter(idusuario=user).exclude(situacao='cancelada')

        # Filtros por data (yyyy-mm-dd) opcionais
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        by = self.request.query_params.get('by', 'criacao')  # 'criacao' ou 'conclusao'

        try:
            if start_date:
                if by == 'conclusao':
                    qs = qs.filter(dtatividaderealizada__date__gte=start_date)
                else:
                    qs = qs.filter(dtatividade__date__gte=start_date)
            if end_date:
                if by == 'conclusao':
                    qs = qs.filter(dtatividaderealizada__date__lte=end_date)
                else:
                    qs = qs.filter(dtatividade__date__lte=end_date)
        except Exception:
            # Em caso de datas inválidas, retorna sem filtro adicional
            pass

        return qs

    def perform_create(self, serializer):
        validated_data = serializer.validated_data
        dificuldade = validated_data.get('dificuldade')
        tempo_estimado = validated_data.get('tpestimado')
        exp = calcular_experiencia(dificuldade, tempo_estimado)
        serializer.save(
            idusuario=self.request.user,
            expatividade=exp,
            situacao='ativa'
        )

    @action(detail=True, methods=['post'])
    def realizar(self, request, pk=None):
        atividade = self.get_object()
        usuario = request.user
        if atividade.situacao == 'cancelada' or \
           (atividade.situacao == 'realizada' and atividade.recorrencia == 'unica'):
            return Response(
                {'erro': 'Esta atividade não pode mais ser realizada.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            with transaction.atomic():
                if atividade.recorrencia == 'unica':
                    atividade.situacao = 'realizada'
                atividade.dtatividaderealizada = timezone.now()
                atividade.save()
                exp_ganha = atividade.expatividade
                AtividadeConcluidas.objects.create(
                    idusuario=usuario,
                    idatividade=atividade,
                    dtconclusao=timezone.now()
                )
                return Response({
                    'status': 'atividade realizada',
                    'exp_ganha': exp_ganha
                }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'erro': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def cancelar(self, request, pk=None):
        try:
            atividade = self.get_object()
            atividade.situacao = 'cancelada'
            atividade.save()
            return Response({'status': 'atividade cancelada'}, status=status.HTTP_200_OK)
        except Atividade.DoesNotExist:
            return Response({'erro': 'Atividade não encontrada'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'erro': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'], url_path='historico')
    def historico(self, request):
        """
        Retorna todas as atividades do usuário, incluindo as canceladas,
        para exibição no histórico.
        """
        user = request.user
        qs = Atividade.objects.filter(idusuario=user)

        # Filtros por data (yyyy-mm-dd) opcionais
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        by = self.request.query_params.get('by', 'criacao')  # 'criacao' ou 'conclusao'

        try:
            if start_date:
                if by == 'conclusao':
                    qs = qs.filter(dtatividaderealizada__date__gte=start_date)
                else:
                    qs = qs.filter(dtatividade__date__gte=start_date)
            if end_date:
                if by == 'conclusao':
                    qs = qs.filter(dtatividaderealizada__date__lte=end_date)
                else:
                    qs = qs.filter(dtatividade__date__lte=end_date)
        except Exception:
            pass

        # Ordena por data de realização (se existir) ou por data da atividade
        qs = qs.order_by('-dtatividaderealizada', '-dtatividade')
        
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='streak-status')
    def streak_status(self, request):
        usuario = request.user
        today = timezone.now().date()
        
        completed_dates = set(
            AtividadeConcluidas.objects.filter(idusuario=usuario)
            .values_list('dtconclusao__date', flat=True)
            .distinct()
        )

        # Condição de quebra de streak: se a última atividade foi há 2 dias ou mais
        last_completion_date = max(completed_dates) if completed_dates else None
        streak_broken = last_completion_date and (today - last_completion_date).days >= 2
        
        # --- LÓGICA DE EXIBIÇÃO DA SEMANA (DOMINGO A SÁBADO) ---
        # A semana no Django começa na Segunda (0). Para começar no Domingo, ajustamos.
        # Se hoje for Domingo (weekday=6), subtraimos 0 dias.
        # Se hoje for Segunda (weekday=0), subtraimos 1 dia.
        start_of_week = today - timedelta(days=(today.weekday() + 1) % 7)
        
        # Gera os dias da semana, de Domingo a Sábado
        days_of_week = [{'date': start_of_week + timedelta(days=i)} for i in range(7)]

        if streak_broken:
            for day in days_of_week:
                day['status'] = 'inativo'
            return Response(days_of_week)

        # Processa os dias para definir o status, mantendo os congelados
        for day_data in days_of_week:
            current_date = day_data['date']
            
            # Não processa status para dias futuros
            if current_date > today:
                day_data['status'] = 'inativo' 
                continue

            # 1. Se teve atividade no dia, o status é 'ativo'
            if current_date in completed_dates:
                day_data['status'] = 'ativo'
                continue

            # 2. Se não foi ativo, verifica o dia anterior para decidir se congela
            # Busca pela data de conclusão mais recente ANTERIOR ao dia atual
            most_recent_past_completion = None
            for d in sorted(list(completed_dates), reverse=True):
                if d < current_date:
                    most_recent_past_completion = d
                    break

            if most_recent_past_completion:
                # Se a última atividade foi exatamente no dia anterior, congela
                if (current_date - most_recent_past_completion).days == 1:
                    day_data['status'] = 'congelado'
                else:
                    # Se foi antes, o dia é inativo (pois já houve uma quebra)
                    day_data['status'] = 'inativo'
            else:
                # Se nunca houve atividade antes deste dia, é inativo
                day_data['status'] = 'inativo'

        return Response(days_of_week)


# A função de calcular experiência foi mantida, pois é idêntica em ambos os sistemas.
def calcular_experiencia(dificuldade: str, tempo_estimado: int) -> int:
    """
    Calcula a experiência ganha por uma atividade baseado na sua dificuldade e tempo.
    RN 04 - A experiência não poderá ultrapassar de 500 e tem um mínimo de 50.
    """
    exp_base = 50
    multiplicadores_dificuldade = {
        'muito_facil': 1.0,
        'facil': 2.0,
        'medio': 3.0,
        'dificil': 4.0,
        'muito_dificil': 5.0
    }
    multiplicador_dificuldade = multiplicadores_dificuldade.get(dificuldade, 1.0)

    if tempo_estimado <= 30:
        multiplicador_tempo = 1.0
    elif tempo_estimado <= 60:
        multiplicador_tempo = 1.5
    elif tempo_estimado <= 120:
        multiplicador_tempo = 2.0
    else:
        multiplicador_tempo = 2.5

    experiencia = round(exp_base * multiplicador_dificuldade * multiplicador_tempo)
    
    return max(50, min(experiencia, 500))