class Partido {
  final String? id;
  final String equipoId;
  final String equipoNombre;
  final String rivalNombre;
  final int puntosMiEquipo;
  final int puntosRival;
  final int setsMiEquipo;
  final int setsRival;
  final int setActual;
  final bool sacaMiEquipo;
  final String estado; // 'en_progreso', 'finalizado'

  Partido({
    this.id,
    required this.equipoId,
    required this.equipoNombre,
    required this.rivalNombre,
    this.puntosMiEquipo = 0,
    this.puntosRival = 0,
    this.setsMiEquipo = 0,
    this.setsRival = 0,
    this.setActual = 1,
    this.sacaMiEquipo = true,
    this.estado = 'en_progreso',
  });

  Map<String, dynamic> toMap() {
    return {
      'equipoId': equipoId,
      'equipoNombre': equipoNombre,
      'rivalNombre': rivalNombre,
      'puntosMiEquipo': puntosMiEquipo,
      'puntosRival': puntosRival,
      'setsMiEquipo': setsMiEquipo,
      'setsRival': setsRival,
      'setActual': setActual,
      'sacaMiEquipo': sacaMiEquipo,
      'estado': estado,
      'fecha': DateTime.now().toIso8601String(),
    };
  }

  factory Partido.fromMap(String id, Map<String, dynamic> map) {
    return Partido(
      id: id,
      equipoId: map['equipoId'] ?? '',
      equipoNombre: map['equipoNombre'] ?? 'Mi Equipo',
      rivalNombre: map['rivalNombre'] ?? 'Rival',
      puntosMiEquipo: map['puntosMiEquipo'] ?? 0,
      puntosRival: map['puntosRival'] ?? 0,
      setsMiEquipo: map['setsMiEquipo'] ?? 0,
      setsRival: map['setsRival'] ?? 0,
      setActual: map['setActual'] ?? 1,
      sacaMiEquipo: map['sacaMiEquipo'] ?? true,
      estado: map['estado'] ?? 'en_progreso',
    );
  }
}
