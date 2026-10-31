import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/partido.dart';
import 'marcador_screen.dart';

class CrearPartidoScreen extends StatefulWidget {
  const CrearPartidoScreen({super.key});

  @override
  State<CrearPartidoScreen> createState() => _CrearPartidoScreenState();
}

class _CrearPartidoScreenState extends State<CrearPartidoScreen> {
  final _rivalController = TextEditingController();

  // Guardamos solo el ID y Nombre del equipo seleccionado
  String? _equipoIdSeleccionado;
  String? _equipoNombreSeleccionado;

  // Obtiene la referencia a la subcolección de equipos del usuario actual
  CollectionReference? get _equiposRef {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('equipos');
  }

  // Obtiene la referencia a la subcolección de partidos del usuario actual
  CollectionReference? get _partidosRef {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('partidos');
  }

  Future<void> _iniciarPartido() async {
    if (_partidosRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para crear un partido.')),
      );
      return;
    }

    if (_equipoIdSeleccionado == null || _rivalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu equipo e ingresa el rival.')),
      );
      return;
    }

    final nuevoPartido = Partido(
      equipoId: _equipoIdSeleccionado!,
      equipoNombre: _equipoNombreSeleccionado!,
      rivalNombre: _rivalController.text.trim(),
    );

    final docRef = await _partidosRef!.add(nuevoPartido.toMap());

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MarcadorScreen(partidoId: docRef.id),
        ),
      );
    }
  }

  @override
  void dispose() {
    _rivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Partido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configurar Partido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Dropdown usando la subcolección privada del usuario autenticado
            _equiposRef == null
                ? const Text('Inicia sesión para seleccionar un equipo.')
                : StreamBuilder<QuerySnapshot>(
                    stream: _equiposRef!.snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Text('Primero debes crear al menos un equipo.');
                      }

                      return DropdownButtonFormField<String>(
                        value: _equipoIdSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Selecciona tu Equipo',
                          prefixIcon: Icon(Icons.sports_volleyball),
                        ),
                        items: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nombre = data['nombre'] ?? 'Sin Nombre';
                          return DropdownMenuItem<String>(
                            value: doc.id, // Usamos el ID único de Firestore
                            child: Text(nombre),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final docSeleccionado = docs.firstWhere((d) => d.id == val);
                            final data = docSeleccionado.data() as Map<String, dynamic>;
                            setState(() {
                              _equipoIdSeleccionado = val;
                              _equipoNombreSeleccionado = data['nombre'];
                            });
                          }
                        },
                      );
                    },
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: _rivalController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Equipo Rival',
                prefixIcon: Icon(Icons.shield),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _iniciarPartido,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Partido'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(12)),
            ),
          ],
        ),
      ),
    );
  }
}
