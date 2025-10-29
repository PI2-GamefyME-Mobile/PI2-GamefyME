# Sons do Aplicativo

## timer_complete.mp3
Som tocado quando o timer de uma atividade é concluído.

**Status**: ⚠️ Arquivo não presente - som não será tocado (fallback silencioso)

### Como Adicionar o Arquivo de Áudio:

1. **Baixe um som de sucesso/conclusão** (1-2 segundos) em formato MP3
2. **Renomeie** para `timer_complete.mp3`
3. **Coloque nesta pasta** (`assets/sounds/`)
4. **Reinicie o app** para que o Flutter reconheça o novo arquivo

### Fontes de Sons Gratuitos:

- **Pixabay**: https://pixabay.com/sound-effects/search/success/
- **Freesound**: https://freesound.org/
- **Mixkit**: https://mixkit.co/free-sound-effects/

### Sugestões de Busca:
- "success"
- "achievement" 
- "ding"
- "notification"
- "complete"
- "level up"

### Requisitos do Arquivo:
- **Formato**: MP3
- **Duração**: 1-3 segundos (recomendado)
- **Tamanho**: < 100KB (para não aumentar muito o app)
- **Taxa de bits**: 128kbps ou menos
- **Licença**: Deve ser livre para uso comercial

### Observações:
- O som é tocado **apenas quando o app está em primeiro plano**
- **Notificações do sistema** têm seus próprios sons (configurados separadamente)
- Se o arquivo não existir, o erro é capturado e não afeta a funcionalidade
- O som é tocado usando o package `audioplayers`

### Teste:
Após adicionar o arquivo, teste:
1. Inicie uma atividade
2. Inicie o timer (use tempo curto para teste)
3. Aguarde o timer terminar
4. Deve tocar o som de conclusão

