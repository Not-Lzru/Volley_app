import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CanchaRotacionScreen extends StatefulWidget {
  final String equipoId;
  final String equipoNombre;

  const CanchaRotacionScreen({
    super.key,
    required this.equipoId,
    required this.equipoNombre,
  });

  @override
  State<CanchaRotacionScreen> createState() => _CanchaRotacionScreenState();
}

class _CanchaRotacionScreenState extends State<CanchaRotacionScreen> {
  // Mapa para guardar los jugadores en las 6 posiciones de la cancha
  // Posiciones: 'pos1', 'pos2', 'pos3', 'pos4', 'pos5', 'pos6'
  Map<String, Map<String, dynamic>?> _cancha = {
    'pos1': null, // Saque / Zaguero Derecho
    'pos2': null, // Delantero Derecho
    'pos3': null, // Delantero Centro
    'pos4': null, // Delantero Izquierdo
    'pos5': null, // Zaguero Izquierdo
    'pos6': null, // Zaguero Centro
  };

  // Obtiene la referencia a la subcolección de jugadores del usuario actual
  CollectionReference? get _jugadoresRef {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('equipos')
        .doc(widget.equipoId)
        .collection('jugadores');
  }

  // Función para rotar en sentido de las agujas del reloj
  void _rotarEquipo() {
    setState(() {
      final pos1Temp = _cancha['pos1'];
      _cancha['pos1'] = _cancha['pos2'];
      _cancha['pos2'] = _cancha['pos3'];
      _cancha['pos3'] = _cancha['pos4'];
      _cancha['pos4'] = _cancha['pos5'];
      _cancha['pos5'] = _cancha['pos6'];
      _cancha['pos6'] = pos1Temp;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Rotación realizada en sentido de las agujas del reloj!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Asignar un jugador a una posición en la cancha
  void _seleccionarJugadorParaPosicion(String posKey, List<DocumentSnapshot> listaJugadores) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Asignar Jugador a ${posKey.toUpperCase()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: listaJugadores.length,
                  itemBuilder: (context, index) {
                    final data = listaJugadores[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text('#${data['numero']}')),
                      title: Text(data['nombre']),
                      subtitle: Text(data['posicion'] ?? ''),
                      onTap: () {
                        setState(() {
                          _cancha[posKey] = {
                            'nombre': data['nombre'],
                            'numero': data['numero'],
                          };
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    return Scaffold(
      appBar: AppBar(
       title: Text('Rotación - ${widget.equipoNombre}'),
        backgroundColor: Color.fromRGBO(13, 27, 42, 1),
        foregroundColor: Colors.white,
      ),
      body: _jugadoresRef == null
          ? const Center(child: Text('Inicia sesión para ver el equipo.'))
          : StreamBuilder<QuerySnapshot>(
              stream: _jugadoresRef!.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jugadores = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Visualización de la Cancha de Voleibol
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange[700], // Color de cancha
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Column(
                            children: [
                              // Red de Voleibol
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.black87,
                                child: const Text(
                                  '--- RED ---',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              // Zona de Ataque (Delanteros: Pos 4, Pos 3, Pos 2)
                              Expanded(
                                child: Row(
                                  children: [
                                    _cuadroPosicion('Pos 4', 'pos4', jugadores),
                                    _cuadroPosicion('Pos 3', 'pos3', jugadores),
                                    _cuadroPosicion('Pos 2', 'pos2', jugadores),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.white, thickness: 3, height: 3),
                              // Zona de Defensa (Zagueros: Pos 5, Pos 6, Pos 1)
                              Expanded(
                                child: Row(
                                  children: [
                                    _cuadroPosicion('Pos 5', 'pos5', jugadores),
                                    _cuadroPosicion('Pos 6', 'pos6', jugadores),
                                    _cuadroPosicion('Pos 1 (Saque)', 'pos1', jugadores, esSaque: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Botón de Rotación Automática
                      ElevatedButton.icon(
                        onPressed: _rotarEquipo,
                        icon: const Icon(Icons.sync, size: 28),
                        label: const Text(
                          'ROTAR EQUIPO ↻',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(13, 27, 42, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _cuadroPosicion(
    String etiqueta,
    String key,
    List<DocumentSnapshot> jugadores, {
    bool esSaque = false,
  }) {
    final jugador = _cancha[key];

    return Expanded(
      child: GestureDetector(
        onTap: () => _seleccionarJugadorParaPosicion(key, jugadores),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: esSaque ? Colors.amber[800] : Colors.orange[400],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white70),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              if (jugador != null) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color.fromRGBO(13, 27, 42, 1),
                  child: Text(
                    '#${jugador['numero']}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  jugador['nombre'],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ] else ...[
                const Icon(Icons.add_circle_outline, color: Colors.white70),
                const Text(
                  'Asignar',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
