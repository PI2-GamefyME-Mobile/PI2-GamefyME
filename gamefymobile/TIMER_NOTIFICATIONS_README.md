# 🔔 Timer com Notificações - Documentação

## 📋 Visão Geral

Implementação completa de um sistema de timer persistente com notificações do sistema para a tela de realizar atividade.

## ✨ Funcionalidades Implementadas

### 1. **Timer Persistente em Background**
- O timer continua rodando mesmo quando o app é fechado ou minimizado
- Usa `SharedPreferences` para armazenar o estado do timer
- Retoma automaticamente quando o app é reaberto

### 2. **Notificações do Sistema**
- Notificação quando o timer é iniciado (low priority, ongoing)
- Notificação quando o timer termina (high priority, com som e vibração)
- Notificação de conclusão da atividade com XP ganho

### 3. **Conclusão Automática**
- Quando o timer chega a zero, a atividade é automaticamente concluída
- Notificação é enviada ao sistema
- Usuário é redirecionado para a tela inicial após 1.5 segundos

## 🏗️ Arquitetura

### Novos Serviços Criados

#### `NotificationService` (`lib/services/notification_service.dart`)
Gerencia todas as notificações do sistema:
- `initialize()` - Inicializa o serviço de notificações
- `requestPermissions()` - Solicita permissões ao usuário
- `showActivityCompletedNotification()` - Mostra notificação de atividade concluída
- `showTimerStartedNotification()` - Mostra notificação de timer em andamento
- `cancelTimerNotification()` - Cancela notificação de timer

#### `TimerService` (`lib/services/timer_service.dart`)
Gerencia o estado do timer em background:
- `startTimer()` - Inicia o timer e salva o estado
- `stopTimer()` - Para o timer
- `resetTimer()` - Reseta o timer e limpa dados salvos
- `getRemainingTime()` - Obtém tempo restante
- `getTimerData()` - Obtém todos os dados do timer
- `resumeTimerIfNeeded()` - Retoma timer ao reabrir o app

### Fluxo de Dados

```
Usuario inicia timer
    ↓
TimerService salva estado (SharedPreferences)
    ↓
NotificationService mostra notificação "Timer em andamento"
    ↓
Timer roda em background (periodic)
    ↓
Tempo chega a zero
    ↓
NotificationService mostra "Atividade Concluída" 
    ↓
API é chamada para registrar conclusão
    ↓
Usuário é redirecionado para home
```

## 🔧 Dependências Adicionadas

```yaml
flutter_local_notifications: ^17.2.3  # Notificações locais
workmanager: ^0.5.2                   # Background tasks (futuro)
```

## 📱 Permissões Android

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

## 🎯 Como Usar

### Inicialização (main.dart)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  await TimerService().resumeTimerIfNeeded();
  
  runApp(MyApp());
}
```

### Na Tela de Atividade
```dart
class _RealizarAtividadeScreenState extends State<RealizarAtividadeScreen> 
    with WidgetsBindingObserver {
  
  final NotificationService _notificationService = NotificationService();
  final TimerService _timerService = TimerService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupTimerListeners();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTimerState();
    }
  }
}
```

## 🔄 Ciclo de Vida do Timer

1. **App em Foreground**: Timer roda normalmente com UI atualizada
2. **App Minimizado**: Timer continua rodando via `Timer.periodic`
3. **App Fechado**: Estado salvo em `SharedPreferences` (timer para)
4. **App Reaberto**: Timer retoma do ponto onde parou

## 🎨 Experiência do Usuário

### Durante o Timer
- Progresso visual circular
- Contagem regressiva em tempo real
- Botões para pausar/reiniciar

### Quando Minimiza
- Notificação persistente mostrando timer em andamento
- Timer continua rodando

### Quando o Timer Termina
- ✅ Notificação do sistema com som e vibração
- ✅ Mensagem "🎉 [Atividade] concluída! (+XP XP)"
- ✅ Atividade registrada na API
- ✅ Redirecionamento automático para home

## 🐛 Tratamento de Erros

- Verifica `mounted` antes de operações assíncronas
- Try-catch em inicializações de serviços
- Mensagens de erro amigáveis ao usuário
- Logs de debug para desenvolvimento

## 🚀 Melhorias Futuras

1. **WorkManager** para timer mais robusto em background
2. **Foreground Service** no Android para timer garantido
3. **Notificações agendadas** com alarme
4. **Sincronização com servidor** do tempo restante
5. **Histórico de notificações** no app

## 📝 Notas Técnicas

### SharedPreferences Keys
- `timer_end_time` - Timestamp de quando o timer termina
- `timer_duration` - Duração total em segundos
- `timer_running` - Boolean se está rodando
- `timer_activity_id` - ID da atividade
- `timer_activity_name` - Nome da atividade
- `timer_activity_xp` - XP da atividade

### Notification Channels
- `activity_timer_channel` - Canal para notificações de timer

### Plataformas Suportadas
- ✅ Android (completo)
- ✅ iOS (completo)
- ⚠️ Web (notificações não suportadas)

## 🧪 Testes

### Para Testar
1. Inicie uma atividade com timer
2. Inicie o timer
3. Minimize o app
4. Aguarde o timer terminar
5. Verifique se:
   - Notificação apareceu
   - Atividade foi registrada
   - App redireciona ao abrir

## 🎉 Resultados

- ✅ Timer persistente funcionando
- ✅ Notificações implementadas
- ✅ Conclusão automática implementada
- ✅ UI melhorada e minimalista
- ✅ Experiência fluida e profissional
