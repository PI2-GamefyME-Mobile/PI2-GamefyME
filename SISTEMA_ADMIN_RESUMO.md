# 🔐 SISTEMA DE ADMINISTRAÇÃO - RESUMO DA IMPLEMENTAÇÃO

## 📋 Funcionalidades Implementadas

### Sistema de Permissões
✅ Usuários com `tipousuario='admin'` têm acesso especial  
✅ Permissão customizada `IsAdmin` no backend  
✅ Getter `isAdmin` no modelo Usuario do Flutter  
✅ Botões de admin aparecem apenas para administradores  

### Administração de Desafios
✅ **Backend** - Endpoints completos:
- `GET /api/desafios/admin/` - Listar todos os desafios
- `POST /api/desafios/admin/` - Criar novo desafio
- `GET /api/desafios/admin/<id>/` - Visualizar desafio específico
- `PUT /api/desafios/admin/<id>/` - Atualizar desafio
- `DELETE /api/desafios/admin/<id>/` - Excluir desafio

✅ **Frontend** - Tela completa de administração:
- Lista todos os desafios cadastrados
- Formulário de criação/edição com todos os campos
- Confirmação antes de excluir
- Validações de datas para desafios únicos
- Botão "Admin" na tela de desafios (apenas para admins)

### Administração de Conquistas
✅ **Backend** - Endpoints completos:
- `GET /api/conquistas/admin/` - Listar todas as conquistas
- `POST /api/conquistas/admin/` - Criar nova conquista
- `GET /api/conquistas/admin/<id>/` - Visualizar conquista específica
- `PUT /api/conquistas/admin/<id>/` - Atualizar conquista
- `DELETE /api/conquistas/admin/<id>/` - Excluir conquista

✅ **Frontend** - Tela completa de administração:
- Lista todas as conquistas cadastradas
- Formulário de criação/edição com todos os campos
- Preview das imagens
- Validação de extensão de arquivo
- Botão "Gerenciar Conquistas" na tela de conquistas (apenas para admins)

## 🔧 Arquivos Criados/Modificados

### Backend (Django)

#### **api/desafios/views.py** (modificado)
```python
# Adicionado:
- Classe IsAdmin (permissão customizada)
- DesafioAdminListCreateView (GET/POST)
- DesafioAdminDetailView (GET/PUT/DELETE)
```

#### **api/desafios/serializers.py** (modificado)
```python
# Adicionado:
- DesafioCreateSerializer com validações para desafios únicos
```

#### **api/desafios/urls.py** (modificado)
```python
# Adicionado:
- path('admin/', ...) - Listar/criar
- path('admin/<int:iddesafio>/', ...) - Detalhes/editar/excluir
```

#### **api/conquistas/views.py** (modificado)
```python
# Adicionado:
- Classe IsAdmin (permissão customizada)
- ConquistaAdminListCreateView (GET/POST)
- ConquistaAdminDetailView (GET/PUT/DELETE)
```

#### **api/conquistas/serializers.py** (modificado)
```python
# Adicionado:
- ConquistaCreateSerializer com validação de extensão de imagem
```

#### **api/conquistas/urls.py** (modificado)
```python
# Adicionado:
- path('admin/', ...) - Listar/criar
- path('admin/<int:idconquista>/', ...) - Detalhes/editar/excluir
```

#### **api/usuarios/models.py** (já existia)
```python
# Já tinha:
- Campo tipousuario com choices (admin, comum)
```

#### **api/usuarios/serializers.py** (modificado)
```python
# Adicionado:
- Campo 'tipousuario' no UsuarioSerializer
```

### Frontend (Flutter)

#### **lib/models/models.dart** (modificado)
```dart
// Adicionado ao modelo Usuario:
- Campo tipoUsuario
- Getter isAdmin para verificar se é administrador
```

#### **lib/admin_desafios_screen.dart** (criado)
```dart
// Nova tela completa:
- AdminDesafiosScreen: lista com botões de editar/excluir
- FormularioDesafioScreen: formulário completo de criação/edição
- Campos: nome, descrição, tipo, lógica, XP, parâmetro, datas (para únicos)
```

#### **lib/admin_conquistas_screen.dart** (criado)
```dart
// Nova tela completa:
- AdminConquistasScreen: lista com botões de editar/excluir
- FormularioConquistaScreen: formulário completo de criação/edição
- Campos: nome, descrição, XP, imagem
```

#### **lib/services/api_service.dart** (modificado)
```dart
// Adicionado 8 métodos:
- fetchDesafiosAdmin()
- criarDesafio(dados)
- atualizarDesafio(id, dados)
- excluirDesafio(id)
- fetchConquistasAdmin()
- criarConquista(dados)
- atualizarConquista(id, dados)
- excluirConquista(id)
```

#### **lib/desafios_screen.dart** (modificado)
```dart
// Adicionado:
- Verificação isAdmin
- Botão "Admin" que navega para /admin-desafios
```

#### **lib/conquistas_screen.dart** (modificado)
```dart
// Adicionado:
- Verificação isAdmin
- Botão "Gerenciar Conquistas" que navega para /admin-conquistas
```

#### **lib/main.dart** (modificado)
```dart
// Adicionado:
- Import das telas de admin
- Rotas nomeadas: /admin-desafios e /admin-conquistas
```

## 🎯 Fluxo de Uso

### Para Administradores - Gerenciar Desafios

