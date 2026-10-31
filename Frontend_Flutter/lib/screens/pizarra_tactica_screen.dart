import 'package:flutter/material.dart';
import 'lista_equipos_screen.dart';
import 'crear_equipo_screen.dart';
import 'perfil_screen.dart';
import '../services/auth_service.dart';

// Modelo para guardar las trazas dibujadas con el dedo
class Trazo {
  final List<Offset> puntos;
  final Color color;
  final double grosor;

  Trazo({required this.puntos, required this.color, required this.grosor});
}

class PizarraTacticaScreen extends StatefulWidget {
  const PizarraTacticaScreen({super.key});

  @override
  State<PizarraTacticaScreen> createState() => _PizarraTacticaScreenState();
}

class _PizarraTacticaScreenState extends State<PizarraTacticaScreen> {
  final List<Trazo> _trazos = [];
  List<Offset> _puntosActuales = [];
  Color _colorSeleccionado = Colors.yellowAccent;
  bool _esGoma = false;
  int _selectedIndex = 0; // 'Pizarra Táctica' (índice 0)

  // Posiciones iniciales de las fichas (Pos 1 a Pos 6)
  final List<Offset> _posicionesJugadores = [
    const Offset(220, 320), // Pos 1 (Saque/Zaguero D)
    const Offset(220, 100), // Pos 2 (Delantero D)
    const Offset(130, 100), // Pos 3 (Delantero C)
    const Offset(40, 100),  // Pos 4 (Delantero I)
    const Offset(40, 320),  // Pos 5 (Zaguero I)
    const Offset(130, 320), // Pos 6 (Zaguero C)
  ];

  void _limpiarTodo() {
    setState(() {
      _trazos.clear();
      _puntosActuales.clear();
    });
  }

  void _deshacerUltimo() {
    if (_trazos.isNotEmpty) {
      setState(() {
        _trazos.removeLast();
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      setState(() => _selectedIndex = index);
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListaEquiposScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CrearEquipoScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_volleyball, color: Colors.amber),
            SizedBox(width: 8),
            Text('Pizarra Táctica'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer',
            onPressed: _deshacerUltimo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Limpiar Cancha',
            onPressed: _limpiarTodo,
          ),
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
      body: Column(
        children: [
          // Barra Superior de Herramientas para Dibujar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.black54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _botonColor(Colors.yellowAccent),
                _botonColor(Colors.white),
                _botonColor(Colors.cyanAccent),
                _botonColor(Colors.redAccent),
                _botonColor(Colors.greenAccent),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    Icons.cleaning_services,
                    color: _esGoma ? Colors.amber : Colors.white,
                  ),
                  tooltip: 'Modo Borrador',
                  onPressed: () {
                    setState(() {
                      _esGoma = !_esGoma;
                    });
                  },
                ),
              ],
            ),
          ),

          // Cancha Interactiva
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // 1. Cancha y Lienzo para Dibujar
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _puntosActuales = [details.localPosition];
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _puntosActuales.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _trazos.add(
                              Trazo(
                                puntos: List.from(_puntosActuales),
                                color: _esGoma ? Colors.orange[800]! : _colorSeleccionado,
                                grosor: _esGoma ? 18.0 : 4.0,
                              ),
                            );
                            _puntosActuales = [];
                          });
                        },
                        child: Container(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          decoration: BoxDecoration(
                            color: Colors.orange[800],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CustomPaint(
                              painter: PizarraPainter(
                                trazos: _trazos,
                                puntosActuales: _puntosActuales,
                                colorActual: _esGoma ? Colors.orange[800]! : _colorSeleccionado,
                                grosorActual: _esGoma ? 18.0 : 4.0,
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.white54, width: 2)),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 6,
                                    color: Colors.black,
                                    width: double.infinity,
                                  ),
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.white54, width: 2)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Fichas Arrastrables con Control Numérico
                      ...List.generate(6, (index) {
                        return Positioned(
                          left: _posicionesJugadores[index].dx,
                          top: _posicionesJugadores[index].dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                double newX = _posicionesJugadores[index].dx + details.delta.dx;
                                double newY = _posicionesJugadores[index].dy + details.delta.dy;

                                // Delimitar movimiento dentro de la cancha
                                newX = newX.clamp(0.0, constraints.maxWidth - 44.0);
                                newY = newY.clamp(0.0, constraints.maxHeight - 44.0);

                                _posicionesJugadores[index] = Offset(newX, newY);
                              });
                            },
                            child: _fichaJugador(index + 1),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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

  Widget _botonColor(Color color) {
    final bool seleccionado = !_esGoma && _colorSeleccionado == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _colorSeleccionado = color;
          _esGoma = false;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? Colors.indigo : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _fichaJugador(int numero) {
    return Material(
      color: Colors.transparent,
      elevation: 4,
      shape: const CircleBorder(),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.indigo[900],
        child: Text(
          'P$numero',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Pintador nativo del lienzo
class PizarraPainter extends CustomPainter {
  final List<Trazo> trazos;
  final List<Offset> puntosActuales;
  final Color colorActual;
  final double grosorActual;

  PizarraPainter({
    required this.trazos,
    required this.puntosActuales,
    required this.colorActual,
    required this.grosorActual,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var trazo in trazos) {
      final paint = Paint()
        ..color = trazo.color
        ..strokeWidth = trazo.grosor
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < trazo.puntos.length - 1; i++) {
        canvas.drawLine(trazo.puntos[i], trazo.puntos[i + 1], paint);
      }
    }

    if (puntosActuales.isNotEmpty) {
      final paint = Paint()
        ..color = colorActual
        ..strokeWidth = grosorActual
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < puntosActuales.length - 1; i++) {
        canvas.drawLine(puntosActuales[i], puntosActuales[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PizarraPainter oldDelegate) => true;
}
