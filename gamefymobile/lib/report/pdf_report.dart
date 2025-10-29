import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Modelo de atividade para relatório PDF
class AtividadeResumo {
  final String nome;
  final String situacao;
  final String dificuldade;
  final int experiencia;
  final DateTime data;
  final String? descricao;

  AtividadeResumo({
    required this.nome,
    required this.situacao,
    required this.dificuldade,
    required this.experiencia,
    required this.data,
    this.descricao,
  });
}

PdfColor _pdfColorFromFlutter(Color c) =>
    PdfColor.fromInt((c.red << 16) + (c.green << 8) + c.blue);

// Widget para card de estatística
pw.Widget _buildStatCard({
  required String title,
  required String value,
  required String percentage,
  required PdfColor color,
  required pw.Font ttfBold,
}) {
  return pw.Container(
    width: 160,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color, width: 2),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    padding: const pw.EdgeInsets.all(12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(title, style: pw.TextStyle(font: ttfBold, fontSize: 11)),
        pw.SizedBox(height: 8),
        pw.Text(value,
            style: pw.TextStyle(font: ttfBold, fontSize: 24, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(percentage, style: pw.TextStyle(fontSize: 10, color: color)),
      ],
    ),
  );
}

// Widget para gráfico circular (pizza)
pw.Widget _buildPieChart({
  required int concluidas,
  required int ativas,
  required int canceladas,
  required int total,
  required pw.Font ttfBold,
}) {
  if (total == 0) {
    return pw.Center(
      child: pw.Text('Nenhuma atividade no período',
          style: const pw.TextStyle(fontSize: 12)),
    );
  }

  final List<_PieChartData> data = [
    if (concluidas > 0)
      _PieChartData(
        label: 'Concluídas',
        value: concluidas,
        color: PdfColors.green,
        percentage: (concluidas / total) * 100,
      ),
    if (ativas > 0)
      _PieChartData(
        label: 'Ativas',
        value: ativas,
        color: PdfColors.blue,
        percentage: (ativas / total) * 100,
      ),
    if (canceladas > 0)
      _PieChartData(
        label: 'Canceladas',
        value: canceladas,
        color: PdfColors.red,
        percentage: (canceladas / total) * 100,
      ),
  ];

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.center,
    children: [
      // Gráfico circular
      pw.Container(
        width: 160,
        height: 160,
        child: pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.CustomPaint(
                painter: (canvas, size) {
                  final center = PdfPoint(size.x / 2, size.y / 2);
                  final radius = size.x / 2 - 5;
                  double currentAngle = -90; // Começar do topo (em graus)

                  for (final item in data) {
                    final sweepAngle = (item.percentage / 100) * 360;

                    // Converter para radianos
                    final startRad = currentAngle * 3.14159265359 / 180;
                    final endRad =
                        (currentAngle + sweepAngle) * 3.14159265359 / 180;

                    // Desenhar fatia
                    canvas
                      ..setFillColor(item.color)
                      ..moveTo(center.x, center.y);

                    // Criar o arco
                    final steps = (sweepAngle.abs() / 2).ceil().clamp(1, 180);
                    for (int i = 0; i <= steps; i++) {
                      final angle = startRad + (endRad - startRad) * i / steps;
                      final x = center.x + radius * _cos(angle);
                      final y = center.y + radius * _sin(angle);
                      canvas.lineTo(x, y);
                    }

                    canvas
                      ..lineTo(center.x, center.y)
                      ..fillPath();

                    currentAngle += sweepAngle;
                  }
                },
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 30),
      // Legenda
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: data
            .map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 16,
                        height: 16,
                        decoration: pw.BoxDecoration(
                          color: item.color,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.label,
                              style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                          pw.Text(
                            '${item.value} (${item.percentage.toStringAsFixed(1)}%)',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    ],
  );
}

// Funções auxiliares para cálculos trigonométricos
double _cos(double radians) {
  // Normalizar o ângulo para [-π, π]
  while (radians > 3.14159265359) radians -= 2 * 3.14159265359;
  while (radians < -3.14159265359) radians += 2 * 3.14159265359;

  // Série de Taylor para cos(x)
  double result = 1.0;
  double term = 1.0;
  for (int i = 1; i <= 12; i++) {
    term *= -radians * radians / ((2 * i - 1) * (2 * i));
    result += term;
  }
  return result;
}

double _sin(double radians) {
  // Normalizar o ângulo para [-π, π]
  while (radians > 3.14159265359) radians -= 2 * 3.14159265359;
  while (radians < -3.14159265359) radians += 2 * 3.14159265359;

  // Série de Taylor para sin(x)
  double result = radians;
  double term = radians;
  for (int i = 1; i <= 12; i++) {
    term *= -radians * radians / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

// Classe auxiliar para dados do gráfico de pizza
class _PieChartData {
  final String label;
  final int value;
  final PdfColor color;
  final double percentage;

  _PieChartData({
    required this.label,
    required this.value,
    required this.color,
    required this.percentage,
  });
}

Future<Uint8List> buildActivitiesPdf({
  required List<AtividadeResumo> atividades,
  required DateTimeRange periodo,
  required Color primaryColor,
  required Color onPrimaryColor,
  PdfPageFormat? pageFormat,
  String fontRegularAsset = 'assets/fonts/Jersey10-Regular.ttf',
}) async {
  final doc = pw.Document();

  final fontRegularData = await rootBundle.load(fontRegularAsset);
  final ttfRegular = pw.Font.ttf(fontRegularData);
  final ttfBold = ttfRegular; // Sem variante bold separada

  final df = DateFormat('dd/MM/yyyy');
  final PdfColor headerBg = _pdfColorFromFlutter(primaryColor);
  final PdfColor headerFg = _pdfColorFromFlutter(onPrimaryColor);

  final titulo = 'Relatório de atividades';
  final periodoStr = '${df.format(periodo.start)} a ${df.format(periodo.end)}';

  // Incluir todas as atividades do período
  final itens = atividades.toList()..sort((a, b) => a.data.compareTo(b.data));

  // Estatísticas por status
  final concluidas =
      itens.where((a) => a.situacao.toLowerCase() == 'realizada').length;
  final canceladas =
      itens.where((a) => a.situacao.toLowerCase() == 'cancelada').length;
  final ativas = itens
      .where((a) =>
          a.situacao.toLowerCase() != 'realizada' &&
          a.situacao.toLowerCase() != 'cancelada')
      .length;
  final total = itens.length;

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: pageFormat ?? PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
      ),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(titulo,
                      style: pw.TextStyle(font: ttfBold, fontSize: 20)),
                  pw.SizedBox(height: 4),
                  pw.Text('Período: $periodoStr',
                      style: const pw.TextStyle(fontSize: 10)),
                ]),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
      build: (ctx) => [
        // Cabeçalho de Resumo
        pw.Container(
          decoration: pw.BoxDecoration(
            color: headerBg,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Resumo Geral',
                  style: pw.TextStyle(
                      color: headerFg, font: ttfBold, fontSize: 14)),
              pw.Text(
                'Total: $total atividades',
                style:
                    pw.TextStyle(color: headerFg, font: ttfBold, fontSize: 12),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Estatísticas em Cards
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              title: 'Concluídas',
              value: concluidas.toString(),
              percentage: total > 0
                  ? '${((concluidas / total) * 100).toStringAsFixed(1)}%'
                  : '0%',
              color: PdfColors.green,
              ttfBold: ttfBold,
            ),
            _buildStatCard(
              title: 'Ativas',
              value: ativas.toString(),
              percentage: total > 0
                  ? '${((ativas / total) * 100).toStringAsFixed(1)}%'
                  : '0%',
              color: PdfColors.blue,
              ttfBold: ttfBold,
            ),
            _buildStatCard(
              title: 'Canceladas',
              value: canceladas.toString(),
              percentage: total > 0
                  ? '${((canceladas / total) * 100).toStringAsFixed(1)}%'
                  : '0%',
              color: PdfColors.red,
              ttfBold: ttfBold,
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // Gráfico Circular
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Distribuição de Atividades',
                  style: pw.TextStyle(font: ttfBold, fontSize: 14)),
              pw.SizedBox(height: 16),
              _buildPieChart(
                concluidas: concluidas,
                ativas: ativas,
                canceladas: canceladas,
                total: total,
                ttfBold: ttfBold,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Tabela de Atividades
        pw.Text('Detalhamento das Atividades',
            style: pw.TextStyle(font: ttfBold, fontSize: 14)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: PdfColors.grey300)),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.0),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Data', style: pw.TextStyle(font: ttfBold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Atividade',
                        style: pw.TextStyle(font: ttfBold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Dificuldade',
                        style: pw.TextStyle(font: ttfBold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Situação',
                        style: pw.TextStyle(font: ttfBold))),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('XP', style: pw.TextStyle(font: ttfBold))),
              ],
            ),
            ...itens.map((a) => pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(df.format(a.data))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(a.nome)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(a.dificuldade)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(a.situacao)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(a.experiencia.toString())),
                  ],
                )),
          ],
        ),
        if (itens.any((a) => (a.descricao ?? '').isNotEmpty)) ...[
          pw.SizedBox(height: 16),
          pw.Text('Descrições',
              style: pw.TextStyle(font: ttfBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          ...itens
              .where((a) => (a.descricao ?? '').isNotEmpty)
              .map((a) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${df.format(a.data)} • ${a.nome}',
                            style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                        pw.SizedBox(height: 2),
                        pw.Text(a.descricao ?? '',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  )),
        ],
      ],
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 10)),
      ),
    ),
  );

  return doc.save();
}

