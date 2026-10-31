class EstadisticaJugador {
  final String jugadorId;
  final String nombreJugador;
  final int numeroJugador;
  int ataquesExitosos;
  int bloqueos;
  int aces;
  int erroresSaque;
  int erroresAtaque;

  EstadisticaJugador({
    required this.jugadorId,
    required this.nombreJugador,
    required this.numeroJugador,
    this.ataquesExitosos = 0,
    this.bloqueos = 0,
    this.aces = 0,
    this.erroresSaque = 0,
    this.erroresAtaque = 0,
  });

  int get totalPuntos => ataquesExitosos + bloqueos + aces;
  int get totalErrores => erroresSaque + erroresAtaque;

  Map<String, dynamic> toMap() {
    return {
      'jugadorId': jugadorId,
      'nombreJugador': nombreJugador,
      'numeroJugador': numeroJugador,
      'ataquesExitosos': ataquesExitosos,
      'bloqueos': bloqueos,
      'aces': aces,
      'erroresSaque': erroresSaque,
      'erroresAtaque': erroresAtaque,
      'totalPuntos': totalPuntos,
      'totalErrores': totalErrores,
    };
  }

  factory EstadisticaJugador.fromMap(Map<String, dynamic> map) {
    return EstadisticaJugador(
      jugadorId: map['jugadorId'] ?? '',
      nombreJugador: map['nombreJugador'] ?? '',
      numeroJugador: map['numeroJugador'] ?? 0,
      ataquesExitosos: map['ataquesExitosos'] ?? 0,
      bloqueos: map['bloqueos'] ?? 0,
      aces: map['aces'] ?? 0,
      erroresSaque: map['erroresSaque'] ?? 0,
      erroresAtaque: map['erroresAtaque'] ?? 0,
    );
  }
}
