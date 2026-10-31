class Equipo {
  final String? id;
  final String nombre;
  final String categoria;
  final String entrenador;
  final String? fotoUrl;

  Equipo({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.entrenador,
    this.fotoUrl,
  });

  factory Equipo.fromMap(String id, Map<String, dynamic> map) {
    return Equipo(
      id: id,
      nombre: map['nombre'] ?? '',
      categoria: map['categoria'] ?? '',
      entrenador: map['entrenador'] ?? '',
      fotoUrl: map['fotoUrl'] ?? map['imagenUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria': categoria,
      'entrenador': entrenador,
      'fotoUrl': fotoUrl,
    };
  }
}
