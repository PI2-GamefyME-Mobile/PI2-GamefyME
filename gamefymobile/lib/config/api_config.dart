import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

/// Configuração centralizada da API
class ApiConfig {
  /// Permite sobrescrever via `--dart-define=API_BASE_URL=...`
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL base da API (dinâmica por plataforma, com override por env)
  static String get baseUrl {
    // 1) Se vier por env, usa ela (útil para dispositivo físico na mesma rede)
    if (_envBaseUrl.isNotEmpty) {
      debugPrint('🌐 [CONFIG] Usando API_BASE_URL do env: $_envBaseUrl');
      return _envBaseUrl;
    }

    // 2) Descoberta automática por plataforma/ambiente
    if (kIsWeb) {
      // Web acessa o host da própria máquina
      debugPrint('🌐 [CONFIG] Plataforma: Web - URL: http://localhost:8000/api');
      return 'http://localhost:8000/api';
    }

    // Evita acessar Platform.* quando rodando na Web
    try {
      if (Platform.isAndroid) {
        // Para dispositivo físico, usa o IP da rede local
        // Para emulador Android, use 10.0.2.2
        debugPrint('🌐 [CONFIG] Plataforma: Android - URL: http://192.168.114.159:8000/api');
        return 'http://192.168.114.159:8000/api';
      }
      if (Platform.isIOS) {
        // Simulador iOS acessa via localhost
        debugPrint('🌐 [CONFIG] Plataforma: iOS - URL: http://localhost:8000/api');
        return 'http://localhost:8000/api';
      }
    } catch (_) {
      // Fallback seguro caso Platform não esteja disponível
    }

    // 3) Fallback genérico (Desktop/dev)
    debugPrint('🌐 [CONFIG] Plataforma: Desktop/Fallback - URL: http://127.0.0.1:8000/api');
    return 'http://127.0.0.1:8000/api';
  }

  /// Alias para manter compatibilidade com chamadas existentes
  static String get apiBaseUrl => baseUrl;
}
