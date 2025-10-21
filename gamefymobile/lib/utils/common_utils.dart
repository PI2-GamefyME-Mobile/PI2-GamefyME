import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/models.dart';

class CommonUtils {
  // Validação de email
  static bool validEmail(String email) {
    final regex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  // Widget de campo de texto reutilizável
  static Widget buildTextField({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.branco,
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
          style: const TextStyle(color: AppColors.branco),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.cinzaSub),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.fundoCard,
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
    required int dificuldadeSelecionada,
    required Function(int) onChanged,
  }) {
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
                    color: isSelected ? AppColors.branco : AppColors.cinzaSub,
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
    required String recorrenciaSelecionada,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildRecorrenciaButton(
            'ÚNICA', 
            'unica', 
            recorrenciaSelecionada, 
            onChanged
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildRecorrenciaButton(
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
    String text, 
    String value, 
    String recorrenciaSelecionada, 
    Function(String) onChanged
  ) {
    final bool isSelected = recorrenciaSelecionada == value;
    return ElevatedButton(
      onPressed: () => onChanged(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.roxoClaro : AppColors.fundoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppColors.branco : AppColors.cinzaSub,
        ),
      ),
    );
  }

  // Widget de título de seção reutilizável
  static Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.branco,
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
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
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

