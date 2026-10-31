import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/jugador.dart';

class AgregarJugadorScreen extends StatefulWidget {
  final String equipoId;
  final String equipoNombre;

  const AgregarJugadorScreen({
    super.key,
    required this.equipoId,
    required this.equipoNombre,
  });

  @override
  State<AgregarJugadorScreen> createState() => _AgregarJugadorScreenState();
}

class _AgregarJugadorScreenState extends State<AgregarJugadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _numeroController = TextEditingController();

  String _posicionSeleccionada = 'Punta';
  final List<String> _posiciones = [
    'Colocador',
    'Central',
    'Punta',
    'Opuesto',
    'Libero'
  ];

  bool _cargando = false;

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

  Future<void> _guardarJugador() async {
    if (_formKey.currentState!.validate()) {
      final ref = _jugadoresRef;
      if (ref == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.')),
        );
        return;
      }

      setState(() => _cargando = true);

      final nuevoJugador = Jugador(
        nombre: _nombreController.text.trim(),
        numero: int.parse(_numeroController.text.trim()),
        posicion: _posicionSeleccionada,
      );

      try {
        // Guardar como subcolección dentro de usuarios/{userId}/equipos/{equipoId}/jugadores
        await ref.add(nuevoJugador.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Jugador agregado con éxito!')),
          );
          _nombreController.clear();
          _numeroController.clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _cargando = false);
      }
    }
  }

  Future<void> _eliminarJugador(String jugadorId) async {
    final ref = _jugadoresRef;
    if (ref == null) return;

    try {
      await ref.doc(jugadorId).delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Jugadores de ${widget.equipoNombre}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulario superior para añadir un jugador
            Form(
              key: _formKey,
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Registrar Nuevo Jugador',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Ingresa el nombre del jugador'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numeroController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Número (#)',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              validator: (value) => value!.isEmpty
                                  ? 'Número'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _posicionSeleccionada,
                              decoration: const InputDecoration(
                                labelText: 'Posición',
                              ),
                              items: _posiciones.map((pos) {
                                return DropdownMenuItem(
                                  value: pos,
                                  child: Text(pos),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _posicionSeleccionada = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _cargando
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _guardarJugador,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Agregar Jugador'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Plantilla del Equipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            // Lista en tiempo real de jugadores del equipo aislado por usuario
            Expanded(
              child: _jugadoresRef == null
                  ? const Center(
                      child: Text('Inicia sesión para ver los jugadores.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _jugadoresRef!.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child:
                                Text('No hay jugadores registrados aún.'),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;
                            final jugador =
                                Jugador.fromMap(docs[index].id, data);

                            return ListTile(
                              leading: CircleAvatar(
                                child: Text('#${jugador.numero}'),
                              ),
                              title: Text(jugador.nombre),
                              subtitle:
                                  Text('Posición: ${jugador.posicion}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _eliminarJugador(docs[index].id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
