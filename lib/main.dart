import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const AppRegalo());
}

class AppRegalo extends StatelessWidget {
  const AppRegalo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupones para mi niña <3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          background: const Color(0xFFFFF5F5),
        ),
      ),
      home: const PantallaVales(),
    );
  }
}

// Nuestro modelo de datos
class Cupon {
  final String id;
  final String titulo;
  final String descripcion;
  final IconData icono;

  Cupon({required this.id, required this.titulo, required this.descripcion, required this.icono});
}

class PantallaVales extends StatefulWidget {
  const PantallaVales({super.key});

  @override
  State<PantallaVales> createState() => _PantallaValesState();
}

class _PantallaValesState extends State<PantallaVales> {
  // Datos hardcodeados temporalmente para trabajar puro Frontend
  final List<Cupon> _listaCupones = [
    Cupon(id: '001', titulo: 'Cena', descripcion: 'Válido para una cena.', icono: Icons.restaurant_rounded),
    Cupon(id: '002', titulo: 'Tarde de Pelis', descripcion: 'Tú eliges qué vemos. Prohibido dormirse.', icono: Icons.movie_rounded),
    Cupon(id: '003', titulo: 'Razón Absoluta', descripcion: 'Válido para tener la razón en una mini discusión.', icono: Icons.gavel_rounded),
  ];

  List<String> _idsCanjeados = [];
  late ConfettiController _controladorConfeti;

  @override
  void initState() {
    super.initState();
    _controladorConfeti = ConfettiController(duration: const Duration(seconds: 2));
    _cargarCuponesUsados();
  }

  @override
  void dispose() {
    _controladorConfeti.dispose();
    super.dispose();
  }

  // Leer memoria local
  Future<void> _cargarCuponesUsados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idsCanjeados = prefs.getStringList('cupones_usados') ?? [];
    });
  }

  // Guardar en memoria local y festejar
  Future<void> _marcarComoCanjeado(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idsCanjeados.add(id);
    });
    await prefs.setStringList('cupones_usados', _idsCanjeados);
    _controladorConfeti.play();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Para mi niña', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _listaCupones.length,
            itemBuilder: (context, index) {
              final cupon = _listaCupones[index];
              final estaCanjeado = _idsCanjeados.contains(cupon.id);

              return _construirTarjeta(cupon, estaCanjeado, context);
            },
          ),
        ),
        // ¡El confeti!
        ConfettiWidget(
          confettiController: _controladorConfeti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Colors.pink, Colors.red, Colors.white],
        ),
      ],
    );
  }

  Widget _construirTarjeta(Cupon cupon, bool estaCanjeado, BuildContext context) {
    return Opacity(
      opacity: estaCanjeado ? 0.5 : 1.0,
      child: Card(
        elevation: estaCanjeado ? 0 : 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            radius: 30,
            child: Icon(cupon.icono, color: Theme.of(context).colorScheme.primary, size: 30),
          ),
          title: Text(cupon.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(cupon.descripcion),
          ),
          trailing: estaCanjeado
              ? const Text('CANJEADO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
              : ElevatedButton(
                  onPressed: () => _marcarComoCanjeado(cupon.id),
                  child: const Text('Usar'),
                ),
        ),
      ),
    );
  }
}