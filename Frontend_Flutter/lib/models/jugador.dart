class Jugador {
  final String? id;
  final String nombre;
  final int numero;
  final String posicion; // Ej: 'Colocador', 'Central', 'Opuesto', 'Punta', 'Libero'

  Jugador({
    this.id,
    required this.nombre,
    required this.numero,
    required this.posicion,
  });

  // Convertir Objeto Dart a JSON para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'numero': numero,
      'posicion': posicion,
    };
  }

  // Convertir JSON de Firestore a Objeto Dart
  factory Jugador.fromMap(String id, Map<String, dynamic> map) {
    return Jugador(
      id: id,
      nombre: map['nombre'] ?? '',
      numero: map['numero'] ?? 0,
      posicion: map['posicion'] ?? 'Punta',
    );
  }
}
