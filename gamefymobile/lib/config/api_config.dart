/// Configuração centralizada da API
class ApiConfig {
  // URL base da API
  // Para rodar no PC local
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Para rodar no celular (descomente e ajuste o IP)
  // static const String baseUrl = 'http://192.168.100.114:8000/api';
  
  // Para ambiente de produção
  // static const String baseUrl = 'https://seu-dominio.com/api';
  
  /// Retorna a URL base configurada
  static String get apiBaseUrl => baseUrl;
}
