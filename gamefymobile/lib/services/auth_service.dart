import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String _baseUrl = "http://127.0.0.1:8000/api/usuarios";
  final _storage = const FlutterSecureStorage();

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse("$_baseUrl/login/");
    final body = jsonEncode({
      'emailusuario': email,
      'password': senha,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final String accessToken = responseBody['tokens']['access'];
        final String refreshToken = responseBody['tokens']['refresh'];
        await _saveTokens(accessToken, refreshToken);
        return {'success': true, 'message': 'Login bem-sucedido!'};
      } else {
        return {'success': false, 'message': responseBody['detail'] ?? responseBody['erro'] ?? 'Credenciais inválidas.'};
      }
    } catch (e) {
      debugPrint("Erro na requisição de login: $e");
      return {'success': false, 'message': 'Erro de conexão. Verifique se a API está rodando.'};
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
    required String confSenha,
  }) async {
    final url = Uri.parse("$_baseUrl/cadastro/");
    final body = jsonEncode({
      'nmusuario': nome,
      'emailusuario': email,
      'senha': senha,
      'confsenha': confSenha,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final String accessToken = responseBody['tokens']['access'];
        final String refreshToken = responseBody['tokens']['refresh'];
        await _saveTokens(accessToken, refreshToken);
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {'success': false, 'message': responseBody['erro'] ?? 'Ocorreu um erro no cadastro.'};
      }
    } catch (e) {
      debugPrint("Erro na requisição de cadastro: $e");
      return {'success': false, 'message': 'Erro de conexão. Verifique se a API está rodando.'};
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse("$_baseUrl/password-reset/");
    final body = jsonEncode({'email': email});
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final responseBody = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': responseBody['message'] ?? responseBody['error']};
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão.'};
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset(String email, String token, String newPassword, String confirmPassword) async {
    final url = Uri.parse("$_baseUrl/password-reset/confirm/");
    final body = jsonEncode({
      'email': email,
      'token': token,
      'new_password': newPassword,
      'confirm_password': confirmPassword
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      final responseBody = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': responseBody['message'] ?? responseBody['error']};
    } catch(e) {
       return {'success': false, 'message': 'Erro de conexão.'};
    }
  }
}