import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- ESTA IMPORTACIÓN ES LA QUE FALTA
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? _user = FirebaseAuth.instance.currentUser;

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  File? _imagenLocal;
  String? _imagenBase64;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: _user?.displayName ?? '');
    _emailController = TextEditingController(text: _user?.email ?? '');
    _cargarFotoPerfilFirestore();
  }

  // Cargar la foto guardada en Firestore
  Future<void> _cargarFotoPerfilFirestore() async {
    if (_user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user!.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('fotoUrl')) {
        setState(() {
          _imagenBase64 = doc.data()!['fotoUrl'];
        });
      }
    } catch (_) {}
  }

  // Seleccionar foto de perfil desde la galería
  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 600,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenLocal = File(imagen.path);
        _imagenBase64 = base64Encode(bytes);
      });
    }
  }

  // Guardar los cambios del perfil
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _cargando = true);

    try {
      // 1. Actualizar Nombre de Usuario en Firebase Auth
      if (_nombreController.text.trim() != _user!.displayName) {
        await _user!.updateDisplayName(_nombreController.text.trim());
      }

      // 2. Guardar la Foto en Base64 dentro de Firestore (Evita el error de URL larga)
      if (_imagenBase64 != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_user!.uid)
            .set({
          'nombre': _nombreController.text.trim(),
          'fotoUrl': _imagenBase64,
          'email': _user!.email,
        }, SetOptions(merge: true));
      }

      // 3. Actualizar Correo Electrónico si cambió
      if (_emailController.text.trim() != _user!.email) {
        await _user!.verifyBeforeUpdateEmail(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se envió un correo de verificación a la nueva dirección.'),
            ),
          );
        }
      }

      // 4. Actualizar Contraseña (si se ingresó una nueva)
      if (_passwordController.text.trim().isNotEmpty) {
        if (_passwordController.text.trim().length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'La contraseña debe tener al menos 6 caracteres.',
          );
        }
        await _user!.updatePassword(_passwordController.text.trim());
        _passwordController.clear();
      }

      await _user!.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String mensaje = 'Error al actualizar: ${e.message}';
        if (e.code == 'requires-recent-login') {
          mensaje = 'Por seguridad, debes volver a iniciar sesión para cambiar esta información.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _buildAvatar() {
    if (_imagenLocal != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_imagenLocal!),
      );
    }

    if (_imagenBase64 != null && _imagenBase64!.isNotEmpty) {
      if (_imagenBase64!.startsWith('http')) {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(_imagenBase64!),
        );
      }
      try {
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64Decode(_imagenBase64!)),
        );
      } catch (_) {}
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.indigo.shade100,
      child: const Icon(Icons.person, size: 50, color: Colors.indigo),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selector de Foto de Perfil
              Center(
                child: Stack(
                  children: [
                    _buildAvatar(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _seleccionarFoto,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campo Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val!.trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 16),

              // Campo Correo Electrónico
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) => val!.trim().isEmpty ? 'Ingresa tu correo' : null,
              ),
              const SizedBox(height: 16),

              // Campo Nueva Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña (Opcional)',
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Déjalo en blanco si no deseas cambiarla',
                ),
              ),
              const SizedBox(height: 28),

              // Botón Guardar Cambios
              _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
                    ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 10),

              // Botón Cerrar Sesión en la parte inferior
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await AuthService().cerrarSesion();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
