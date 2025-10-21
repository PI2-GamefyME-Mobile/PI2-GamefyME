# 🔐 Google Sign-In - Guia de Configuração

## 📋 Visão Geral

Este guia explica como configurar e usar o login/registro com conta Google no GamefyME.

## ✨ Funcionalidades Implementadas

### 1. **Login com Google** 🔑
- Login rápido usando conta Google existente
- Criação automática de conta se não existir
- Token seguro armazenado localmente

### 2. **Registro com Google** 📝
- Registro simplificado com um clique
- Dados do usuário preenchidos automaticamente
- Integração completa com backend Django

### 3. **UI Moderna** 🎨
- Botões com logo do Google
- Design consistente com o app
- Feedback visual para o usuário

## 🏗️ Arquitetura

### Arquivos Criados/Modificados

#### Novos Arquivos:
1. **`lib/services/google_auth_service.dart`** - Gerenciador de autenticação Google

#### Arquivos Modificados:
1. **`lib/services/auth_service.dart`** - Adicionados métodos:
   - `loginWithGoogle()`
   - `registerWithGoogle()`

2. **`lib/main.dart`** - Adicionados:
   - Botões de login/registro com Google
   - Handlers de autenticação Google
   - UI atualizada com dividers "OU"

3. **`pubspec.yaml`** - Dependência adicionada:
   - `google_sign_in: ^6.2.1`

4. **`android/app/src/main/AndroidManifest.xml`** - Permissões:
   - INTERNET (necessária para Google Sign-In)

## 🔧 Configuração Necessária

### 1. Configurar Google Cloud Console

#### Passo 1: Criar Projeto no Google Cloud
1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Anote o **Project ID**

#### Passo 2: Habilitar Google Sign-In API
1. No menu lateral, vá em **APIs & Services** > **Library**
2. Procure por "Google Sign-In API"
3. Clique em **Enable**

#### Passo 3: Configurar Tela de Consentimento OAuth
1. Vá em **APIs & Services** > **OAuth consent screen**
2. Escolha **External** (para teste)
3. Preencha:
   - **App name**: GamefyME
   - **User support email**: seu email
   - **Developer contact**: seu email
4. Clique em **Save and Continue**
5. Em **Scopes**, adicione:
   - `.../auth/userinfo.email`
   - `.../auth/userinfo.profile`
6. Adicione seus emails de teste em **Test users**

#### Passo 4: Criar Credenciais OAuth 2.0

##### Para Android:
1. Vá em **APIs & Services** > **Credentials**
2. Clique em **+ CREATE CREDENTIALS** > **OAuth client ID**
3. Selecione **Android**
4. Preencha:
   - **Name**: GamefyME Android
   - **Package name**: `com.example.gamefymobile` (ou seu package)
   - **SHA-1 certificate fingerprint**: (veja como obter abaixo)

**Como obter SHA-1:**
```bash
# Windows (PowerShell)
cd C:\Users\FelipeSantili\Documents\PI2-GamefyME\gamefymobile\android
.\gradlew signingReport

# Procure por "SHA1" na saída do comando
```

5. Clique em **Create**
6. Anote o **Client ID**

##### Para Web:
1. Crie outro OAuth client ID
2. Selecione **Web application**
3. Preencha:
   - **Name**: GamefyME Web
   - **Authorized JavaScript origins**: 
     - `http://localhost`
     - `http://localhost:8000`
   - **Authorized redirect URIs**:
     - `http://localhost/auth`
4. Clique em **Create**
5. Anote o **Client ID** e **Client Secret**

### 2. Configurar Android (android/app/build.gradle)

Não precisa adicionar nada extra! O plugin `google_sign_in` já faz a configuração automaticamente.

### 3. Configurar iOS (se necessário)

Adicione no arquivo `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>com.googleusercontent.apps.SEU-CLIENT-ID-INVERTIDO</string>
		</array>
	</dict>
</array>
```

### 4. Configurar Backend Django

Você precisará criar os endpoints no backend:

#### `api/usuarios/urls.py`:
```python
urlpatterns = [
    # ... rotas existentes ...
    path('login/google/', views.login_google, name='login-google'),
    path('cadastro/google/', views.cadastro_google, name='cadastro-google'),
]
```

