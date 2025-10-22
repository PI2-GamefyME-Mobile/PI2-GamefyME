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

Future<Uint8List> buildActivitiesPdf({
  required List<AtividadeResumo> atividades,
  required DateTimeRange periodo,
  required Color primaryColor,
  required Color onPrimaryColor,
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

  final itens = atividades
      .where((a) => a.situacao.toLowerCase() == 'realizada' || a.situacao.toLowerCase() == 'cancelada')
      .toList()
    ..sort((a, b) => a.data.compareTo(b.data));

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
      ),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(titulo, style: pw.TextStyle(font: ttfBold, fontSize: 20)),
              pw.SizedBox(height: 4),
              pw.Text('Período: $periodoStr', style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
      build: (ctx) => [
        pw.Container(
          decoration: pw.BoxDecoration(
            color: headerBg,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Resumo', style: pw.TextStyle(color: headerFg, font: ttfBold, fontSize: 14)),
              pw.Text(
                'Total: ${itens.length}',
                style: pw.TextStyle(color: headerFg, font: ttfBold, fontSize: 12),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.grey300)),
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
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Data', style: pw.TextStyle(font: ttfBold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Atividade', style: pw.TextStyle(font: ttfBold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Dificuldade', style: pw.TextStyle(font: ttfBold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Situação', style: pw.TextStyle(font: ttfBold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('XP', style: pw.TextStyle(font: ttfBold))),
              ],
            ),
            ...itens.map((a) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(df.format(a.data))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(a.nome)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(a.dificuldade)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(a.situacao)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(a.experiencia.toString())),
              ],
            )),
          ],
        ),
        if (itens.any((a) => (a.descricao ?? '').isNotEmpty)) ...[
          pw.SizedBox(height: 16),
          pw.Text('Descrições', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          ...itens.where((a) => (a.descricao ?? '').isNotEmpty).map((a) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${df.format(a.data)} • ${a.nome}', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
                pw.SizedBox(height: 2),
                pw.Text(a.descricao ?? '', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          )),
        ],
      ],
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
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
}) async {
  final bytes = await buildActivitiesPdf(
    atividades: atividades,
    periodo: periodo,
    primaryColor: primaryColor,
    onPrimaryColor: onPrimaryColor,
  );
  final filename =
      'relatorio-atividades_${DateFormat('yyyyMMdd').format(periodo.start)}-${DateFormat('yyyyMMdd').format(periodo.end)}.pdf';
  await Printing.sharePdf(bytes: bytes, filename: filename);
}
