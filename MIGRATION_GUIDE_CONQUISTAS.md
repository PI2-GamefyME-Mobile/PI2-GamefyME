# Guia de Migração - Imagens de Conquistas

## Problema Identificado
Ao adicionar uma nova conquista, a imagem era salva corretamente no sistema de arquivos, mas não era exibida no aplicativo mobile. Isso ocorria porque:

1. As imagens eram salvas na pasta `gamefymobile/assets/conquistas/`
2. O Flutter usa `Image.asset()` para carregar imagens do bundle do app
3. As imagens em `assets/` são empacotadas apenas no momento da compilação
4. Novas imagens adicionadas após a compilação não aparecem no bundle

## Solução Implementada
A solução foi mudar de `Image.asset()` (imagens locais empacotadas) para `Image.network()` (imagens servidas pela API):

### Mudanças no Backend (Django)

1. **Configuração de Media Files** (`api/api/settings.py`)
   - Adicionado `MEDIA_URL = '/media/'`
   - Adicionado `MEDIA_ROOT = BASE_DIR / 'media'`

2. **URLs para servir arquivos** (`api/api/urls.py`)
   - Configurado para servir arquivos de mídia em desenvolvimento

3. **Modelo de Conquista** (`api/conquistas/models.py`)
   - Alterado campo `nmimagem` de `CharField` para `ImageField`
   - Configurado `upload_to='conquistas/'`

4. **Serializers** (`api/conquistas/serializers.py`)
   - Adicionado campo `imagem_url` que retorna a URL completa da imagem
   - Atualizado para incluir URLs em todas as respostas

5. **View de Upload** (`api/conquistas/views.py`)
   - Modificada para retornar tanto o filename quanto a URL completa
   - Simplificada para usar o sistema de upload do Django

### Mudanças no Frontend (Flutter)

1. **Modelo de Conquista** (`lib/models/models.dart`)
   - Adicionado campo opcional `imagemUrl`
   - Atualizado `fromJson` para capturar `imagem_url`

2. **Serviço de API** (`lib/services/api_service.dart`)
   - Alterado retorno de `uploadImagemConquista` para incluir URL

3. **Telas de Conquistas**
   - `admin_conquistas_screen.dart`: Usa `Image.network()` com fallback para `Image.asset()`
   - `conquistas_screen.dart`: Atualizado para exibir imagens via URL
   - `widgets/custom_app_bar.dart`: Suporta tanto URLs quanto assets

## Passos para Aplicar a Migração

### 1. Instalar Dependências
```powershell
# Ativar ambiente virtual
.\env\Scripts\Activate.ps1

# Navegar para pasta da API
cd api

# Instalar Pillow (necessário para ImageField)
pip install Pillow==11.0.0
```

### 2. Aplicar Migração do Banco de Dados
```powershell
# Ainda na pasta api/
python manage.py makemigrations conquistas
python manage.py migrate conquistas
```

### 3. Aplicar Script SQL (Opcional)
Se necessário, execute o script de migração SQL:
```powershell
psql -U postgres -d postgres -f ..\migration_conquistas_imagem.sql
```

### 4. Criar Diretório de Media
```powershell
# Voltar para raiz do projeto
cd ..

# Criar diretório de media
New-Item -ItemType Directory -Path "api\media\conquistas" -Force
```

### 5. Migrar Imagens Existentes (Se Aplicável)
Se você tem imagens existentes em `gamefymobile/assets/conquistas/`, pode copiá-las:
```powershell
# Copiar imagens existentes
Copy-Item "gamefymobile\assets\conquistas\*" -Destination "api\media\conquistas\" -Recurse
```

### 6. Atualizar Registros Existentes no Banco
Execute no psql ou através do Django shell:
```python
python manage.py shell

from conquistas.models import Conquista
from django.core.files import File
import os

# Para cada conquista que tem nmimagem mas não tem arquivo
for c in Conquista.objects.all():
    if c.nmimagem and not c.nmimagem.name.startswith('conquistas/'):
        # Atualizar o caminho para o novo formato
        c.nmimagem = f'conquistas/{c.nmimagem}'
        c.save()
```

### 7. Reiniciar o Servidor Django
```powershell
cd api
python manage.py runserver 0.0.0.0:8000
```

### 8. Recompilar o App Flutter (Se Necessário)
```powershell
cd ..\gamefymobile
flutter clean
flutter pub get
flutter run
```

## Verificação

1. **Testar Upload de Nova Imagem**
   - Login como admin
   - Criar nova conquista com imagem
   - Verificar se a imagem aparece imediatamente

2. **Verificar URL da Imagem**
   - A API deve retornar URLs no formato: `http://seu-servidor:8000/media/conquistas/nome_arquivo.png`

3. **Testar Fallback**
   - Imagens antigas em assets devem continuar funcionando
   - Novas imagens devem vir da URL

## Compatibilidade Retroativa

O código foi desenvolvido com fallback para manter compatibilidade:
- Se `imagemUrl` está disponível, usa `Image.network()`
- Se não, tenta `Image.asset()` com as imagens antigas
- Se falhar, mostra ícone padrão

## Notas Importantes

1. **Segurança**: Em produção, considere usar um serviço de storage como AWS S3
2. **Performance**: As imagens via rede podem ter carregamento mais lento
3. **Cache**: O Flutter faz cache automático de `Image.network()`
4. **CORS**: Verifique se o CORS está configurado corretamente para permitir o acesso às imagens

## Troubleshooting

### Erro: "Pillow not installed"
```powershell
pip install Pillow==11.0.0
```

### Erro: "Permission denied" ao criar diretório media
Execute o PowerShell como administrador ou verifique permissões

### Imagens não carregam no app
- Verifique se o servidor Django está rodando
- Confirme que `CORS_ALLOW_ALL_ORIGINS = True` em settings.py
- Verifique o console do Flutter para erros de rede
- Teste a URL da imagem diretamente no navegador

### Imagens antigas não aparecem
- Certifique-se de que as imagens foram copiadas para `api/media/conquistas/`
- Verifique se os caminhos no banco de dados estão corretos
