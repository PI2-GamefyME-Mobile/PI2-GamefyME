import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final AuthService _authService = AuthService();

  /// Verifica se o usuário já está logado com Google
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      debugPrint('Erro ao verificar login do Google: $e');
      return false;
    }
  }

  /// Faz login com Google e registra/autentica no backend
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Tenta fazer login silencioso primeiro
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      
      // Se não conseguir, faz login interativo
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return {
          'success': false,
          'message': 'Login cancelado pelo usuário',
        };
      }

      // Obtém os dados do usuário
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        return {
          'success': false,
          'message': 'Não foi possível obter token do Google',
        };
      }

      debugPrint('Google Sign In - Email: ${account.email}');
      debugPrint('Google Sign In - Nome: ${account.displayName}');
      debugPrint('Google Sign In - ID: ${account.id}');

      // Tenta fazer login no backend com o token do Google
      final result = await _authService.loginWithGoogle(
        idToken: idToken,
        email: account.email,
        name: account.displayName ?? account.email,
        googleId: account.id,
      );

      if (result['success'] == true) {
        return {
          'success': true,
          'message': 'Login com Google realizado com sucesso',
          'user': account,
        };
      } else {
        // Se o login falhou, pode ser que o usuário não existe
        // Tenta registrar automaticamente
        final registerResult = await _authService.registerWithGoogle(
          idToken: idToken,
          email: account.email,
          name: account.displayName ?? account.email,
          googleId: account.id,
        );

        if (registerResult['success'] == true) {
          return {
            'success': true,
            'message': 'Conta criada e login realizado com sucesso',
            'user': account,
            'isNewUser': true,
          };
        } else {
          return {
            'success': false,
            'message': registerResult['message'] ?? 'Erro ao autenticar com Google',
          };
        }
      }
    } catch (error) {
      debugPrint('Erro no login com Google: $error');
      return {
        'success': false,
        'message': 'Erro ao fazer login com Google: $error',
      };
    }
  }

  /// Faz logout do Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _authService.logout();
      debugPrint('Logout do Google realizado com sucesso');
    } catch (error) {
      debugPrint('Erro ao fazer logout do Google: $error');
    }
  }

  /// Desconecta completamente a conta Google do app
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await _authService.logout();
      debugPrint('Conta Google desconectada com sucesso');
    } catch (error) {
      debugPrint('Erro ao desconectar conta Google: $error');
    }
  }

  /// Obtém a conta atual do Google (se houver)
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
