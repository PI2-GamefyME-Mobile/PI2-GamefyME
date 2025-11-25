# GamefyME: um sistema mobile de tarefas gamificado focado em produtividade

## Resumo

**GamefyME** é um aplicativo de produtividade gamificado, projetado para transformar a maneira como você encara suas tarefas diárias. Ao adicionar elementos de jogo à sua lista de afazeres, o GamefyME torna a produtividade mais envolvente e recompensadora.

### Visão Geral

O projeto consiste em um aplicativo móvel desenvolvido com **Flutter** e um backend robusto construído com **Django REST Framework**. O objetivo principal é incentivar os usuários a completarem suas tarefas, oferecendo recompensas como pontos de experiência (XP), níveis, desafios e conquistas.

### Funcionalidades Principais

* **Gamificação da Produtividade**: Transforme suas tarefas em um jogo! Ganhe XP e suba de nível ao concluir atividades.
* **Gestão de Atividades**: Crie e gerencie tarefas únicas ou recorrentes com diferentes níveis de dificuldade.
* **Sistema de Recompensas**: Desbloqueie conquistas e complete desafios diários, semanais ou mensais para ganhar recompensas extras.
* **Acompanhamento de Progresso**: Mantenha-se motivado com um sistema de "streak" que acompanha seus dias consecutivos de atividades.
* **Notificações**: Receba notificações para se manter atualizado sobre suas atividades e recompensas.
* **Personalização**: Escolha entre diferentes avatares para personalizar seu perfil.

### Tecnologias Utilizadas

* **Frontend**: Desenvolvido em **Flutter**, garantindo uma experiência de usuário fluida e multiplataforma.
* **Backend**: API RESTful construída com **Django** e **Django REST Framework**.
* **Banco de Dados**: **PostgreSQL** é utilizado para o armazenamento dos dados.

---

## Colaboradores

-   **Arthur Roque dos Santos**
    -   [roquearthur86@gmail.com](mailto:roquearthur86@gmail.com)
-   **Lucas Minozzo Avila**
    -   [lucasmavila@gmail.com](mailto:lucasmavila@gmail.com)
-   **Luis Felipe de Souza Santili**
    -   [felipesantili@gmail.com](mailto:felipesantili@gmail.com)

---

## Manual para instalação e execução do aplicativo

Passos essenciais para rodar o backend (Django + PostgreSQL) e o app (Flutter), em Windows e Linux.
Pré-Requisitos:
 - <a href="https://www.postgresql.org/download/" target="_blank">PostgreSQL</a> 
 - <a href="https://www.djangoproject.com/download/" target="_blank">Django</a>
 - <a href="https://docs.flutter.dev/install" target="_blank">Flutter</a>

## Configuração do Banco de Dados (antes de tudo)

Antes de rodar a API, configure o PostgreSQL e atualize o arquivo de `settings` do Django.

1) Crie usuário e banco no PostgreSQL (via psql ou pgAdmin):

```powershell
# Abra o psql (ajuste se necessário)
psql -U postgres -h localhost

# Dentro do psql, crie usuário e banco (substitua pela sua senha)
CREATE USER gamefy_user WITH PASSWORD 'SUA_SENHA';
CREATE DATABASE gamefydb OWNER gamefy_user;
```

2) Ajuste o arquivo de configuração do Django em `api/api/settings.py` na seção `DATABASES`:

```python
# Em api/api/settings.py > DATABASES
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'gamefydb',         # nome do banco
        'USER': 'gamefy_user',      # usuário do banco
        'PASSWORD': 'SUA_SENHA_FORTE',
        'HOST': 'localhost',
        'PORT': 5432,
    }
}
```

Observações:
- O repositório possui exemplos de configuração (Felipe/Lucas) dentro de `api/api/settings.py`. Substitua pelos seus valores locais.
- Em produção, prefira variáveis de ambiente para `USER`, `PASSWORD`, etc.

3) Aplique as migrações e valide a conexão:

```powershell
python api/manage.py migrate
python api/manage.py runserver 0.0.0.0:8000
# API: http://127.0.0.1:8000/api | Swagger: http://127.0.0.1:8000/swagger/
```

