import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/estadistica.dart';
import 'marcador_screen.dart';
import 'resumen_partido_screen.dart';

class RegistroEstadisticasScreen extends StatefulWidget {
  final String partidoId;
  final String equipoId;

  const RegistroEstadisticasScreen({
    super.key,
    required this.partidoId,
    required this.equipoId,
  });

  @override
  State<RegistroEstadisticasScreen> createState() => _RegistroEstadisticasScreenState();
}

class _RegistroEstadisticasScreenState extends State<RegistroEstadisticasScreen> {
  int _selectedIndex = 0; // 'Estadísticas' es la opción 0 (izquierda)

  // Obtiene el ID del usuario actualmente autenticado[cite: 3]
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Colección de jugadores del equipo pertenecientes al usuario actual[cite: 3]
  CollectionReference? get _jugadoresRef {
    if (_userId == null) return null;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('equipos')
        .doc(widget.equipoId)
        .collection('jugadores');
  }

  // Colección de estadísticas del partido perteneciente al usuario actual[cite: 3]
  CollectionReference? get _estadisticasRef {
    if (_userId == null) return null;
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userId)
        .collection('partidos')
        .doc(widget.partidoId)
        .collection('estadisticas');
  }

  void _registrarAccion(String jugadorId, String nombre, int numero, String tipoAccion) async {
    if (_estadisticasRef == null) return;

    final docRef = _estadisticasRef!.doc(jugadorId);
    final snapshot = await docRef.get();

    EstadisticaJugador stats;
    if (snapshot.exists && snapshot.data() != null) {
      stats = EstadisticaJugador.fromMap(snapshot.data() as Map<String, dynamic>);
    } else {
      stats = EstadisticaJugador(
        jugadorId: jugadorId,
        nombreJugador: nombre,
        numeroJugador: numero,
      );
    }

    // Incrementar el contador según el botón presionado[cite: 3]
    switch (tipoAccion) {
      case 'ataque':
        stats.ataquesExitosos++;
        break;
      case 'bloqueo':
        stats.bloqueos++;
        break;
      case 'ace':
        stats.aces++;
        break;
      case 'error_saque':
        stats.erroresSaque++;
        break;
      case 'error_ataque':
        stats.erroresAtaque++;
        break;
    }

    await docRef.set(stats.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$tipoAccion registrado para $nombre'),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget buildPosicionBadge(String posicion) {
    Color color;
    switch (posicion.toLowerCase()) {
      case 'colocador':
        color = Colors.purple;
        break;
      case 'central':
        color = Colors.blue;
        break;
      case 'punta':
        color = Colors.green;
        break;
      case 'opuesto':
        color = Colors.deepOrange;
        break;
      case 'libero':
        color = Colors.amber[800]!;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        posicion.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
              Text('Registro de Estadísticas'),
            ],
          ),
        ),
        body: const Center(child: Text('Inicia sesión para registrar estadísticas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_volleyball, color: Colors.amber),
            SizedBox(width: 8),
            Text('Registro de Estadísticas'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _jugadoresRef?.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jugadores = snapshot.data!.docs;

          if (jugadores.isEmpty) {
            return const Center(child: Text('No hay jugadores en este equipo[cite: 3].'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: jugadores.length,
            itemBuilder: (context, index) {
              final data = jugadores[index].data() as Map<String, dynamic>;
              final id = jugadores[index].id;
              final nombre = data['nombre'] ?? '';
              final numero = data['numero'] ?? 0;
              final posicion = data['posicion'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            child: Text('#$numero', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (posicion.isNotEmpty) buildPosicionBadge(posicion),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      // Botones de acciones organizados estéticamente
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildActionButton(
                            label: 'Ataque',
                            icon: Icons.flash_on,
                            color: Colors.green.shade700,
                            onPressed: () => _registrarAccion(id, nombre, numero, 'ataque'),
                          ),
                          _buildActionButton(
                            label: 'Bloqueo',
                            icon: Icons.shield,
                            color: Colors.blue.shade700,
                            onPressed: () => _registrarAccion(id, nombre, numero, 'bloqueo'),
                          ),
                          _buildActionButton(
                            label: 'Ace',
                            icon: Icons.sports_volleyball,
                            color: Colors.amber.shade800,
                            onPressed: () => _registrarAccion(id, nombre, numero, 'ace'),
                          ),
                          _buildActionButton(
                            label: 'Err. Saque',
                            icon: Icons.error_outline,
                            color: Colors.red.shade400,
                            onPressed: () => _registrarAccion(id, nombre, numero, 'error_saque'),
                          ),
                          _buildActionButton(
                            label: 'Err. Ataque',
                            icon: Icons.close,
                            color: Colors.red.shade700,
                            onPressed: () => _registrarAccion(id, nombre, numero, 'error_ataque'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) {
            // Ya estamos aquí (Estadísticas)
          } else if (index == 1) {
            // Ir al Marcador Digital reemplazando la ruta actual
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MarcadorScreen(partidoId: widget.partidoId),
              ),
            );
          } else if (index == 2) {
            // Ir al Resumen del Partido reemplazando la ruta actual
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResumenPartidoScreen(partidoId: widget.partidoId),
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
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
