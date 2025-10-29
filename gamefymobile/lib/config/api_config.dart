import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      debugPrint('🌐 [CONFIG] Usando API_BASE_URL do env: $_envBaseUrl');
      return _envBaseUrl;
    }

    if (kIsWeb) {
      debugPrint(
          '🌐 [CONFIG] Plataforma: Web - URL: http://localhost:8000/api');
      return 'http://localhost:8000/api';
    }

    // IP do Felipe
    // try {
    //   if (Platform.isAndroid) {
    //     debugPrint(
    //         '🌐 [CONFIG] Plataforma: Android - URL: http://192.168.114.159:8000/api');
    //     return 'http://192.168.114.159:8000/api';
    //   }
    // } catch (_) {
    //   // Fallback seguro caso Platform não esteja disponível
    // }

    // IP do Lucas
    try {
      if (Platform.isAndroid) {
        debugPrint(
            '🌐 [CONFIG] Plataforma: Android - URL: http://192.168.xxx:8000/api');
        return 'http://192.168.xxx:8000/api';
      }
    } catch (_) {
      // Fallback seguro caso Platform não esteja disponível
    }

    debugPrint(
        '🌐 [CONFIG] Plataforma: Desktop/Fallback - URL: http://127.0.0.1:8000/api');
    return 'http://127.0.0.1:8000/api';
  }

  static String get apiBaseUrl => baseUrl;
}