## Importar Desafios e Conquistas Iniciais (SQL)

Após criar o banco e aplicar as migrações, você pode popular as tabelas com os registros iniciais do arquivo `banco.sql` (na raiz do projeto).

1) Via `psql` (recomendado):

```powershell
# Ajuste <USER> e <DB_NAME> com os valores de `api/api/settings.py`
# Ex.: NAME = gamefydb | USER = gamefy_user
psql -U <USER> -h localhost -d <DB_NAME> -f "c:\Users\FelipeSantili\Documents\PI2-GamefyME\banco.sql"
```

Em Linux:

```bash
# Rode a partir da raiz do projeto ou use caminho absoluto
psql -U <USER> -h localhost -d <DB_NAME> -f banco.sql
```

2) Via pgAdmin (alternativa):
- Abra o servidor e selecione seu banco.
- Ferramenta de Consulta (Query Tool) → File → Open → selecione `banco.sql` → Execute.

Observações importantes:
- Garanta que as tabelas existam (rode `python api/manage.py migrate` antes).
- As conquistas referenciam imagens por caminho como `conquistas/arquivo.png`. Coloque esses arquivos em `api/media/conquistas/` ou ajuste os nomes conforme seu ambiente.
- Se houver atualizações complementares, veja também `db_update_2025-10-28_conquistas.sql`.

### Windows (PowerShell)

- Backend
    ```powershell
    git clone https://github.com/PI2-GamefyME-Mobile/PI2-GamefyME.git
    cd PI2-GamefyME
    python -m venv env
    .\env\Scripts\Activate.ps1
    pip install -r requirements.txt
    python api/manage.py migrate
    python api/manage.py runserver 0.0.0.0:8000
    ```
    - API: http://127.0.0.1:8000/api | Swagger: http://127.0.0.1:8000/swagger/
    - DB padrão (ajuste em `api/api/settings.py` se necessário): nome `postgres`, usuário `postgres`, senha `ifpr`.

- Mobile (Flutter)
    ```powershell
    cd gamefymobile
    flutter pub get
    flutter run -d windows --dart-define API_BASE_URL=http://127.0.0.1:8000/api
    # Chrome (opcional)
    flutter run -d chrome  --dart-define API_BASE_URL=http://127.0.0.1:8000/api
    # Android Emulator: usar 10.0.2.2 para acessar o host
    flutter run --dart-define API_BASE_URL=http://10.0.2.2:8000/api
    ```

### Linux (Bash)

- Backend
    ```bash
    git clone https://github.com/PI2-GamefyME-Mobile/PI2-GamefyME.git
    cd PI2-GamefyME
    python3 -m venv env
    source env/bin/activate
    pip install -r requirements.txt
    python3 api/manage.py migrate
    python3 api/manage.py runserver 0.0.0.0:8000
    ```
    - API: http://127.0.0.1:8000/api | Swagger: http://127.0.0.1:8000/swagger/

- Mobile (Flutter)
    ```bash
    cd gamefymobile
    flutter pub get
    # Desktop Linux
    flutter run -d linux  --dart-define API_BASE_URL=http://127.0.0.1:8000/api
    # Chrome (opcional)
    flutter run -d chrome --dart-define API_BASE_URL=http://127.0.0.1:8000/api
    # Android Emulator
    flutter run --dart-define API_BASE_URL=http://10.0.2.2:8000/api
    ```


## Lembretes Automáticos por E-mail (RF 12)

Foi adicionada uma tarefa de gerenciamento para enviar lembretes diários aos usuários que ainda não concluíram atividades no dia, além de registrar uma Notificação no histórico.

Como executar manualmente:

```
python api/manage.py enviar_lembretes
```

Como agendar (Windows): utilize o Agendador de Tarefas para executar o comando diariamente no ambiente configurado. Em Linux, use cron; em produção pode-se empregar Celery Beat.

---

Notas rápidas:
- Ajuste `API_BASE_URL` conforme seu cenário (dispositivo físico: IP da máquina, ex.: http://192.168.X.Y:8000/api).
- Para configuração persistente, você pode alterar `gamefymobile/lib/config/api_config.dart`.
  
