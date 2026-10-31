import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/estadistica.dart';
import '../services/pdf_service.dart';
import '../models/partido.dart';
import 'registro_estadisticas_screen.dart';
import 'marcador_screen.dart';

class ResumenPartidoScreen extends StatefulWidget {
  final String partidoId;

  const ResumenPartidoScreen({super.key, required this.partidoId});

  @override
  State<ResumenPartidoScreen> createState() => _ResumenPartidoScreenState();
}

class _ResumenPartidoScreenState extends State<ResumenPartidoScreen> {
  int _selectedIndex = 2; // 'Resumen Partido' es la opción 2 (derecha)

  // Obtiene el ID del usuario actualmente autenticado
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Referencia al documento del partido específico del usuario actual
  DocumentReference? get _partidoDocRef {
    if (_userId == null) return null;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('partidos')
        .doc(widget.partidoId);
  }

  // Referencia a la subcolección de estadísticas del partido
  CollectionReference? get _estadisticasRef {
    if (_partidoDocRef == null) return null;
    return _partidoDocRef!.collection('estadisticas');
  }

  Future<void> _exportarPdf(BuildContext context) async {
    if (_partidoDocRef == null || _estadisticasRef == null) return;

    // 1. Obtener datos del partido desde la subcolección del usuario
    final partidoDoc = await _partidoDocRef!.get();

    if (!partidoDoc.exists || partidoDoc.data() == null) return;

    final partido = Partido.fromMap(
      partidoDoc.id,
      partidoDoc.data() as Map<String, dynamic>,
    );

    // 2. Obtener estadísticas de los jugadores desde la subcolección del usuario
    final statsSnapshot = await _estadisticasRef!.get();

    final statsList = statsSnapshot.docs
        .map((d) => EstadisticaJugador.fromMap(d.data() as Map<String, dynamic>))
        .toList();

    // 3. Generar y abrir el archivo PDF
    if (context.mounted) {
      await PdfService.generarReportePartido(
        partido: partido,
        estadisticas: statsList,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_volleyball, color: Colors.amber),
              SizedBox(width: 8),
              Text('Resumen Estadístico'),
            ],
          ),
        ),
        body: const Center(child: Text('Inicia sesión para ver el resumen.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_volleyball, color: Colors.amber),
            SizedBox(width: 8),
            Text('Resumen Estadístico'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportarPdf(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _estadisticasRef
            ?.orderBy('totalPuntos', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No hay estadísticas registradas en este partido.'),
            );
          }

          final statsList = docs
              .map((d) => EstadisticaJugador.fromMap(d.data() as Map<String, dynamic>))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView(
              children: [
                const Text(
                  'Tabla de Anotadores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                DataTable(
                  columnSpacing: 12,
                  columns: const [
                    DataColumn(label: Text('Jugador')),
                    DataColumn(label: Text('Atq')),
                    DataColumn(label: Text('Blq')),
                    DataColumn(label: Text('Ace')),
                    DataColumn(label: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: statsList.map((stat) {
                    return DataRow(cells: [
                      DataCell(Text('#${stat.numeroJugador} ${stat.nombreJugador}')),
                      DataCell(Text('${stat.ataquesExitosos}')),
                      DataCell(Text('${stat.bloqueos}')),
                      DataCell(Text('${stat.aces}')),
                      DataCell(Text(
                        '${stat.totalPuntos}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      )),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) async {
          setState(() => _selectedIndex = index);

          // Necesitamos obtener el equipoId para navegar a estadísticas si es necesario, 
          // o podemos extraerlo directamente del documento del partido.
          if (index == 0 || index == 1) {
            final partidoDoc = await _partidoDocRef?.get();
            if (partidoDoc != null && partidoDoc.exists) {
              final data = partidoDoc.data() as Map<String, dynamic>;
              final equipoId = data['equipoId'] ?? '';

              if (context.mounted) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistroEstadisticasScreen(
                        partidoId: widget.partidoId,
                        equipoId: equipoId,
                      ),
                    ),
                  );
                } else if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarcadorScreen(
                        partidoId: widget.partidoId,
                      ),
                    ),
                  );
                }
              }
            }
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.playlist_add_outlined),
            selectedIcon: Icon(Icons.playlist_add),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.scoreboard_outlined),
            selectedIcon: Icon(Icons.scoreboard),
            label: 'Marcador Digital',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Resumen Partido',
          ),
        ],
      ),
    );
  }
}