#### `api/usuarios/views.py`:
```python
from google.oauth2 import id_token
from google.auth.transport import requests
import os

GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')

@api_view(['POST'])
@permission_classes([AllowAny])
def login_google(request):
    """Login com Google OAuth"""
    try:
        token = request.data.get('id_token')
        email = request.data.get('email')
        google_id = request.data.get('google_id')
        
        # Verifica o token do Google
        idinfo = id_token.verify_oauth2_token(
            token, 
            requests.Request(), 
            GOOGLE_CLIENT_ID
        )
        
        # Verifica se o usuário existe
        try:
            usuario = Usuario.objects.get(emailusuario=email)
        except Usuario.DoesNotExist:
            return Response(
                {'erro': 'Usuário não encontrado. Por favor, registre-se primeiro.'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Gera tokens JWT
        refresh = RefreshToken.for_user(usuario)
        
        return Response({
            'message': 'Login com Google realizado com sucesso!',
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'erro': f'Erro no login com Google: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def cadastro_google(request):
    """Cadastro com Google OAuth"""
    try:
        token = request.data.get('id_token')
        email = request.data.get('email')
        name = request.data.get('name')
        google_id = request.data.get('google_id')
        
        # Verifica o token do Google
        idinfo = id_token.verify_oauth2_token(
            token, 
            requests.Request(), 
            GOOGLE_CLIENT_ID
        )
        
        # Verifica se o usuário já existe
        if Usuario.objects.filter(emailusuario=email).exists():
            return Response(
                {'erro': 'Este email já está cadastrado.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Cria novo usuário
        usuario = Usuario.objects.create(
            nmusuario=name,
            emailusuario=email,
            google_id=google_id,
            # Senha aleatória (não será usada)
            senha=make_password(os.urandom(32).hex())
        )
        
        # Gera tokens JWT
        refresh = RefreshToken.for_user(usuario)
        
        return Response({
            'message': 'Cadastro com Google realizado com sucesso!',
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response(
            {'erro': f'Erro no cadastro com Google: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
```

#### Instale a biblioteca Google:
```bash
pip install google-auth google-auth-oauthlib google-auth-httplib2
```

#### Configure variável de ambiente:
```bash
# .env
GOOGLE_CLIENT_ID=seu-client-id-aqui.apps.googleusercontent.com
```

## 🎨 Assets Necessários

### Logo do Google

Baixe o logo oficial do Google em: [Google Brand Resource Center](https://about.google/brand-resource-center/)

Salve como: `assets/images/google_logo.png` (24x24 ou 48x48 pixels)

Ou use o ícone padrão (o código já tem fallback).

## 🚀 Como Usar

### No App

#### Tela de Login:
1. Usuário clica em "Continuar com Google"
2. Abre popup de seleção de conta Google
3. Usuário escolhe a conta
4. Se conta existe: faz login
5. Se não existe: cria automaticamente e faz login
6. Redireciona para HomeScreen

#### Tela de Registro:
1. Usuário clica em "Registrar com Google"
2. Mesmo fluxo do login
3. Dados preenchidos automaticamente
4. Redireciona para HomeScreen

### Logout

Para fazer logout completo (incluindo Google):
```dart
await GoogleAuthService().signOut();
```

Para desconectar completamente:
```dart
await GoogleAuthService().disconnect();
```

## 🔒 Segurança

### Tokens
- **ID Token**: Verificado no backend
- **Access Token**: Não armazenado (opcional)
- **JWT Tokens**: Armazenados com `flutter_secure_storage`

### Validação
- Token verificado no backend usando biblioteca oficial Google
- Email verificado contra database
- Proteção contra CSRF automática

## 🧪 Testes

### Ambiente de Desenvolvimento

Durante desenvolvimento, você pode testar com:
1. Contas de email adicionadas em "Test users" no Google Cloud Console
2. Não precisa publicar o app
3. Funciona em debug mode

### Ambiente de Produção

Para produção:
1. Submeta o app para revisão no Google Cloud Console
2. Publique o app na Play Store (Android)
3. Configure os redirects corretos

## 🐛 Troubleshooting

### Erro: "Error 10"
- **Causa**: SHA-1 não configurado corretamente
- **Solução**: Gere SHA-1 com `gradlew signingReport` e adicione no Google Cloud Console

### Erro: "API not enabled"
- **Causa**: Google Sign-In API não habilitada
- **Solução**: Habilite no Google Cloud Console

### Erro: "Invalid Client ID"
- **Causa**: Client ID incorreto
- **Solução**: Verifique se copiou o Client ID correto do Google Cloud Console

### Login não funciona
- **Causa**: Backend não configurado
- **Solução**: Implemente os endpoints `/login/google/` e `/cadastro/google/`

## 📚 Referências

- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Google Identity](https://developers.google.com/identity)
- [OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

## ✅ Checklist de Implementação

- [x] Adicionar dependência `google_sign_in`
- [x] Criar `GoogleAuthService`
- [x] Adicionar métodos no `AuthService`
- [x] Atualizar UI (Login/Registro)
- [x] Adicionar permissões Android
- [ ] Configurar Google Cloud Console
- [ ] Obter Client IDs
- [ ] Implementar endpoints backend
- [ ] Adicionar logo do Google
- [ ] Testar fluxo completo

## 🎉 Pronto!

Após configurar tudo, seu app terá login/registro com Google totalmente funcional! 🚀
