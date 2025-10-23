import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/config/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:gamefymobile/config/app_colors.dart';

class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen> {
  final ApiService _apiService = ApiService();
  Estatisticas? _estatisticas;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final estatisticas = await _apiService.fetchEstatisticas();
      if (!mounted) return;
      setState(() {
        _estatisticas = estatisticas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar estatísticas: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.fundoApp,
      appBar: AppBar(
        title: const Text('Estatísticas'),
        backgroundColor: AppColors.roxoHeader,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarEstatisticas,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarEstatisticas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResumoCards(themeProvider),
                        const SizedBox(height: 24),
                        _buildProgressoNivel(themeProvider),
                        const SizedBox(height: 24),
                        _buildHeatMap(themeProvider),
                        const SizedBox(height: 24),
                        _buildGraficoUltimos30Dias(themeProvider),
                        const SizedBox(height: 24),
                        _buildAtividadesPorDificuldade(themeProvider),
                        const SizedBox(height: 24),
                        _buildGraficoPorSemana(themeProvider),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumoCards(ThemeProvider themeProvider) {
    final resumo = _estatisticas!.resumo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Resumo Geral',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: themeProvider.textoTexto,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '🎯',
                resumo.totalAtividades.toString(),
                'Atividades',
                AppColors.roxoHeader,
                themeProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🏆',
                resumo.totalConquistas.toString(),
                'Conquistas',
                AppColors.amareloOuro,
                themeProvider,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '⚔️',
                resumo.totalDesafios.toString(),
                'Desafios',
                AppColors.verdeSuccess,
                themeProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🔥',
                resumo.diasStreak.toString(),
                'Dias Streak',
                Colors.orange,
                themeProvider,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '📈',
                resumo.mediaPorDia.toStringAsFixed(1),
                'Média/Dia',
                Colors.blue,
                themeProvider,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '📅',
                resumo.melhorDiaSemana ?? 'N/A',
                'Melhor Dia',
                Colors.purple,
                themeProvider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String valor, String label, Color cor,
      ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.textoTexto.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressoNivel(ThemeProvider themeProvider) {
    final progresso = _estatisticas!.progressoNivel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.roxoHeader.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⚡ Progresso de Nível',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textoTexto,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.roxoHeader,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nível ${progresso.nivelAtual}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progresso.xpAtual} XP',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textoTexto.withOpacity(0.7),
                ),
              ),
              Text(
                '${progresso.xpNecessario} XP',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textoTexto.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progresso.percentual / 100,
              minHeight: 20,
              backgroundColor: themeProvider.fundoApp,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.roxoHeader),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${progresso.percentual.toStringAsFixed(1)}% completo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.roxoHeader,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMap(ThemeProvider themeProvider) {
    final heatMapData = _estatisticas!.heatMap;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Heat Map - Últimos 90 dias',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textoTexto,
            ),
          ),
          const SizedBox(height: 16),
          _buildHeatMapGrid(heatMapData, themeProvider),
          const SizedBox(height: 12),
          _buildHeatMapLegend(themeProvider),
        ],
      ),
    );
  }

  Widget _buildHeatMapGrid(List<HeatMapData> data, ThemeProvider themeProvider) {
    // Agrupa por semanas
    final semanas = <List<HeatMapData>>[];
    for (int i = 0; i < data.length; i += 7) {
      semanas.add(data.sublist(i, (i + 7).clamp(0, data.length)));
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: semanas.length,
        itemBuilder: (context, semanaIndex) {
          final semana = semanas[semanaIndex];
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: semana.map((dia) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _getHeatMapColor(dia.intensidade, themeProvider),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Color _getHeatMapColor(int intensidade, ThemeProvider themeProvider) {
    if (intensidade == 0) {
      return themeProvider.fundoApp;
    }
    final cores = [
      Colors.green.shade200,
      Colors.green.shade400,
      Colors.green.shade600,
      Colors.green.shade800,
      Colors.green.shade900,
    ];
    return cores[(intensidade - 1).clamp(0, cores.length - 1)];
  }

  Widget _buildHeatMapLegend(ThemeProvider themeProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Menos',
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.textoTexto.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index == 0
                  ? themeProvider.fundoApp
                  : _getHeatMapColor(index, themeProvider),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: themeProvider.textoTexto.withOpacity(0.2),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'Mais',
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.textoTexto.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoUltimos30Dias(ThemeProvider themeProvider) {
    final dados = _estatisticas!.atividadesUltimos30Dias;
    final maxValue = dados.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();
    final heightFactor = maxValue > 0 ? 100 / maxValue : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Atividades - Últimos 30 dias',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textoTexto,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dados.length,
              itemBuilder: (context, index) {
                final dia = dados[index];
                final altura = dia.count * heightFactor;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (dia.count > 0)
                        Text(
                          dia.count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: themeProvider.textoTexto.withOpacity(0.6),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: altura.clamp(2, 100),
                        decoration: BoxDecoration(
                          color: dia.count > 0
                              ? AppColors.roxoHeader
                              : themeProvider.fundoApp,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (index % 5 == 0)
                        SizedBox(
                          width: 30,
                          child: Text(
                            dia.data,
                            style: TextStyle(
                              fontSize: 8,
                              color: themeProvider.textoTexto.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtividadesPorDificuldade(ThemeProvider themeProvider) {
    final dados = _estatisticas!.atividadesPorDificuldade;
    final total = dados.values.fold(0, (sum, count) => sum + count);

    final dificuldades = {
      'muito_facil': {'label': 'Muito Fácil', 'color': Colors.green.shade300},
      'facil': {'label': 'Fácil', 'color': Colors.lightGreen},
      'medio': {'label': 'Médio', 'color': Colors.orange},
      'dificil': {'label': 'Difícil', 'color': Colors.deepOrange},
      'muito_dificil': {'label': 'Muito Difícil', 'color': Colors.red},
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Atividades por Dificuldade',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textoTexto,
            ),
          ),
          const SizedBox(height: 16),
          ...dificuldades.entries.map((entry) {
            final count = dados[entry.key] ?? 0;
            final percentual = total > 0 ? (count / total * 100) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.value['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.textoTexto,
                        ),
                      ),
                      Text(
                        '$count (${percentual.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: entry.value['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentual / 100,
                      minHeight: 12,
                      backgroundColor: themeProvider.fundoApp,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        entry.value['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGraficoPorSemana(ThemeProvider themeProvider) {
    final dados = _estatisticas!.atividadesPorSemana;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.fundoCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Atividades por Semana (últimas 12)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.textoTexto,
            ),
          ),
          const SizedBox(height: 16),
          ...dados.map((semana) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      semana.semana,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.textoTexto.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: semana.count / 50, // normalizado para max 50
                              minHeight: 20,
                              backgroundColor: themeProvider.fundoApp,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.verdeSuccess,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            semana.count.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.verdeSuccess,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
