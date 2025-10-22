import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  // Getters para cores dinâmicas
  Color get fundoApp => _isDarkMode ? AppColors.fundoEscuro : AppColors.fundoClaro;
  Color get fundoCard => _isDarkMode ? AppColors.fundoCardEscuro : const Color.fromARGB(255, 199, 199, 199);
  Color get textoTexto => _isDarkMode ? AppColors.textoEscuro : AppColors.textoClaro;
  Color get textoCinza => _isDarkMode ? AppColors.cinzaSubEscuro : AppColors.cinzaSubClaro;
  Color get fundoDropDown => _isDarkMode ? AppColors.fundoDropDownEscuro : AppColors.fundoDropDownClaro;
  Color get botaoDropDown => _isDarkMode ? AppColors.botaoDropDownEscuro : AppColors.botaoDropDownClaro;
  Color get cardAtividade => _isDarkMode ? AppColors.roxoHeader : AppColors.fundoEscuro;
  Color get leaderboard => _isDarkMode ? AppColors.fundoCardEscuro : const Color.fromARGB(255, 199, 199, 199);
  Color get leaderboardPerfil => _isDarkMode ? AppColors.roxoHeader : AppColors.fundoEscuro;
  Color get textoAtividade => _isDarkMode ? AppColors.branco : AppColors.branco;
  Color get desafioCompleto => _isDarkMode ? AppColors.roxoHeader : AppColors.fundoEscuro;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Método helper para obter ThemeData
  ThemeData get themeData {
    return ThemeData(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: fundoApp,
      primaryColor: AppColors.roxoHeader,
      cardColor: fundoCard,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textoTexto),
        bodyMedium: TextStyle(color: textoTexto),
        bodySmall: TextStyle(color: textoCinza),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.roxoHeader,
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primary: AppColors.roxoHeader,
        onPrimary: Colors.white,
        secondary: AppColors.verdeLima,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        surface: fundoCard,
        onSurface: textoTexto,
      ),
    );
  }
}
