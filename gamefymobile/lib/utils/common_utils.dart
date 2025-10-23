import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../config/theme_provider.dart';
import '../models/models.dart';

class CommonUtils {
  // Validação de email
  static bool validEmail(String email) {
    final regex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  // Widget de campo de texto reutilizável
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLines = 1,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeProvider.textoTexto,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(color: themeProvider.textoTexto),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: themeProvider.textoCinza),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: themeProvider.fundoCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.verdeLima, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Widget de seletor de dificuldade reutilizável
  static Widget buildDificuldadeSelector({
    required BuildContext context,
    required int dificuldadeSelecionada,
    required Function(int) onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dificuldades = ['muito_facil', 'facil', 'medio', 'dificil', 'muito_dificil'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        bool isSelected = index == dificuldadeSelecionada;
        final dificuldade = dificuldades[index];
        
        return GestureDetector(
          onTap: () => onChanged(index),
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/dificuldade${index + 1}.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  FilterHelpers.getDificuldadeDisplayName(dificuldade),
                  style: TextStyle(
                    color: isSelected ? themeProvider.textoTexto : themeProvider.textoCinza,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Widget de seletor de recorrência reutilizável
  static Widget buildRecorrenciaSelector({
    required BuildContext context,
    required String recorrenciaSelecionada,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildRecorrenciaButton(
            context,
            'ÚNICA', 
            'unica', 
            recorrenciaSelecionada, 
            onChanged
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildRecorrenciaButton(
            context,
            'RECORRENTE', 
            'recorrente', 
            recorrenciaSelecionada, 
            onChanged
          ),
        ),
      ],
    );
  }

  static Widget _buildRecorrenciaButton(
    BuildContext context,
    String text, 
    String value, 
    String recorrenciaSelecionada, 
    Function(String) onChanged
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isSelected = recorrenciaSelecionada == value;
    return ElevatedButton(
      onPressed: () => onChanged(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.roxoClaro : themeProvider.fundoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? themeProvider.textoTexto : themeProvider.textoCinza,
        ),
      ),
    );
  }

  // Widget de título de seção reutilizável
  static Widget buildSectionTitle(BuildContext context, String title) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Text(
      title,
      style: TextStyle(
        color: themeProvider.textoTexto,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Validação de campos obrigatórios
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  // Validação de email com mensagem personalizada
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    if (!validEmail(value)) {
      return 'Email inválido';
    }
    return null;
  }

  // Validação de senha
  // RN 06: Mínimo 6 caracteres, 1 maiúscula e 1 caractere especial
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    // Verifica se tem pelo menos uma letra maiúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Senha deve conter pelo menos uma letra maiúscula';
    }
    // Verifica se tem pelo menos um caractere especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\;/]').hasMatch(value)) {
      return 'Senha deve conter pelo menos um caractere especial';
    }
    return null;
  }

  // Validação de confirmação de senha
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != password) {
      return 'As senhas não coincidem';
    }
    return null;
  }
}