Future<void> shareActivitiesPdf({
  required List<AtividadeResumo> atividades,
  required DateTimeRange periodo,
  required Color primaryColor,
  required Color onPrimaryColor,
  PdfPageFormat? pageFormat,
}) async {
  final bytes = await buildActivitiesPdf(
    atividades: atividades,
    periodo: periodo,
    primaryColor: primaryColor,
    onPrimaryColor: onPrimaryColor,
    pageFormat: pageFormat,
  );
  final filename =
      'relatorio-atividades_${DateFormat('yyyyMMdd').format(periodo.start)}-${DateFormat('yyyyMMdd').format(periodo.end)}.pdf';
  await Printing.sharePdf(bytes: bytes, filename: filename);
}

Future<void> openActivitiesPdfPreview({
  required BuildContext context,
  required List<AtividadeResumo> atividades,
  required DateTimeRange periodo,
  required Color primaryColor,
  required Color onPrimaryColor,
}) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final selectedFormat = screenWidth < 380 ? PdfPageFormat.a5 : PdfPageFormat.a4;

  final filename =
      'relatorio-atividades_${DateFormat('yyyyMMdd').format(periodo.start)}-${DateFormat('yyyyMMdd').format(periodo.end)}.pdf';

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Visualizar PDF'),
        ),
        body: PdfPreview(
          allowSharing: true,
          allowPrinting: false,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          pdfFileName: filename,
          build: (format) => buildActivitiesPdf(
            atividades: atividades,
            periodo: periodo,
            primaryColor: primaryColor,
            onPrimaryColor: onPrimaryColor,
            pageFormat: selectedFormat,
          ),
        ),
      ),
    ),
  );
}
