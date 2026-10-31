import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/partido.dart';
import 'registro_estadisticas_screen.dart';
import 'resumen_partido_screen.dart';

class MarcadorScreen extends StatefulWidget {
  final String partidoId;

  const MarcadorScreen({super.key, required this.partidoId});

  @override
  State<MarcadorScreen> createState() => _MarcadorScreenState();
}

class _MarcadorScreenState extends State<MarcadorScreen> {
  int _selectedIndex = 1; // 'Marcador Digital' es la opción 1 (centro)

  DocumentReference? get _partidoDocRef {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('partidos')
        .doc(widget.partidoId);
  }

  void _sumarPunto(Partido partido, bool esMiEquipo) {
    if (_partidoDocRef == null) return;

    int miPuntos = partido.puntosMiEquipo;
    int rivalPuntos = partido.puntosRival;
    int miSets = partido.setsMiEquipo;
    int rivalSets = partido.setsRival;
    int setAct = partido.setActual;
    bool sacaMio = partido.sacaMiEquipo;
    String estado = partido.estado;

    if (estado == 'finalizado') return;

    if (esMiEquipo) {
      miPuntos++;
      sacaMio = true;
    } else {
      rivalPuntos++;
      sacaMio = false;
    }

    int limitePuntos = (setAct == 5) ? 15 : 25;

    if (miPuntos >= limitePuntos && (miPuntos - rivalPuntos) >= 2) {
      miSets++;
      miPuntos = 0;
      rivalPuntos = 0;
      setAct++;
    } else if (rivalPuntos >= limitePuntos && (rivalPuntos - miPuntos) >= 2) {
      rivalSets++;
      miPuntos = 0;
      rivalPuntos = 0;
      setAct++;
    }

    if (miSets == 3 || rivalSets == 3) {
      estado = 'finalizado';
    }

    _partidoDocRef!.update({
      'puntosMiEquipo': miPuntos,
      'puntosRival': rivalPuntos,
      'setsMiEquipo': miSets,
      'setsRival': rivalSets,
      'setActual': setAct,
      'sacaMiEquipo': sacaMio,
      'estado': estado,
    });
  }

  void _restarPunto(Partido partido, bool esMiEquipo) {
    if (_partidoDocRef == null) return;

    if (esMiEquipo && partido.puntosMiEquipo > 0) {
      _partidoDocRef!.update({'puntosMiEquipo': partido.puntosMiEquipo - 1});
    } else if (!esMiEquipo && partido.puntosRival > 0) {
      _partidoDocRef!.update({'puntosRival': partido.puntosRival - 1});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_partidoDocRef == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_volleyball, color: Colors.amber),
              SizedBox(width: 8),
              Text('Marcador Digital'),
            ],
          ),
        ),
        body: const Center(child: Text('Inicia sesión para ver el marcador.')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _partidoDocRef!.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_volleyball, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Marcador Digital'),
                ],
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final partido = Partido.fromMap(snapshot.data!.id, data);

        return Scaffold(
          backgroundColor: Colors.grey[950],
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_volleyball, color: Colors.amber),
                SizedBox(width: 8),
                Text('Marcador Digital'),
              ],
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de Set / Estado Estilo LED
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade700, width: 1.5),
                      ),
                      child: Text(
                        partido.estado == 'finalizado'
                            ? 'PARTIDO FINALIZADO'
                            : 'SET ${partido.setActual}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade400,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tablero Principal (Equipos y Puntuaciones)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Equipo Local
                        Expanded(
                          child: _tableroEquipo(
                            nombre: partido.equipoNombre,
                            puntos: partido.puntosMiEquipo,
                            sets: partido.setsMiEquipo,
                            saca: partido.sacaMiEquipo,
                            color: Colors.cyanAccent,
                            onSuma: () => _sumarPunto(partido, true),
                            onResta: () => _restarPunto(partido, true),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            ':',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Equipo Rival
                        Expanded(
                          child: _tableroEquipo(
                            nombre: partido.rivalNombre,
                            puntos: partido.puntosRival,
                            sets: partido.setsRival,
                            saca: !partido.sacaMiEquipo,
                            color: Colors.amberAccent,
                            onSuma: () => _sumarPunto(partido, false),
                            onResta: () => _restarPunto(partido, false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              if (index == 0) {
                // Ir a Estadísticas
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistroEstadisticasScreen(
                      partidoId: widget.partidoId,
                      equipoId: partido.equipoId,
                    ),
                  ),
                );
              } else if (index == 1) {
                // Ya estamos en Marcador Digital
              } else if (index == 2) {
                // Ir a Resumen de Partido
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResumenPartidoScreen(
                      partidoId: widget.partidoId,
                    ),
                  ),
                );
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
      },
    );
  }

  Widget _tableroEquipo({
    required String nombre,
    required int puntos,
    required int sets,
    required bool saca,
    required Color color,
    required VoidCallback onSuma,
    required VoidCallback onResta,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nombre y Indicador de Saque
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (saca)
              const Icon(Icons.sports_volleyball, color: Colors.amber, size: 18),
            if (saca) const SizedBox(width: 4),
            Flexible(
              child: Text(
                nombre.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Pantalla LED de Puntos (Clickeable para sumar)
        GestureDetector(
          onTap: onSuma,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Text(
              puntos.toString().padLeft(2, '0'),
              style: TextStyle(
                color: color,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Sets Ganados
        Text(
          'SETS: $sets',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Botones de Control Compactos (+1 / -1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: IconButton.filled(
                padding: EdgeInsets.zero,
                onPressed: onResta,
                icon: const Icon(Icons.remove, size: 16),
                style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                onPressed: onSuma,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+1', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
