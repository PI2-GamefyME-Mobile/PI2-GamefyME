import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/models.dart';

class ApiService {
  final AuthService _authService = AuthService();
  static const String _baseRoot = 'http://127.0.0.1:8000/api';

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
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      return Usuario.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    } else {
      throw Exception('Falha ao carregar dados do usuário');
    }
  }

  Future<List<Atividade>> fetchAtividades() async {
    final url = Uri.parse('$_baseRoot/atividades/');
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar atividades');
    }
  }

  Future<Atividade> fetchAtividade(int atividadeId) async {
    final url = Uri.parse('$_baseRoot/atividades/$atividadeId/');
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
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

  Future<List<Conquista>> fetchUsuarioConquistas() async {
    final url = Uri.parse('$_baseRoot/conquistas/');
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Conquista.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar conquistas do usuário');
    }
  }

  Future<List<DesafioPendente>> fetchDesafiosPendentes() async {
    final url = Uri.parse('$_baseRoot/desafios/');
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
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
  final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
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
    final res = await _authorizedRequest((headers) => http.get(url, headers: headers));
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Usuario.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar a leaderboard');
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

}
