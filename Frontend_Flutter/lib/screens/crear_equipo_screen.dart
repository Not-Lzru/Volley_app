import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'pizarra_tactica_screen.dart';
import 'lista_equipos_screen.dart';
import '../services/auth_service.dart';
import 'perfil_screen.dart';

class CrearEquipoScreen extends StatefulWidget {
  const CrearEquipoScreen({super.key});

  @override
  State<CrearEquipoScreen> createState() => _CrearEquipoScreenState();
}

class _CrearEquipoScreenState extends State<CrearEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _entrenadorController = TextEditingController();

  File? _imagenLocal;
  String? _imagenBase64;
  bool _cargando = false;
  int _selectedIndex = 2; // 'Crear Equipo' (índice 2)

  // Método para seleccionar una imagen desde la galería del dispositivo
  Future<void> _seleccionarImagenGaleria() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65, // Comprimir la imagen para optimizar almacenamiento en Firestore
      maxWidth: 600,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenLocal = File(imagen.path);
        _imagenBase64 = base64Encode(bytes); // Convertir imagen a texto Base64
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PizarraTacticaScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListaEquiposScreen()),
      );
    } else if (index == 2) {
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> _guardarEquipo() async {
    if (_formKey.currentState!.validate()) {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado.')),
        );
        return;
      }

      setState(() => _cargando = true);

      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('equipos')
            .add({
          'nombre': _nombreController.text.trim(),
          'categoria': _categoriaController.text.trim(),
          'entrenador': _entrenadorController.text.trim(),
          'fotoUrl': _imagenBase64 ?? '', // Guardamos la cadena de la imagen seleccionada
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Equipo creado exitosamente!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ListaEquiposScreen()),
          );
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

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _entrenadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_volleyball, color: Colors.amber),
            SizedBox(width: 8),
            Text('Nuevo Equipo'),
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
            itemBuilder: (context) => <PopupMenuEntry<String>>[
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Selector visual para la foto/escudo del equipo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage: _imagenLocal != null
                          ? FileImage(_imagenLocal!)
                          : null,
                      child: _imagenLocal == null
                          ? const Icon(Icons.shield, size: 50, color: Colors.indigo)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _seleccionarImagenGaleria,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.add_a_photo, size: 18, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _seleccionarImagenGaleria,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Cargar Escudo desde Galería'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Equipo',
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (val) => val!.isEmpty ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(
                  labelText: 'Categoría (Ej: Varonil Libre, Femenil U18)',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (val) => val!.isEmpty ? 'Ingresa la categoría' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _entrenadorController,
                decoration: const InputDecoration(
                  labelText: 'Director Técnico / Entrenador',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val!.isEmpty ? 'Ingresa el nombre del DT' : null,
              ),
              const SizedBox(height: 24),
              _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _guardarEquipo,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Equipo'),
                    ),
            ],
          ),
        ),
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
