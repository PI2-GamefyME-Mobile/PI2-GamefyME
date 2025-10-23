// lib/desafios_screen.dart

import 'package:flutter/material.dart';
import 'package:gamefymobile/models/models.dart';
import 'package:gamefymobile/services/api_service.dart';
import 'package:gamefymobile/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'config/app_colors.dart';
import 'config/theme_provider.dart';

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
        _apiService.fetchConquistas(),
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
    final bool isAdmin = _usuario?.isAdmin ?? false;

    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: CustomAppBar(
        usuario: _usuario,
        notificacoes: _notificacoes,
        desafios: _desafios,
        conquistas: _conquistas,
        onDataReload: _carregarDados,
      ),
      backgroundColor: themeProvider.fundoApp,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildFiltroTipo()),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin-desafios')
                          .then((_) => _carregarDados());
                    },
                    icon: const Icon(Icons.admin_panel_settings, size: 20),
                    label: const Text('Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roxoProfundo,
                      foregroundColor: AppColors.verdeLima,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _desafiosFiltrados.isEmpty
                      ? Center(
                          child: Text('Nenhum desafio encontrado.',
                              style:
                                  TextStyle(color: themeProvider.textoTexto)))
                      : _buildListaDesafios(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroTipo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Tipos únicos de desafios para o dropdown
    final tipos = _desafios.map((d) => d.tipo).toSet().toList();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _tipoSelecionado,
            hint: Text('Filtrar por tipo',
                style: TextStyle(
                  color: themeProvider.textoTexto,
                  fontFamily: 'Jersey 10',
                )),
            style: TextStyle(
              color: themeProvider.textoTexto,
              fontFamily: 'Jersey 10',
            ),
            dropdownColor: themeProvider.fundoCard,
            items: tipos
                .map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child:
                        Text(FilterHelpers.getTipoDesafioDisplayName(value))))
                .toList(),
            onChanged: (newValue) => _filtrarDesafios(newValue),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: themeProvider.textoCinza),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.verdeLima),
              ),
            ),
          ),
        ),
        if (_tipoSelecionado != null)
          IconButton(
            icon: Icon(Icons.clear, color: themeProvider.textoTexto),
            onPressed: () => _filtrarDesafios(null),
          )
      ],
    );
  }

  Widget _buildListaDesafios() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListView(
      children: _desafiosAgrupados.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.roxoClaro,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((desafio) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: desafio.completado
                      ? themeProvider.desafioCompleto.withValues(alpha: 0.8)
                      : themeProvider.desafioCompleto,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: desafio.completado
                        ? AppColors.verdeLima.withValues(alpha: 0.3)
                        : AppColors.amareloClaro.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: desafio.completado
                      ? const Icon(Icons.check_circle,
                          color: AppColors.verdeLima, size: 30)
                      : const Icon(Icons.emoji_events_outlined,
                          color: AppColors.amareloClaro, size: 30),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              desafio.nome,
                              style: TextStyle(
                                color: themeProvider.textoAtividade,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.amareloClaro,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${desafio.xp} XP',
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? AppColors.fundoEscuro
                                    : AppColors.fundoEscuro,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desafio.descricao,
                        style: TextStyle(
                          color: themeProvider.textoAtividade,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Badge de tipo de desafio
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.roxoClaro.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.roxoClaro,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          FilterHelpers.getTipoDesafioDisplayName(desafio.tipo)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.verdeLima,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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
