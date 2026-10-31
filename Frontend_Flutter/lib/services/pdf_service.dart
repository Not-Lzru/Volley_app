import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/estadistica.dart';
import '../models/partido.dart';

class PdfService {
  static Future<void> generarReportePartido({
    required Partido partido,
    required List<EstadisticaJugador> estadisticas,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VOLLEY CONTROL - FICHA TÉCNICA',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Estado: ${partido.estado.toUpperCase()}',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Resumen del Resultado
                pw.Text(
                  'Resultado del Partido',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            partido.equipoNombre,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                          ),
                          pw.Text('Sets: ${partido.setsMiEquipo}', style: const pw.TextStyle(fontSize: 16)),
                        ],
                      ),
                      pw.Text('VS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Column(
                        children: [
                          pw.Text(
                            partido.rivalNombre,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                          ),
                          pw.Text('Sets: ${partido.setsRival}', style: const pw.TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Tabla de Estadísticas por Jugador
                pw.Text(
                  'Estadísticas de Jugadores',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['#', 'Jugador', 'Ataques', 'Bloqueos', 'Aces', 'Puntos Totales'],
                  data: estadisticas.map((stat) {
                    return [
                      '#${stat.numeroJugador}',
                      stat.nombreJugador,
                      '${stat.ataquesExitosos}',
                      '${stat.bloqueos}',
                      '${stat.aces}',
                      '${stat.totalPuntos}',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            ),
          );
        },
      ),
    );

    // Muestra la vista previa o abre el diálogo para Guardar/Compartir PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_${partido.equipoNombre}_vs_${partido.rivalNombre}.pdf',
    );
  }
}
