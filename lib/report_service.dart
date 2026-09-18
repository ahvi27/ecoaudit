import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';

class ReportService {
  static Future<Uint8List> build(
      Inspection inspection, Facility facility) async {
    final pdf = pw.Document(title: 'EcoAudit Inspection Report');
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('ECOAUDIT',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800)),
            pw.Text('Environmental Compliance Report',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
      footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9))),
      build: (_) => [
        pw.SizedBox(height: 18),
        pw.Text(inspection.title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Table.fromTextArray(
            data: [
              ['Facility', facility.name],
              ['Sector', facility.sector],
              ['Location', facility.location],
              ['Inspection date', DateFormat.yMMMd().format(inspection.date)],
              ['Inspector', inspection.inspector],
              ['Compliance score', '${inspection.score}%'],
            ],
            headerCount: 0,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding: const pw.EdgeInsets.all(7)),
        pw.SizedBox(height: 22),
        pw.Text('Findings',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (inspection.findings.isEmpty)
          pw.Text('No non-conformities recorded.'),
        ...inspection.findings.map((f) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${f.severity.name.toUpperCase()} · ${f.category}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.green800,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(f.title,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(f.description),
                  if (f.latitude != null)
                    pw.Text(
                        'GPS: ${f.latitude!.toStringAsFixed(5)}, ${f.longitude!.toStringAsFixed(5)}',
                        style: const pw.TextStyle(fontSize: 9)),
                ]))),
        pw.SizedBox(height: 14),
        pw.Text('Corrective Actions',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (inspection.actions.isEmpty)
          pw.Text('No corrective actions assigned.'),
        if (inspection.actions.isNotEmpty)
          pw.Table.fromTextArray(
              headers: ['Action', 'Owner', 'Due', 'Status'],
              data: inspection.actions
                  .map((a) => [
                        a.title,
                        a.owner,
                        DateFormat.yMMMd().format(a.dueDate),
                        a.status.name
                      ])
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.green800),
              headerStyle: pw.TextStyle(
                  color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
      ],
    ));
    return pdf.save();
  }
}
