class Estatisticas {
  final ResumoEstatisticas resumo;
  final Map<String, int> atividadesPorDificuldade;
  final List<AtividadeDia> atividadesUltimos30Dias;
  final List<AtividadeSemana> atividadesPorSemana;
  final List<HeatMapData> heatMap;
  final ProgressoNivel progressoNivel;

  Estatisticas({
    required this.resumo,
    required this.atividadesPorDificuldade,
    required this.atividadesUltimos30Dias,
    required this.atividadesPorSemana,
    required this.heatMap,
    required this.progressoNivel,
  });

  factory Estatisticas.fromJson(Map<String, dynamic> json) {
    return Estatisticas(
      resumo: ResumoEstatisticas.fromJson(json['resumo'] ?? {}),
      atividadesPorDificuldade: Map<String, int>.from(
        json['atividades_por_dificuldade'] ?? {}
      ),
      atividadesUltimos30Dias: (json['atividades_ultimos_30_dias'] as List? ?? [])
          .map((e) => AtividadeDia.fromJson(e))
          .toList(),
      atividadesPorSemana: (json['atividades_por_semana'] as List? ?? [])
          .map((e) => AtividadeSemana.fromJson(e))
          .toList(),
      heatMap: (json['heat_map'] as List? ?? [])
          .map((e) => HeatMapData.fromJson(e))
          .toList(),
      progressoNivel: ProgressoNivel.fromJson(json['progresso_nivel'] ?? {}),
    );
  }
}

class ResumoEstatisticas {
  final int totalAtividades;
  final int totalConquistas;
  final int totalDesafios;
  final int diasStreak;
  final double mediaPorDia;
  final String? melhorDiaSemana;

  ResumoEstatisticas({
    required this.totalAtividades,
    required this.totalConquistas,
    required this.totalDesafios,
    required this.diasStreak,
    required this.mediaPorDia,
    this.melhorDiaSemana,
  });

  factory ResumoEstatisticas.fromJson(Map<String, dynamic> json) {
    return ResumoEstatisticas(
      totalAtividades: json['total_atividades'] ?? 0,
      totalConquistas: json['total_conquistas'] ?? 0,
      totalDesafios: json['total_desafios'] ?? 0,
      diasStreak: json['dias_streak'] ?? 0,
      mediaPorDia: (json['media_por_dia'] ?? 0).toDouble(),
      melhorDiaSemana: json['melhor_dia_semana'],
    );
  }
}

class AtividadeDia {
  final String data;
  final int count;

  AtividadeDia({
    required this.data,
    required this.count,
  });

  factory AtividadeDia.fromJson(Map<String, dynamic> json) {
    return AtividadeDia(
      data: json['data'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class AtividadeSemana {
  final String semana;
  final int count;

  AtividadeSemana({
    required this.semana,
    required this.count,
  });

  factory AtividadeSemana.fromJson(Map<String, dynamic> json) {
    return AtividadeSemana(
      semana: json['semana'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class HeatMapData {
  final String data;
  final int count;
  final int intensidade;

  HeatMapData({
    required this.data,
    required this.count,
    required this.intensidade,
  });

  factory HeatMapData.fromJson(Map<String, dynamic> json) {
    return HeatMapData(
      data: json['data'] ?? '',
      count: json['count'] ?? 0,
      intensidade: json['intensidade'] ?? 0,
    );
  }
}

class ProgressoNivel {
  final int nivelAtual;
  final int xpAtual;
  final int xpNecessario;
  final double percentual;

  ProgressoNivel({
    required this.nivelAtual,
    required this.xpAtual,
    required this.xpNecessario,
    required this.percentual,
  });

  factory ProgressoNivel.fromJson(Map<String, dynamic> json) {
    return ProgressoNivel(
      nivelAtual: json['nivel_atual'] ?? 1,
      xpAtual: json['xp_atual'] ?? 0,
      xpNecessario: json['xp_necessario'] ?? 1000,
      percentual: (json['percentual'] ?? 0).toDouble(),
    );
  }
}
