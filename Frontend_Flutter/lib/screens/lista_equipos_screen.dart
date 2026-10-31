import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/equipo.dart';
import 'agregar_jugador_screen.dart';
import 'crear_equipo_screen.dart';
import 'crear_partido_screen.dart';
import 'cancha_rotacion_screen.dart';
import 'pizarra_tactica_screen.dart';
import 'perfil_screen.dart';
import '../services/auth_service.dart';

class ListaEquiposScreen extends StatefulWidget {
  const ListaEquiposScreen({super.key});

  @override
  State<ListaEquiposScreen> createState() => _ListaEquiposScreenState();
}

class _ListaEquiposScreenState extends State<ListaEquiposScreen> {
  int _selectedIndex = 1; // Seleccionado 'Mis Equipos' (índice 1) por defecto

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      // Pizarra Táctica
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PizarraTacticaScreen(),
        ),
      );
    } else if (index == 1) {
      // Ya estamos en la lista de equipos
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 2) {
      // Crear Equipo
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CrearEquipoScreen(),
        ),
      );
    }
  }

  // Helper para construir el Avatar del equipo respondiendo a Base64, URL o Fallback
  Widget _buildAvatar(String? fotoUrl, {double radius = 20}) {
    if (fotoUrl == null || fotoUrl.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.sports_volleyball, size: radius),
      );
    }

    if (fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(fotoUrl),
      );
    }

    try {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(fotoUrl)),
      );
    } catch (_) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.sports_volleyball, size: radius),
      );
    }
  }

  // Modal para editar los datos y la foto del equipo
  void _mostrarDialogoEditarEquipo(Equipo equipo, String userId) {
    final nombreController = TextEditingController(text: equipo.nombre);
    final categoriaController = TextEditingController(text: equipo.categoria);
    final entrenadorController = TextEditingController(text: equipo.entrenador);

    File? nuevaImagenLocal;
    String? nuevaImagenBase64 = equipo.fotoUrl;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> seleccionarNuevaFoto() async {
              final picker = ImagePicker();
              final XFile? imagen = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 65,
                maxWidth: 600,
              );

              if (imagen != null) {
                final bytes = await imagen.readAsBytes();
                setDialogState(() {
                  nuevaImagenLocal = File(imagen.path);
                  nuevaImagenBase64 = base64Encode(bytes);
                });
              }
            }

            Future<void> guardarCambios() async {
              if (nombreController.text.trim().isEmpty) return;

              setDialogState(() => guardando = true);

              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(userId)
                    .collection('equipos')
                    .doc(equipo.id)
                    .update({
                  'nombre': nombreController.text.trim(),
                  'categoria': categoriaController.text.trim(),
                  'entrenador': entrenadorController.text.trim(),
                  'fotoUrl': nuevaImagenBase64 ?? '',
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Equipo actualizado correctamente')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e')),
                  );
                }
              } finally {
                setDialogState(() => guardando = false);
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit, color: Color.fromRGBO(13, 27, 42, 1),),
                  SizedBox(width: 8),
                  Text('Editar Equipo'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          nuevaImagenLocal != null
                              ? CircleAvatar(
                                  radius: 40,
                                  backgroundImage: FileImage(nuevaImagenLocal!),
                                )
                              : _buildAvatar(nuevaImagenBase64, radius: 40),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: seleccionarNuevaFoto,
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.edit, size: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Equipo',
                        prefixIcon: Icon(Icons.groups),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: entrenadorController,
                      decoration: const InputDecoration(
                        labelText: 'Director Técnico / Entrenador',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                guardando
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: guardarCambios,
                        child: const Text('Guardar'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_volleyball, color: Colors.amber),
            SizedBox(width: 8),
            Text('Mis Equipos'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerfilScreen(),
                  ),
                );
              } else if (value == 'logout') {
                await AuthService().cerrarSesion();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black87),
                    SizedBox(width: 10),
                    Text('Configuración de Perfil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearPartidoScreen(),
            ),
          );
        },
        icon: const Icon(Icons.scoreboard),
        label: const Text('Crear Partido'),
      ),
      body: userId == null
          ? const Center(child: Text('Usuario no autenticado.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userId)
                  .collection('equipos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay equipos creados. Toca "Crear Equipo" abajo para agregar uno.'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final equipo = Equipo.fromMap(docs[index].id, data);

                    final String? fotoUrl = data['fotoUrl'] ?? data['imagenUrl'];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: _buildAvatar(fotoUrl),
                        title: Text(
                          equipo.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Categoría: ${equipo.categoria} | D.T: ${equipo.entrenador}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              tooltip: 'Editar Equipo',
                              onPressed: () {
                                _mostrarDialogoEditarEquipo(equipo, userId);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.grid_on, color: Color.fromRGBO(55, 93, 134, 1),),
                              tooltip: 'Cancha y Rotación',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CanchaRotacionScreen(
                                      equipoId: equipo.id!,
                                      equipoNombre: equipo.nombre,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgregarJugadorScreen(
                                equipoId: equipo.id!,
                                equipoNombre: equipo.nombre,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.draw_outlined),
            selectedIcon: Icon(Icons.draw),
            label: 'Pizarra Táctica',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Lista de Equipos',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Crear Equipo',
          ),
        ],
      ),
    );
  }
}
