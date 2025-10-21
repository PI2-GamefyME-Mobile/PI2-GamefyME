# Code Health Report

Data: 2025-10-21

Este relatório consolida os achados de duplicidade e código não utilizado no repositório.

## Duplicidades (jscpd)

- Ferramenta: jscpd (via npx)
- Caminho analisado: repositório inteiro
- Relatórios gerados:
  - Console: executado
  - HTML: `report-clean/html/index.html`

Resumo por linguagem (amostra mais relevante):
- Dart: 19 arquivos, 34 clones, ~10.36% de linhas duplicadas nas áreas afetadas
- Python: muitos clones foram reportados dentro do diretório `env/Lib/site-packages` (dependências). Estes não são parte do código do projeto e podem ser ignorados. O relatório limpo ainda exibiu entradas do `env/`, pois os padrões globais do Windows não foram totalmente respeitados pelo CLI; foque nos clones em `gamefymobile/lib/**`.

Principais pontos em Dart (exemplos):
- `lib/services/api_service.dart`: blocos repetidos entre métodos (padrões de request/try/catch e tratamento de respostas)
- `lib/services/auth_service.dart`: trechos duplicados próximos (fluxos de autenticação)
- `lib/widgets/custom_app_bar.dart`: blocos repetidos no mesmo arquivo
- Telas com repetições entre si:
  - `home_screen.dart` <-> `settings_screen.dart` (múltiplos blocos)
  - `historico_screen.dart` replicando blocos internos
  - `desafios_screen.dart` <-> `historico_screen.dart`
  - `conquistas_screen.dart` reutilizando padrões de layout
  - `cadastro_atividade_screen.dart` <-> `editar_atividade_screen.dart`

Ações sugeridas (Dart):
- Extrair widgets reutilizáveis (cards/list tiles/botões) em `lib/widgets/`
- Criar helpers para requisições HTTP em `lib/services/` (ex.: um método genérico para GET/POST com tratamento de erros)
- Consolidar lógica de formulários e validações em utilitários
- Avaliar uso de gerência de estado para reduzir lógica duplicada em telas

## Código não utilizado (Python – api/)

- Ferramentas: vulture e flake8

Observação importante: Em projetos Django, o vulture costuma marcar como “não utilizado” variáveis e classes que são usadas indiretamente pelo framework (ex.: `settings.py`, `Meta`, `db_table`, `urlpatterns`, apps, migrations). Trate a saída do vulture como triagem inicial, com alto índice de falso positivo.

Achados acionáveis (flake8):
- Vários `F401` (imports não utilizados), por exemplo:
  - `api/atividades/admin.py`: `django.contrib.admin` importado e não usado
  - `api/desafios/serializers.py`: múltiplos imports de `atividades.signals` não utilizados
  - `api/conquistas/admin.py`, `api/desafios/admin.py`, `api/notificacoes/admin.py`, `api/usuarios/admin.py`: imports não utilizados
- Vários `E501` (linhas > 79 colunas) e formatação: `E302`, `E261`, `W29x`, `W391` etc.

Ações sugeridas (Python):
- Remover imports não utilizados sinalizados por `F401`
- Ajustar formatação: quebras de linha, espaços e finais de arquivo (padrões PEP8)
- Opcional: adicionar um `.flake8` para ajustar regras (ex.: relaxar `E501` para 100-120 colunas se fizer sentido)
- Para minimizar falsos positivos do vulture, considerar um `whitelist.py` (marcando símbolos usados dinamicamente) ou focar no `flake8` para “unused imports/vars”

## Código não utilizado (Dart – gamefymobile/)

- Ferramenta: `flutter analyze`
- 23 issues:
  - Imports desnecessários (ex.: `services.dart` redundante com `material.dart`)
  - Uso de APIs deprecated: `.withOpacity` (substituir por `.withValues()`), `FormField.value` (usar `initialValue`)
  - Avisos de `use_build_context_synchronously`
  - `library_private_types_in_public_api` em alguns arquivos

Ações sugeridas (Dart):
- Remover imports não utilizados conforme apontado
- Substituir `.withOpacity(...)` por `.withValues(opacity: ...)`
- Revisar usos de `BuildContext` após awaits (padrão: checar `context.mounted` e reposicionar chamadas)
- Tornar tipos privados realmente internos ou expor tipos públicos adequadamente

## Próximos passos práticos

1) Duplicidades em Dart
   - Extrair componentes comuns dos trechos apontados no relatório HTML
   - Criar um `HttpClient`/`ApiClient` centralizado
   - Adicionar testes básicos para garantir comportamento antes/depois da refatoração

2) Limpeza Python (api/)
   - Remover F401 e ajustar formatação das ocorrências listadas
   - (Opcional) Adicionar `.flake8` para regras do projeto e executar no CI
   - Considerar ignorar `migrations/` e `settings.py` em checagens “unused” do vulture

3) Limpeza Dart
   - Aplicar sugestões do `flutter analyze`
   - (Opcional) Adicionar `dart_code_metrics` para métricas adicionais

## Como reproduzir as checagens

- Duplicidade (jscpd):
  - Na raiz do repo: `npx jscpd . -r console,html -o ./report-clean/ -p "**/*.{dart,kt,kts,swift,java,xml,yaml,json,py,html,css,js,ts}" -i "env/**" -i "**/site-packages/**" -i "**/build/**" -i "**/.dart_tool/**" -i "**/.git/**"`
- Python (flake8):
  - `env/Scripts/python.exe -m flake8 api`
- Python (vulture – com cautela):
  - `env/Scripts/python.exe -m vulture api --min-confidence 60`
- Dart/Flutter:
  - Em `gamefymobile/`: `flutter analyze`

---

Se quiser, posso começar limpando imports não utilizados (Python/Dart) e subindo um PR de refactor dos widgets duplicados mais óbvios nas telas apontadas.