1. **Acessar tela de desafios**
   - Na tela de Desafios, aparece botão "Admin" no topo
   
2. **Criar novo desafio**
   - Clicar no botão "Novo"
   - Preencher formulário:
     - Nome do desafio
     - Descrição
     - Tipo (diário, semanal, mensal, único)
     - Tipo de lógica (atividades concluídas, recorrentes, etc.)
     - XP a ser concedido
     - Meta (parâmetro numérico)
     - Se único: datas de início e fim
   - Clicar em "CRIAR"

3. **Editar desafio existente**
   - Na lista, clicar no ícone de editar (lápis)
   - Modificar campos desejados
   - Clicar em "ATUALIZAR"

4. **Excluir desafio**
   - Na lista, clicar no ícone de excluir (lixeira)
   - Confirmar exclusão no diálogo

### Para Administradores - Gerenciar Conquistas

1. **Acessar tela de conquistas**
   - Na tela de Conquistas, aparece botão "Gerenciar Conquistas" no topo

2. **Criar nova conquista**
   - Clicar no botão "Nova"
   - Preencher formulário:
     - Nome da conquista
     - Descrição
     - XP a ser concedido
     - Nome da imagem (ex: relogio.png)
       - **Importante**: a imagem deve existir em `assets/conquistas/`
   - Clicar em "CRIAR"

3. **Editar conquista existente**
   - Na lista, clicar no ícone de editar (lápis)
   - Modificar campos desejados
   - Clicar em "ATUALIZAR"

4. **Excluir conquista**
   - Na lista, clicar no ícone de excluir (lixeira)
   - Confirmar exclusão no diálogo

## 🔒 Segurança

### Backend
- ✅ Permissão `IsAdmin` verifica `tipousuario == 'admin'`
- ✅ Endpoints de admin requerem autenticação + permissão admin
- ✅ Usuários comuns recebem 403 Forbidden ao tentar acessar

### Frontend
- ✅ Botões de admin só aparecem se `usuario.isAdmin == true`
- ✅ Rotas estão protegidas por autenticação JWT
- ✅ API retorna erro se usuário não autorizado tentar acessar

## 📊 Tipos de Lógica de Desafios

Os seguintes tipos de lógica estão disponíveis para desafios:

1. **atividades_concluidas**: Contar atividades concluídas no período
2. **recorrentes_concluidas**: Contar apenas atividades recorrentes concluídas
3. **min_dificeis**: Contar atividades difíceis/muito difíceis únicas concluídas
4. **desafios_concluidos**: Contar outros desafios completados
5. **atividades_criadas**: Contar atividades criadas pelo usuário

## 🧪 Como Testar

### 1. Criar usuário administrador no backend

**Opção A - Via Django Admin:**
```bash
cd api
python manage.py createsuperuser
# Email: admin@teste.com
# Senha: suasenha123
```

**Opção B - Atualizar usuário existente via shell:**
```bash
cd api
python manage.py shell
```
```python
from usuarios.models import Usuario
u = Usuario.objects.get(emailusuario='seuemail@teste.com')
u.tipousuario = 'admin'
u.save()
exit()
```

**Opção C - Diretamente no banco:**
```sql
UPDATE usuarios SET tipousuario = 'admin' WHERE emailusuario = 'seuemail@teste.com';
```

### 2. Testar no app

1. Fazer login com conta admin
2. Navegar para "Desafios"
   - Verificar que botão "Admin" aparece
   - Clicar no botão
   - Testar criar/editar/excluir desafios
3. Navegar para "Conquistas"
   - Verificar que botão "Gerenciar Conquistas" aparece
   - Clicar no botão
   - Testar criar/editar/excluir conquistas

### 3. Testar permissões

1. Fazer login com conta comum (tipousuario='comum')
2. Verificar que botões de admin NÃO aparecem
3. Tentar acessar endpoints de admin via Postman/curl:
```bash
# Deve retornar 403 Forbidden
curl -H "Authorization: Bearer SEU_TOKEN" http://127.0.0.1:8000/api/desafios/admin/
```

## ⚠️ Observações Importantes

1. **Imagens de conquistas**:
   - As imagens devem ser adicionadas manualmente em `assets/conquistas/`
   - Apenas o nome do arquivo é armazenado no banco
   - Extensões suportadas: .png, .jpg, .jpeg

2. **Desafios únicos**:
   - Requerem data de início e fim
   - Validação impede criar com datas inválidas
   - Aparecem apenas no período definido

3. **Exclusões**:
   - Não há soft delete implementado
   - Exclusão é permanente
   - Conquistas/desafios já concedidos aos usuários não são afetados (devido a ForeignKey)

4. **Validações**:
   - Backend valida todos os campos obrigatórios
   - Frontend mostra mensagens de erro amigáveis
   - Formulários impedem envio com dados inválidos

## 🚀 Próximas Melhorias Possíveis

- [ ] Upload de imagens de conquistas via app
- [ ] Preview em tempo real da imagem selecionada
- [ ] Filtros e busca nas telas de admin
- [ ] Ordenação customizável das listas
- [ ] Histórico de alterações (audit log)
- [ ] Duplicar desafio/conquista existente
- [ ] Ativar/desativar temporariamente sem excluir
- [ ] Dashboard com estatísticas para admins
- [ ] Notificar usuários quando novos desafios/conquistas são adicionados

---

**Implementação concluída com sucesso! 🎉**

Administradores agora podem gerenciar completamente desafios e conquistas através do aplicativo.
