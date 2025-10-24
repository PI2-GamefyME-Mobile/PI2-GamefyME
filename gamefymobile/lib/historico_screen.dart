import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'report/pdf_report.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';
import 'config/theme_provider.dart';
import 'package:intl/intl.dart';
import 'utils/responsive_utils.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Dados para a CustomAppBar
  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<DesafioPendente> _desafios = [];
  List<Conquista> _conquistas = [];

  // Dados específicos da tela
  List<Atividade> _atividades = [];
  List<Atividade> _atividadesFiltradas = [];
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final TextEditingController _nomeController = TextEditingController();
  String? _situacaoSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchHistoricoAtividades(
          startDate: _dataInicio,
          endDate: _dataFim,
        ),
        _apiService.fetchNotificacoes(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchConquistas(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _atividades = results[1] as List<Atividade>;
        _atividadesFiltradas = _atividades;
        _notificacoes = results[2] as List<Notificacao>;
        _desafios = results[3] as List<DesafioPendente>;
        _conquistas = results[4] as List<Conquista>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados.')),
      );
    }
  }

  void _filtrarAtividades() {
    List<Atividade> atividadesFiltradas = List.from(_atividades);

    if (_nomeController.text.isNotEmpty) {
      atividadesFiltradas = atividadesFiltradas
          .where((atividade) => atividade.nome
              .toLowerCase()
              .contains(_nomeController.text.toLowerCase()))
          .toList();
    }
    if (_situacaoSelecionada != null) {
      atividadesFiltradas = atividadesFiltradas
          .where((atividade) => atividade.situacao == _situacaoSelecionada)
          .toList();
    }
    setState(() => _atividadesFiltradas = atividadesFiltradas);
  }

  void _mostrarDetalhesAtividade(Atividade atividade) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: themeProvider.fundoCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho com cor de acordo com a situação
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: atividade.situacaoColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: atividade.situacaoColor,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Ícone de situação
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: atividade.situacaoColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        atividade.situacao == 'realizada'
                            ? Icons.check_circle
                            : atividade.situacao == 'cancelada'
                                ? Icons.cancel
                                : Icons.schedule,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            atividade.nome,
                            style: TextStyle(
                              color: themeProvider.textoTexto,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            FilterHelpers.getSituacaoDisplayName(
                                    atividade.situacao)
                                .toUpperCase(),
                            style: TextStyle(
                              color: atividade.situacaoColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: themeProvider.textoCinza),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Conteúdo
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Descrição
                      if (atividade.descricao.isNotEmpty) ...[
                        _buildSectionTitle('Descrição', themeProvider),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeProvider.fundoApp,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            atividade.descricao,
                            style: TextStyle(
                              color: themeProvider.textoTexto,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Informações em grid
                      _buildSectionTitle('Informações', themeProvider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.calendar_today,
                              label: 'Data',
                              value: DateFormat('dd/MM/yyyy')
                                  .format(DateTime.parse(atividade.dtAtividade)),
                              color: AppColors.verdeLima,
                              themeProvider: themeProvider,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.timer_outlined,
                              label: 'Tempo',
                              value: '${atividade.tpEstimado} min',
                              color: AppColors.roxoClaro,
                              themeProvider: themeProvider,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.stars,
                              label: 'Experiência',
                              value: '${atividade.xp} XP',
                              color: AppColors.amareloClaro,
                              themeProvider: themeProvider,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: atividade.recorrenciaIcon,
                              label: 'Tipo',
                              value: FilterHelpers.getRecorrenciaDisplayName(
                                  atividade.recorrencia),
                              color: atividade.recorrenciaColor,
                              themeProvider: themeProvider,
                            ),
                          ),
                        ],
                      ),

                      // Dificuldade destacada
                      const SizedBox(height: 20),
                      _buildSectionTitle('Dificuldade', themeProvider),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: atividade.dificuldadeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: atividade.dificuldadeColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              atividade.dificuldadeImage,
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              FilterHelpers.getDificuldadeDisplayName(
                                  atividade.dificuldade),
                              style: TextStyle(
                                color: atividade.dificuldadeColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Data de realização (se existir)
                      if (atividade.dtAtividadeRealizada != null &&
                          atividade.dtAtividadeRealizada!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle(
                          atividade.situacao == 'realizada'
                              ? 'Concluída em'
                              : 'Data de modificação',
                          themeProvider,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeProvider.fundoApp,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: atividade.situacaoColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(
                                    DateTime.parse(
                                        atividade.dtAtividadeRealizada!)),
                                style: TextStyle(
                                  color: themeProvider.textoTexto,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Botão de fechar
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeLima,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'FECHAR',
                      style: TextStyle(
                        color: AppColors.fundoEscuro,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Text(
      title,
      style: TextStyle(
        color: themeProvider.textoCinza,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoApp,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: themeProvider.textoCinza,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textoTexto,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafios,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
      ),
      backgroundColor: themeProvider.fundoApp,
      body: Column(
        children: [
          // Filtros na parte superior
          _buildFiltros(themeProvider),
          
          // Lista de atividades
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    color: AppColors.verdeLima,
                  ))
                : _atividadesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: themeProvider.textoCinza,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma atividade encontrada',
                              style: TextStyle(
                                color: themeProvider.textoCinza,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.verdeLima,
                        onRefresh: _carregarDados,
                        child: ListView.builder(
                          padding: ResponsiveUtils.adaptivePadding(context),
                          itemCount: _atividadesFiltradas.length,
                          itemBuilder: (context, index) {
                            final atividade = _atividadesFiltradas[index];
                            return _buildAtividadeCard(atividade, themeProvider);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtividadeCard(Atividade atividade, ThemeProvider themeProvider) {
    final isSmall = ResponsiveUtils.isSmallScreen(context);
    return GestureDetector(
      onTap: () => _mostrarDetalhesAtividade(atividade),
      child: Container(
        margin: EdgeInsets.only(bottom: isSmall ? 8 : 12),
        decoration: BoxDecoration(
          color: themeProvider.cardAtividade,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: atividade.situacaoColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador visual de situação (círculo colorido)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: atividade.situacaoColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da atividade
                    Text(
                      atividade.nome,
                      style: TextStyle(
                        color: themeProvider.textoAtividade,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Data
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: themeProvider.textoCinza,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(atividade.dtAtividade)),
                          style: TextStyle(
                            color: themeProvider.textoCinza,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // XP
                        Icon(
                          Icons.stars,
                          size: 12,
                          color: AppColors.amareloClaro,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${atividade.xp} XP',
                          style: TextStyle(
                            color: themeProvider.textoCinza,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Badges compactas
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildCompactBadge(
                          FilterHelpers.getSituacaoDisplayName(atividade.situacao),
                          atividade.situacaoColor,
                        ),
                        _buildCompactBadge(
                          FilterHelpers.getDificuldadeDisplayName(atividade.dificuldade),
                          atividade.dificuldadeColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Ícone de detalhes
              Icon(
                Icons.chevron_right,
                color: themeProvider.textoCinza,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFiltros(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.verdeLima,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'FILTROS',
                style: TextStyle(
                  color: themeProvider.textoTexto,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seleção de intervalo de datas
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  context: context,
                  label: _dataInicio == null
                      ? 'Data Início'
                      : DateFormat('dd/MM/yyyy').format(_dataInicio!),
                  icon: Icons.event,
                  isSelected: _dataInicio != null,
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _dataInicio ?? DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.verdeLima,
                              onPrimary: AppColors.fundoEscuro,
                              surface: AppColors.fundoCardEscuro,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _dataInicio = picked);
                      await _carregarDados();
                      _filtrarAtividades();
                    }
                  },
                  themeProvider: themeProvider,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  context: context,
                  label: _dataFim == null
                      ? 'Data Fim'
                      : DateFormat('dd/MM/yyyy').format(_dataFim!),
                  icon: Icons.event,
                  isSelected: _dataFim != null,
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _dataFim ?? DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.verdeLima,
                              onPrimary: AppColors.fundoEscuro,
                              surface: AppColors.fundoCardEscuro,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _dataFim = picked);
                      await _carregarDados();
                      _filtrarAtividades();
                    }
                  },
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Campo de busca por nome
          TextField(
            controller: _nomeController,
            style: TextStyle(color: themeProvider.textoTexto, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar por nome...',
              hintStyle: TextStyle(color: themeProvider.textoCinza),
              prefixIcon: Icon(Icons.search, color: AppColors.verdeLima, size: 20),
              suffixIcon: _nomeController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: themeProvider.textoCinza, size: 20),
                      onPressed: () {
                        _nomeController.clear();
                        _filtrarAtividades();
                      },
                    )
                  : null,
              filled: true,
              fillColor: themeProvider.fundoApp,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeProvider.fundoApp),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.verdeLima, width: 2),
              ),
            ),
            onChanged: (value) => _filtrarAtividades(),
          ),

          const SizedBox(height: 12),

          // Filtro de situação
          DropdownButtonFormField<String>(
            value: _situacaoSelecionada,
            hint: Row(
              children: [
                Icon(Icons.label, color: themeProvider.textoCinza, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Situação',
                  style: TextStyle(color: themeProvider.textoCinza, fontSize: 14),
                ),
              ],
            ),
            style: TextStyle(color: themeProvider.textoTexto, fontSize: 14),
            dropdownColor: themeProvider.fundoCard,
            decoration: InputDecoration(
              filled: true,
              fillColor: themeProvider.fundoApp,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: FilterHelpers.getSituacaoOptions().map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _situacaoSelecionada = newValue);
              _filtrarAtividades();
            },
          ),

          // Botões de ação
          if (_dataInicio != null || _dataFim != null || 
              _nomeController.text.isNotEmpty || _situacaoSelecionada != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Botão limpar filtros
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _limparFiltros,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: themeProvider.textoCinza,
                      side: BorderSide(color: themeProvider.textoCinza),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_dataInicio != null && _dataFim != null) ...[
                  const SizedBox(width: 8),
                  // Botão gerar PDF
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final periodo = DateTimeRange(start: _dataInicio!, end: _dataFim!);
                        final atividadesResumo = _atividadesFiltradas
                            .map((a) {
                              DateTime data;
                              if ((a.dtAtividadeRealizada ?? '').isNotEmpty) {
                                data = DateTime.tryParse(a.dtAtividadeRealizada!) ?? DateTime.now();
                              } else {
                                data = DateTime.tryParse(a.dtAtividade) ?? DateTime.now();
                              }
                              return AtividadeResumo(
                                nome: a.nome,
                                situacao: a.situacao,
                                dificuldade: FilterHelpers.getDificuldadeDisplayName(a.dificuldade),
                                experiencia: a.xp,
                                data: data,
                                descricao: a.descricao.isEmpty ? null : a.descricao,
                              );
                            })
                            .toList();

                        await shareActivitiesPdf(
                          atividades: atividadesResumo,
                          periodo: periodo,
                          primaryColor: AppColors.verdeLima,
                          onPrimaryColor: AppColors.fundoEscuro,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verdeLima,
                        foregroundColor: AppColors.fundoEscuro,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required ThemeProvider themeProvider,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: isSelected ? AppColors.verdeLima : themeProvider.textoCinza,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.verdeLima : themeProvider.textoCinza,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: themeProvider.fundoApp,
        side: BorderSide(
          color: isSelected ? AppColors.verdeLima : themeProvider.textoCinza,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _limparFiltros() {
    setState(() {
      _nomeController.clear();
      _situacaoSelecionada = null;
      _dataInicio = null;
      _dataFim = null;
    });
    _carregarDados();
  }
}
