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

  /// Inicializa o GoogleSignIn (obrigatório na versão 7.x)
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    await _googleSignIn.initialize(
      clientId: kIsWeb 
          ? '848375608749-rcc8rfvbfhqg8i21b6ouiisf20t9a2hq.apps.googleusercontent.com'
          : null,
    );
    
    _initialized = true;
  }

  /// Verifica se o usuário já está logado com Google
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

  /// Faz login com Google e registra/autentica no backend
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      debugPrint('🔍 [GOOGLE] Iniciando Google Sign In...');
      await _ensureInitialized();
      
      // Em Web, limpar sessão antes para evitar conflitos com One Tap/FedCM
      if (kIsWeb) {
        try { 
          await _googleSignIn.disconnect();
        } catch (_) {}
      }
      
      // Faz login usando authenticate (novo método na v7.x)
      // Se o usuário cancelar, uma exceção GoogleSignInException é lançada
      debugPrint('🔐 [GOOGLE] Chamando authenticate...');
      final user = await _googleSignIn.authenticate();

      debugPrint('✅ [GOOGLE] Google Sign In - Email: ${user.email}');
      debugPrint('✅ [GOOGLE] Google Sign In - Nome: ${user.displayName}');
      debugPrint('✅ [GOOGLE] Google Sign In - ID: ${user.id}');

      // Na versão 7.x, usamos o ID do usuário como identificador único
      // O backend deve validar com o Google usando este ID
      final token = user.id;

      debugPrint('🔄 [GOOGLE] Tentando login no backend...');
      // Tenta fazer login no backend com o token do Google
      final loginResult = await _authService.loginWithGoogle(
        idToken: token,
        email: user.email,
        name: user.displayName ?? user.email,
        googleId: user.id,
      );

      if (loginResult['success'] == true) {
        debugPrint('🎉 [GOOGLE] Login bem-sucedido!');
        return {
          'success': true,
          'message': 'Login com Google realizado com sucesso',
          'user': user,
        };
      } else {
        debugPrint('⚠️ [GOOGLE] Login falhou, tentando cadastro...');
        // Se o login falhou, pode ser que o usuário não existe
        // Tenta registrar automaticamente
        final registerResult = await _authService.registerWithGoogle(
          idToken: token,
          email: user.email,
          name: user.displayName ?? user.email,
          googleId: user.id,
        );

        if (registerResult['success'] == true) {
          debugPrint('🎉 [GOOGLE] Cadastro bem-sucedido!');
          return {
            'success': true,
            'message': 'Conta criada e login realizado com sucesso',
            'user': user,
            'isNewUser': true,
          };
        } else {
          debugPrint('❌ [GOOGLE] Cadastro falhou: ${registerResult['message']}');
          return {
            'success': false,
            'message': registerResult['message'] ?? 'Erro ao autenticar com Google',
          };
        }
      }
    } on GoogleSignInException catch (e) {
      debugPrint('❌ [GOOGLE] Erro GoogleSignIn: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return {
          'success': false,
          'message': 'Login cancelado pelo usuário',
        };
      }
      return {
        'success': false,
        'message': e.description ?? 'Erro ao fazer login com Google',
      };
    } catch (error) {
      debugPrint('❌ [GOOGLE] Erro no login com Google: $error');
      try { await _googleSignIn.disconnect(); } catch (_) {}
      return {
        'success': false,
        'message': 'Erro ao fazer login com Google: $error',
      };
    }
  }

  /// Faz logout do Google
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

  /// Desconecta completamente a conta Google do app
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

  /// Obtém a conta atual do Google (se houver)
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
