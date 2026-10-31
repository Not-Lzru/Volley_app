import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/lista_equipos_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VolleyControlApp());
}

class VolleyControlApp extends StatelessWidget {
  const VolleyControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición de colores principales de la app
    const primaryNavy = Color(0xFF0D1B2A);      // Azul Marino Oscuro / Elegante
    const secondaryBlue = Color(0xFF1B263B);    // Azul Medio
    const accentVolt = Color(0xFFFFD166);       // Amarillo/Dorado Deportivo
    const backgroundColor = Color(0xFFF4F6F9);  // Gris Clarin (Fondo suave)

    return MaterialApp(
      title: 'Volley Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          primary: primaryNavy,
          secondary: accentVolt,
          surface: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        
        // Estilo Global de la Barra Superior (AppBar)
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),

        // Estilo Global de Tarjetas (Cards)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Bordes suaves
          ),
        ),

        // Estilo Global de Botones Principales
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Estilo Global de Campos de Texto (Input Decoration)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryNavy, width: 2),
          ),
          labelStyle: const TextStyle(color: secondaryBlue),
        ),

        // Botón Flotante (FAB)
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: primaryNavy),
              ),
            );
          }

          if (snapshot.hasData) {
            return const ListaEquiposScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
