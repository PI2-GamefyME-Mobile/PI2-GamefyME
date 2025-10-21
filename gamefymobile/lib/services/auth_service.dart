import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String _baseUrl = "http://127.0.0.1:8000/api/usuarios";
  // final String _baseUrl = "http://192.168.100.114:8000/api/usuarios";
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

  Future<bool> validateSession() async {
    try {
      final access = await _storage.read(key: 'access_token');
      if (access == null) return false;
      final url = Uri.parse("$_baseUrl/me/");
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $access',
        },
      );
      if (response.statusCode == 200) {
        return true;
      }
      // se inválido, limpar tokens
      await logout();
      return false;
    } catch (e) {
      debugPrint("Erro ao validar sessão: $e");
      return false;
    }
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

  /// Login com Google - envia o token do Google para o backend
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    required String email,
    required String name,
    required String googleId,
  }) async {
    final url = Uri.parse("$_baseUrl/login/google/");
    final body = jsonEncode({
      // backend aceita id_token/token/access_token
      'id_token': idToken,
      'email': email,
      'name': name,
      'google_id': googleId,
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
        return {'success': true, 'message': 'Login com Google realizado!'};
      } else {
        return {'success': false, 'message': responseBody['error'] ?? responseBody['detail'] ?? responseBody['erro'] ?? 'Erro no login com Google.'};
      }
    } catch (e) {
      debugPrint("Erro na requisição de login com Google: $e");
      return {'success': false, 'message': 'Erro de conexão. Verifique se a API está rodando.'};
    }
  }

  /// Registro com Google - cria uma nova conta usando Google
  Future<Map<String, dynamic>> registerWithGoogle({
    required String idToken,
    required String email,
    required String name,
    required String googleId,
  }) async {
    final url = Uri.parse("$_baseUrl/cadastro/google/");
    final body = jsonEncode({
      // backend aceita id_token/token/access_token
      'id_token': idToken,
      'email': email,
      'name': name,
      'google_id': googleId,
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
        return {'success': true, 'message': responseBody['message'] ?? 'Conta criada com sucesso!'};
      } else {
        return {'success': false, 'message': responseBody['error'] ?? responseBody['erro'] ?? 'Erro ao criar conta com Google.'};
      }
    } catch (e) {
      debugPrint("Erro na requisição de cadastro com Google: $e");
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
  
  Future<bool> refreshAccessToken() async {
  final refreshToken = await _storage.read(key: 'refresh_token');
  if (refreshToken == null) return false;

  final url = Uri.parse("$_baseUrl/token/refresh/");
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String newAccess = data['access'];
      await _storage.write(key: 'access_token', value: newAccess);
      return true;
    } else {
      return false;
    }
  } catch (e) {
    debugPrint("Erro ao renovar token: $e");
    return false;
  }
}
}