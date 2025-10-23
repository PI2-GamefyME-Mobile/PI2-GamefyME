import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// Exportar o modelo de estatísticas
export 'estatisticas.dart';

// Modelo para os dados do usuário principal
class Usuario {
  final int id;
  final String nome;
  final String email;
  final int nivel;
  final int exp;
  final int expTotalNivel;
  final String imagemPerfil;
  final String tipoUsuario;
  final List<StreakDia> streakData;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.nivel,
    required this.exp,
    required this.expTotalNivel,
    required this.imagemPerfil,
    required this.tipoUsuario,
    required this.streakData,
  });

  bool get isAdmin => tipoUsuario == 'admin';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['idusuario'] ?? 0,
      nome: json['nmusuario'] ?? '',
      email: json['emailusuario'] ?? '',
      nivel: json['nivelusuario'] ?? 1,
      exp: json['expusuario'] ?? 0,
      expTotalNivel: json['exp_total_nivel'] ?? 100,
      imagemPerfil: json['imagem_perfil'] ?? 'avatar1.png',
      tipoUsuario: json['tipousuario'] ?? 'comum',
      streakData: (json['streak_data'] as List<dynamic>? ?? [])
          .map((e) => StreakDia.fromJson(e))
          .toList(),
    );
  }
}

// Modelo para os dias da semana no card de streak
class StreakDia {
  final String diaSemana;
  final String imagem;

  StreakDia({required this.diaSemana, required this.imagem});

  factory StreakDia.fromJson(Map<String, dynamic> json) {
    return StreakDia(
      diaSemana: json['dia_semana'] ?? '',
      imagem: json['imagem'] ?? '',
    );
  }
}

// Modelo para a lista de atividades na tela principal
class Atividade {
  final int id;
  final String nome;
  final String descricao;
  final String dificuldade;
  final String situacao;
  final String recorrencia;
  final int tpEstimado; // em minutos
  final int xp;
  final int nivelUsuario;
  final String dtAtividade;
  final String? dtAtividadeRealizada;

  Atividade({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.dificuldade,
    required this.situacao,
    required this.recorrencia,
    required this.tpEstimado,
    required this.xp,
    required this.nivelUsuario,
    required this.dtAtividade,
    this.dtAtividadeRealizada,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['idatividade'] ?? 0,
      nome: json['nmatividade'] ?? '',
      descricao: json['dsatividade'] ?? '',
      dificuldade: json['dificuldade'] ?? 'facil',
      situacao: json['situacao'] ?? 'ativa',
      recorrencia: json['recorrencia'] ?? 'unica',
      tpEstimado: json['tpestimado'] ?? 0,
      xp: json['expatividade'] ?? 0,
      nivelUsuario: json['nivelusuario'] ?? 1,
      dtAtividade: json['dtatividade'] ?? '',
      dtAtividadeRealizada: json['dtatividaderealizada'],
    );
  }

  // Métodos auxiliares para obter cores baseadas nos atributos
  Color get dificuldadeColor {
    switch (dificuldade.toLowerCase()) {
      case 'muito_facil':
        return AppColors.dificuldadeFacil;
      case 'facil':
        return AppColors.dificuldadeFacil;
      case 'medio':
        return AppColors.dificuldadeMedia;
      case 'dificil':
        return AppColors.dificuldadeDificil;
      case 'muito_dificil':
        return AppColors.dificuldadeMuitoDificil;
      default:
        return AppColors.cinzaSub;
    }
  }

  Color get situacaoColor {
    switch (situacao.toLowerCase()) {
      case 'ativa':
        return AppColors.situacaoAtiva;
      case 'pausada':
        return AppColors.situacaoPausada;
      case 'concluida':
        return AppColors.situacaoConcluida;
      case 'cancelada':
        return AppColors.situacaoCancelada;
      default:
        return AppColors.cinzaSub;
    }
  }

  Color get recorrenciaColor {
    switch (recorrencia.toLowerCase()) {
      case 'unica':
        return AppColors.recorrenciaUnica;
      case 'recorrente':
        return AppColors.recorrenciaRecorrente;
      default:
        return AppColors.cinzaSub;
    }
  }

  // Método para obter ícone baseado na dificuldade
  String get dificuldadeImage {
    final valor = dificuldade.toLowerCase().trim();
    switch (valor) {
      case 'muito_facil':
        return 'assets/images/dificuldade1.png';
      case 'facil':
        return 'assets/images/dificuldade2.png';
      case 'medio':
      case 'media':
        return 'assets/images/dificuldade3.png';
      case 'dificil':
        return 'assets/images/dificuldade4.png';
      case 'muito_dificil':
        return 'assets/images/dificuldade5.png';
      case 'extrema':
        return 'assets/images/dificuldade6.png';
      default:
        return 'assets/images/dificuldade_default.png'; // opcional, pode usar um “?” custom
    }
  }

  // Método para obter ícone baseado na recorrência
  IconData get recorrenciaIcon {
    switch (recorrencia.toLowerCase()) {
      case 'unica':
        return Icons.radio_button_unchecked;
      case 'recorrente':
        return Icons.autorenew;
      default:
        return Icons.help_outline;
    }
  }
}

