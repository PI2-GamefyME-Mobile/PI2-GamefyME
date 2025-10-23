import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/models.dart';
import '../config/api_config.dart';

class ApiService {
  final AuthService _authService = AuthService();
  static String get _baseRoot => ApiConfig.apiBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  Future<Usuario> fetchUsuario() async {
    final url = Uri.parse('$_baseRoot/usuarios/me/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      return Usuario.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    } else {
      throw Exception('Falha ao carregar dados do usuário');
    }
  }

  Future<List<Atividade>> fetchAtividades({
    DateTime? startDate,
    DateTime? endDate,
    bool byConclusao = false,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) query['end_date'] = endDate.toIso8601String().substring(0, 10);
    if (byConclusao) query['by'] = 'conclusao';
    final url = Uri.parse('$_baseRoot/atividades/').replace(queryParameters: query.isEmpty ? null : query);
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar atividades');
    }
  }

  Future<List<Atividade>> fetchHistoricoAtividades({
    DateTime? startDate,
    DateTime? endDate,
    bool byConclusao = false,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) query['end_date'] = endDate.toIso8601String().substring(0, 10);
    if (byConclusao) query['by'] = 'conclusao';
    final url = Uri.parse('$_baseRoot/atividades/historico/').replace(queryParameters: query.isEmpty ? null : query);
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar histórico de atividades');
    }
  }

  Future<Atividade> fetchAtividade(int atividadeId) async {
    final url = Uri.parse('$_baseRoot/atividades/$atividadeId/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      return Atividade.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    } else {
      throw Exception('Falha ao carregar detalhes da atividade');
    }
  }

  Future<bool> deleteAtividade(int atividadeId) async {
    final url = Uri.parse('$_baseRoot/atividades/$atividadeId/');
    try {
      final response = await http.delete(url, headers: await _getHeaders());
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Erro ao deletar atividade: $e');
      return false;
    }
  }

  Future<bool> cancelAtividade(int atividadeId) async {
    final url = Uri.parse('$_baseRoot/atividades/$atividadeId/cancelar/');
    try {
      final response = await http.post(url, headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao cancelar atividade: $e');
      return false;
    }
  }

  Future<bool> updateProfilePicture(String avatarName) async {
    final url = Uri.parse('$_baseRoot/usuarios/me/');
    final body = jsonEncode({'imagem_perfil': avatarName});
    try {
      final response =
          await http.patch(url, headers: await _getHeaders(), body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao atualizar a foto de perfil: $e');
      return false;
    }
  }

  Future<List<Conquista>> fetchConquistas({bool todasConquistas = false}) async {
    final url = Uri.parse('$_baseRoot/conquistas/${todasConquistas ? '' : 'usuario/'}'); 
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      if (todasConquistas) {
        return data.map((e) => Conquista.fromAllConquistasJson(e)).toList();
      } else {
        return data.map((e) => Conquista.fromJson(e)).toList();
      }
    } else {
      throw Exception('Falha ao carregar conquistas');
    }
  }

  Future<List<DesafioPendente>> fetchDesafiosPendentes() async {
    final url = Uri.parse('$_baseRoot/desafios/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => DesafioPendente.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar desafios');
    }
  }

  Future<bool> realizarAtividade(int atividadeId) async {
    final url = Uri.parse('$_baseRoot/atividades/$atividadeId/realizar/');
    final res = await http.post(url, headers: await _getHeaders());
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>> cadastrarAtividade({
    required String nome,
    required String descricao,
    required String dificuldade,
    required String recorrencia,
    required int tpEstimado,
  }) async {
    final url = Uri.parse('$_baseRoot/atividades/');
    final body = jsonEncode({
      'nmatividade': nome,
      'dsatividade': descricao,
      'dificuldade': dificuldade,
      'recorrencia': recorrencia,
      'tpestimado': tpEstimado,
      'dtatividade': DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: body,
      );
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Atividade criada com sucesso!'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {'success': false, 'message': responseBody.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<List<Notificacao>> fetchNotificacoes() async {
    final url = Uri.parse('$_baseRoot/notificacoes/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Notificacao.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar notificações: ${res.statusCode}');
    }
  }

  Future<void> marcarNotificacaoComoLida(int notificacaoId) async {
    final url = Uri.parse(
      '$_baseRoot/notificacoes/$notificacaoId/marcar-como-lida/',
    );
    await http.post(url, headers: await _getHeaders());
  }

  Future<void> marcarTodasNotificacoesComoLidas() async {
    final url = Uri.parse('$_baseRoot/notificacoes/marcar-todas-como-lidas/');
    try {
      await http.post(url, headers: await _getHeaders());
    } catch (e) {
      debugPrint('Erro ao marcar todas notificações como lidas: $e');
    }
  }

  Future<Map<String, dynamic>> updateAtividade({
    required int id,
    required String nome,
    required String descricao,
    required String dificuldade,
    required String recorrencia,
    required int tpEstimado,
    required String dtAtividade,
  }) async {
    final url = Uri.parse('$_baseRoot/atividades/$id/');
    final body = jsonEncode({
      'nmatividade': nome,
      'dsatividade': descricao,
      'dificuldade': dificuldade,
      'recorrencia': recorrencia,
      'tpestimado': tpEstimado,
      'dtatividade': dtAtividade,
    });

    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: body,
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Atividade atualizada com sucesso!'
        };
      } else {
        final responseBody = jsonDecode(response.body);
        return {'success': false, 'message': responseBody.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$_baseRoot/usuarios/password-reset/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao solicitar a redefinição de senha.');
    }
  }

  Future<void> confirmPasswordReset(
      String uidb64, String token, String password) async {
    final response = await http.post(
      Uri.parse('$_baseRoot/usuarios/password-reset/confirm/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uidb64': uidb64,
        'token': token,
        'password': password,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao confirmar a redefinição de senha.');
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required String nome,
    required String email,
  }) async {
    final url = Uri.parse('$_baseRoot/usuarios/me/');
    final body = jsonEncode({
      'nmusuario': nome,
      'emailusuario': email,
    });

    try {
      final response = await http.patch(
        url,
        headers: await _getHeaders(),
        body: body,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Dados atualizados com sucesso!'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {'success': false, 'message': responseBody.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<List<Usuario>> fetchLeaderboard() async {
    final url = Uri.parse('$_baseRoot/usuarios/leaderboard/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Usuario.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar a leaderboard');
    }
  }

  Future<Estatisticas> fetchEstatisticas() async {
    final url = Uri.parse('$_baseRoot/usuarios/estatisticas/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return Estatisticas.fromJson(data);
    } else {
      throw Exception('Falha ao carregar estatísticas');
    }
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String>) requestFn,
  ) async {
    var headers = await _getHeaders();
    var response = await requestFn(headers);

    if (response.statusCode == 401) {
      // tenta renovar token
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed) {
        headers = await _getHeaders();
        response = await requestFn(headers);
      }

      // se ainda der 401 → forçar logout
      if (response.statusCode == 401) {
        await _authService.logout();
        // aqui você pode navegar para login:
        // Navigator.of(context).pushReplacementNamed('/login');
      }
    }
    return response;
  }

  Future<List<dynamic>> fetchStreakStatus() async {
    final url = Uri.parse('$_baseRoot/atividades/streak-status/');
    final res =
        await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      // A API já retorna uma lista, então decodificamos diretamente
      return json.decode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('Falha ao carregar o status do streak');
    }
  }

  // ===== MÉTODOS DE ADMINISTRAÇÃO - DESAFIOS =====
  
  Future<List<dynamic>> fetchDesafiosAdmin() async {
    final url = Uri.parse('$_baseRoot/desafios/admin/');
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('Falha ao carregar desafios (admin)');
    }
  }

  Future<void> criarDesafio(Map<String, dynamic> dados) async {
    final url = Uri.parse('$_baseRoot/desafios/admin/');
    final res = await _authorizedRequest(
      (headers) => http.post(url, headers: headers, body: json.encode(dados)),
    );
    if (res.statusCode != 201) {
      final error = json.decode(utf8.decode(res.bodyBytes));
      throw Exception('Erro ao criar desafio: ${error.toString()}');
    }
  }

  Future<void> atualizarDesafio(int id, Map<String, dynamic> dados) async {
    final url = Uri.parse('$_baseRoot/desafios/admin/$id/');
    final res = await _authorizedRequest(
      (headers) => http.put(url, headers: headers, body: json.encode(dados)),
    );
    if (res.statusCode != 200) {
      final error = json.decode(utf8.decode(res.bodyBytes));
      throw Exception('Erro ao atualizar desafio: ${error.toString()}');
    }
  }

  Future<void> excluirDesafio(int id) async {
    final url = Uri.parse('$_baseRoot/desafios/admin/$id/');
    final res = await _authorizedRequest(
      (headers) => http.delete(url, headers: headers),
    );
    if (res.statusCode != 204) {
      throw Exception('Erro ao excluir desafio');
    }
  }

  // ===== MÉTODOS DE ADMINISTRAÇÃO - CONQUISTAS =====
  
  Future<List<dynamic>> fetchConquistasAdmin() async {
    final url = Uri.parse('$_baseRoot/conquistas/admin/');
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    } else {
      throw Exception('Falha ao carregar conquistas (admin)');
    }
  }

  Future<void> criarConquista(Map<String, dynamic> dados) async {
    final url = Uri.parse('$_baseRoot/conquistas/admin/');
    final res = await _authorizedRequest(
      (headers) => http.post(url, headers: headers, body: json.encode(dados)),
    );
    if (res.statusCode != 201) {
      final error = json.decode(utf8.decode(res.bodyBytes));
      throw Exception('Erro ao criar conquista: ${error.toString()}');
    }
  }

  Future<void> atualizarConquista(int id, Map<String, dynamic> dados) async {
    final url = Uri.parse('$_baseRoot/conquistas/admin/$id/');
    final res = await _authorizedRequest(
      (headers) => http.put(url, headers: headers, body: json.encode(dados)),
    );
    if (res.statusCode != 200) {
      final error = json.decode(utf8.decode(res.bodyBytes));
      throw Exception('Erro ao atualizar conquista: ${error.toString()}');
    }
  }

  Future<void> excluirConquista(int id) async {
    final url = Uri.parse('$_baseRoot/conquistas/admin/$id/');
    final res = await _authorizedRequest(
      (headers) => http.delete(url, headers: headers),
    );
    if (res.statusCode != 204) {
      throw Exception('Erro ao excluir conquista');
    }
  }

  // ===== GERENCIAMENTO DE CONTA =====
  
  Future<Map<String, dynamic>> inativarConta() async {
    final url = Uri.parse('$_baseRoot/usuarios/inativar/');
    try {
      final response = await http.post(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Conta inativada com sucesso.'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {'success': false, 'message': responseBody['erro'] ?? 'Erro ao inativar conta.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<String> uploadImagemConquista(String filePath) async {
    final url = Uri.parse('$_baseRoot/conquistas/admin/upload-image/');
    final token = await _authService.getToken();
    
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', filePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['filename'];
    } else {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(error['error'] ?? 'Erro ao fazer upload da imagem');
    }
  }
}
