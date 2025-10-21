// lib/desafios_screen.dart

import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'config/app_colors.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  Usuario? _usuario;
  List<Notificacao> _notificacoes = [];
  List<Conquista> _conquistas = [];
  List<DesafioPendente> _desafios = [];
  List<DesafioPendente> _desafiosFiltrados = [];
  String? _tipoSelecionado;

  Map<String, List<DesafioPendente>> _desafiosAgrupados = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchDesafiosPendentes(),
        _apiService.fetchNotificacoes(),
        _apiService.fetchUsuarioConquistas(),
      ]);
      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _desafios = results[1] as List<DesafioPendente>;
        _desafiosFiltrados = _desafios;
        _agruparDesafios();
        _notificacoes = results[2] as List<Notificacao>;
        _conquistas = results[3] as List<Conquista>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados.')),
      );
    }
  }

  void _agruparDesafios() {
    _desafiosAgrupados = {};
    for (var desafio in _desafiosFiltrados) {
      if (!_desafiosAgrupados.containsKey(desafio.tipo)) {
        _desafiosAgrupados[desafio.tipo] = [];
      }
      _desafiosAgrupados[desafio.tipo]!.add(desafio);
    }
  }

  void _filtrarDesafios(String? tipo) {
    setState(() {
      _tipoSelecionado = tipo;
      if (_tipoSelecionado == null) {
        _desafiosFiltrados = _desafios;
      } else {
        _desafiosFiltrados =
            _desafios.where((d) => d.tipo == _tipoSelecionado).toList();
      }
      _agruparDesafios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafios,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
      ),
      backgroundColor: AppColors.fundoEscuro,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFiltroTipo(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _desafiosFiltrados.isEmpty
                      ? const Center(
                          child: Text('Nenhum desafio encontrado.',
                              style: TextStyle(color: Colors.white)))
                      : _buildListaDesafios(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroTipo() {
    // Tipos únicos de desafios para o dropdown
    final tipos = _desafios.map((d) => d.tipo).toSet().toList();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _tipoSelecionado,
            hint: const Text('Filtrar por tipo',
                style: TextStyle(color: Colors.white)),
            style: const TextStyle(color: Colors.white),
            dropdownColor: AppColors.fundoCard,
            items: tipos
                .map((String value) => DropdownMenuItem<String>(
                    value: value, 
                    child: Text(FilterHelpers.getTipoDesafioDisplayName(value))))
                .toList(),
            onChanged: (newValue) => _filtrarDesafios(newValue),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.cinzaSub),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.verdeLima),
              ),
            ),
          ),
        ),
        if (_tipoSelecionado != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () => _filtrarDesafios(null),
          )
      ],
    );
  }

  Widget _buildListaDesafios() {
    return ListView(
      children: _desafiosAgrupados.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.verdeLima,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((desafio) {
              return Card(
                color: desafio.completado ? AppColors.fundoCard.withValues(alpha: 0.5) : AppColors.fundoCard,
                child: ListTile(
                  leading: desafio.completado 
                    ? const Icon(Icons.check_circle, color: AppColors.verdeLima, size: 30)
                    : const Icon(Icons.emoji_events_outlined, color: AppColors.amareloClaro, size: 30),
                  title: Text(desafio.nome,
                      style: TextStyle(color: desafio.completado ? Colors.grey : Colors.white)),
                  subtitle: Text(desafio.descricao,
                      style: TextStyle(color: desafio.completado ? Colors.grey[600] : Colors.grey)),
                  trailing: Text('+${desafio.xp} XP',
                      style: const TextStyle(
                          color: AppColors.amareloClaro,
                          fontWeight: FontWeight.bold)),
                ),
              );
            }),
             const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}