// Classe auxiliar para filtros
class FilterHelpers {
  // Converte valores de dificuldade para nomes amigáveis
  static String getDificuldadeDisplayName(String dificuldade) {
    switch (dificuldade.toLowerCase()) {
      case 'muito_facil':
        return 'Muito Fácil';
      case 'facil':
        return 'Fácil';
      case 'medio':
        return 'Médio';
      case 'dificil':
        return 'Difícil';
      case 'muito_dificil':
        return 'Muito Difícil';
      case 'extrema':
        return 'Extrema';
      default:
        return dificuldade;
    }
  }

  // Converte valores de situação para nomes amigáveis
  static String getSituacaoDisplayName(String situacao) {
    switch (situacao.toLowerCase()) {
      case 'ativa':
        return 'Ativa';
      case 'pausada':
        return 'Pausada';
      case 'concluida':
        return 'Concluída';
      case 'realizada':
        return 'Realizada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return situacao;
    }
  }

  // Converte valores de recorrência para nomes amigáveis
  static String getRecorrenciaDisplayName(String recorrencia) {
    switch (recorrencia.toLowerCase()) {
      case 'unica':
        return 'Única';
      case 'recorrente':
        return 'Recorrente';
      default:
        return recorrencia;
    }
  }

  // Converte valores de tipo de desafio para nomes amigáveis
  static String getTipoDesafioDisplayName(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'diário':
        return 'Diário';
      case 'semanal':
        return 'Semanal';
      case 'mensal':
        return 'Mensal';
      case 'especial':
        return 'Especial';
      default:
        return tipo;
    }
  }

  // Lista de opções de dificuldade com valores e nomes
  static List<Map<String, String>> getDificuldadeOptions() {
    return [
      {'value': 'muito_facil', 'label': 'Muito Fácil'},
      {'value': 'facil', 'label': 'Fácil'},
      {'value': 'medio', 'label': 'Médio'},
      {'value': 'dificil', 'label': 'Difícil'},
      {'value': 'muito_dificil', 'label': 'Muito Difícil'},
    ];
  }

  // Lista de opções de situação com valores e nomes
  static List<Map<String, String>> getSituacaoOptions() {
    return [
      {'value': 'ativa', 'label': 'Ativa'},
      {'value': 'realizada', 'label': 'Realizada'},
      {'value': 'cancelada', 'label': 'Cancelada'},
    ];
  }

  // Lista de opções de recorrência com valores e nomes
  static List<Map<String, String>> getRecorrenciaOptions() {
    return [
      {'value': 'unica', 'label': 'Única'},
      {'value': 'recorrente', 'label': 'Recorrente'},
    ];
  }
}

class DesafioPendente {
  final int id;
  final String nome;
  final String descricao;
  final int xp;
  final String tipo;
  final bool completado;
  final int progresso;
  final int meta;

  DesafioPendente({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.xp,
    required this.tipo,
    required this.completado,
    required this.progresso,
    required this.meta,
  });

  factory DesafioPendente.fromJson(Map<String, dynamic> json) {
    return DesafioPendente(
      id: json['iddesafio'],
      nome: json['nmdesafio'],
      descricao: json['dsdesafio'] ?? 'Sem descrição',
      xp: json['expdesafio'],
      tipo: json['tipo_display'],
      completado: json['completado'] ?? false,
      progresso: json['progresso'] ?? 0,
      meta: json['meta'] ?? 1,
    );
  }
}

class Conquista {
  final int id;
  final String nome;
  final String descricao;
  final String imagem;
  final int xp;
  final String dataDesbloqueio;
  final bool completada;

  Conquista({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imagem,
    required this.xp,
    required this.dataDesbloqueio,
    required this.completada,
  });

  factory Conquista.fromJson(Map<String, dynamic> json) {
    // Se o JSON tem a estrutura do endpoint de usuário (com 'conquista' e 'dtconcessao')
    final conquistaData = json['conquista'] ?? json;
    final dataConcessao = json['dtconcessao'] ?? '';

    return Conquista(
      id: conquistaData['idconquista'] ?? 0,
      nome: conquistaData['nmconquista'] ?? 'Conquista sem nome',
      descricao: conquistaData['dsconquista'] ?? '',
      imagem: conquistaData['nmimagem'] ?? 'relogio.png',
      xp: conquistaData['expconquista'] ?? 0,
      dataDesbloqueio: dataConcessao,
      // Se tem data de concessão, significa que foi desbloqueada
      completada: dataConcessao.isNotEmpty,
    );
  }

  // Factory para conquistas do endpoint geral (todas as conquistas)
  factory Conquista.fromAllConquistasJson(Map<String, dynamic> json) {
    return Conquista(
      id: json['idconquista'] ?? 0,
      nome: json['nmconquista'] ?? 'Conquista sem nome',
      descricao: json['dsconquista'] ?? '',
      imagem: json['nmimagem'] ?? 'relogio.png',
      xp: json['expconquista'] ?? 0,
      dataDesbloqueio: '', // Não tem data de concessão no endpoint geral
      completada: json['completada'] ?? false, // Vem do serializer do backend
    );
  }
}

// Modelo para as notificações
class Notificacao {
  final int id;
  final String mensagem;
  final String tipo;
  final bool lida;

  Notificacao({
    required this.id,
    required this.mensagem,
    required this.tipo,
    required this.lida,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['idnotificacao'] ?? 0,
      mensagem: json['dsmensagem'] ?? 'Mensagem indisponível',
      tipo: json['fltipo'] ?? 'info',
      lida: json['flstatus'] ?? false,
    );
  }
}
