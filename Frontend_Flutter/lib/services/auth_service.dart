import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar Sesión con Email y Contraseña
  Future<UserCredential?> iniciarSesion(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _manejarErrorAuth(e.code);
    }
  }

  // Registrar Nuevo Usuario con Email y Contraseña
  Future<UserCredential?> registrarUsuario(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _manejarErrorAuth(e.code);
    }
  }

  // Enviar correo de recuperación de contraseña
  Future<void> recuperarPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _manejarErrorAuth(e.code);
    }
  }

  // Cerrar Sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // Mensajes de error amigables
  String _manejarErrorAuth(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      default:
        return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}
