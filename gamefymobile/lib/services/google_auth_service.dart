import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final AuthService _authService = AuthService();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await _googleSignIn.initialize(
      clientId: Platform.isAndroid
          ? '848375608749-qnlq0liglen8dausgo29o6obl0m2v8qd.apps.googleusercontent.com'
          : null,
    );
    // await _googleSignIn.initialize(
    //   clientId: kIsWeb
    //       ? '848375608749-rcc8rfvbfhqg8i21b6ouiisf20t9a2hq.apps.googleusercontent.com'
    //       : null,
    // );

    _initialized = true;
  }

  Future<bool> isSignedIn() async {
    try {
      await _ensureInitialized();
      final user = await _googleSignIn.attemptLightweightAuthentication();
      return user != null;
    } catch (e) {
      debugPrint('Erro ao verificar login do Google: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      debugPrint('[GOOGLE] Iniciando Google Sign In...');
      await _ensureInitialized();

      GoogleSignInAccount? user; // Alterado para aceitar nulo
      if (kIsWeb) {
        // ... (Sua lógica web)
        return {
          'success': false,
          'message':
              'No Web, use o botão Google nativo (GIS). Implementação pendente na UI.',
        };
      } else {
        debugPrint('[GOOGLE] Chamando authenticate...');
        user = await _googleSignIn.authenticate(); //
      }

      // Verifica se o usuário cancelou o login
      if (user == null) {
        debugPrint('[GOOGLE] Usuário cancelou o login.');
        return {
          'success': false,
          'message': 'Login cancelado pelo usuário',
        };
      }

      // 1. Obter o objeto de autenticação
      final GoogleSignInAuthentication auth = await user.authentication;

      // 2. Extrair o idToken (JWT)
      final String? idToken = auth.idToken;

      if (idToken == null) {
        debugPrint('[GOOGLE] Erro: Não foi possível obter o idToken.');
        return {
          'success': false,
          'message': 'Não foi possível obter o ID Token do Google.'
        };
      }

      // 3. Usar o idToken (e não mais o user.id) nas chamadas para seu backend

      // ---- FIM DA CORREÇÃO ----

      debugPrint('[GOOGLE] Google Sign In - Email: ${user.email}');
      debugPrint('[GOOGLE] Google Sign In - Nome: ${user.displayName}');
      debugPrint('[GOOGLE] Google Sign In - ID: ${user.id}');

      debugPrint('[GOOGLE] Tentando login no backend com o ID Token...');
      final loginResult = await _authService.loginWithGoogle(
        idToken: idToken, // <-- CORRIGIDO
        email: user.email,
        name: user.displayName ?? user.email,
        googleId: user.id,
      );

      if (loginResult['success'] == true) {
        debugPrint('[GOOGLE] Login bem-sucedido!');
        return {
          'success': true,
          'message': 'Login com Google realizado com sucesso',
          'user': user,
        };
      } else {
        debugPrint('[GOOGLE] Login falhou, tentando cadastro...');
        final registerResult = await _authService.registerWithGoogle(
          idToken: idToken, // <-- CORRIGIDO
          email: user.email,
          name: user.displayName ?? user.email,
          googleId: user.id,
        );

        if (registerResult['success'] == true) {
          debugPrint('[GOOGLE] Cadastro bem-sucedido!');
          return {
            'success': true,
            'message': 'Conta criada e login realizado com sucesso',
            'user': user,
            'isNewUser': true,
          };
        } else {
          // ... (resto do seu tratamento de erro)
        }
      }
    } on GoogleSignInException catch (e) {
      // ... (resto do seu tratamento de erro)
    } catch (error) {
      // ... (resto do seu tratamento de erro)
    }
    // Adicionado retorno de falha genérico para garantir que todos os caminhos retornem
    return {
      'success': false,
      'message': 'Ocorreu um erro inesperado durante o login com Google.',
    };
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.disconnect();
      await _authService.logout();
      debugPrint('Logout do Google realizado com sucesso');
    } catch (error) {
      debugPrint('Erro ao fazer logout do Google: $error');
    }
  }

  Future<void> disconnect() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.disconnect();
      await _authService.logout();
      debugPrint('Conta Google desconectada com sucesso');
    } catch (error) {
      debugPrint('Erro ao desconectar conta Google: $error');
    }
  }

  Future<GoogleSignInAccount?> get currentUser async {
    try {
      await _ensureInitialized();
      final user = await _googleSignIn.attemptLightweightAuthentication();
      return user;
    } catch (e) {
      debugPrint('Erro ao obter usuário atual: $e');
      return null;
    }
  }
}
