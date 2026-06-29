import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      home: const PantallaBienvenida(),
    );
  }
}

// modelo para guardar los datos de cada cupon juas juas
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
  
  final String _urlJson = 'https://raw.githubusercontent.com/SevenEquisde/love./refs/heads/main/cupones.json';

  List<Cupon> _listaCupones = [];
  List<String> _idsCanjeados = [];
  bool _cargando = true; 
  late ConfettiController _controladorConfeti;

  @override
  void initState() {
    super.initState();
    _controladorConfeti = ConfettiController(duration: const Duration(seconds: 2));
    _inicializarApp();
  }

  @override
  void dispose() {
    _controladorConfeti.dispose();
    super.dispose();
  }

  // Función que carga la memoria local y descarga los cupones de internet
  Future<void> _inicializarApp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _idsCanjeados = prefs.getStringList('cupones_usados') ?? [];
    });

    try {
      final respuesta = await http.get(Uri.parse(_urlJson));
      
      if (respuesta.statusCode == 200) {
        // Si responde bien, decodificamos el texto a una lista
        final List<dynamic> datosJson = json.decode(respuesta.body);
        
        setState(() {
          _listaCupones = datosJson.map((json) => Cupon(
            id: json['id'],
            titulo: json['titulo'],
            descripcion: json['descripcion'],
            icono: _obtenerIcono(json['icono']),
          )).toList();
          _cargando = false;
        });
      }
    } catch (e) {
      // Si no hay internet o falla el link
      setState(() {
        _cargando = false;
      });
      debugPrint('Error cargando JSON: $e');
    }
  }

  // Traductor de texto a icono de Flutter
  IconData _obtenerIcono(String nombreIcono) {
    switch (nombreIcono) {
      case 'restaurant': return Icons.restaurant_rounded;
      case 'movie': return Icons.movie_rounded;
      case 'gavel': return Icons.gavel_rounded;
      case 'heart': return Icons.favorite_rounded;
      case 'study': return Icons.book_rounded;
      case 'history': return Icons.history_edu_rounded;

      default: return Icons.card_giftcard_rounded;
    }
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
          // Si está cargando muestra la ruedita, si no, muestra la lista
          body: _cargando 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listaCupones.length,
                  itemBuilder: (context, index) {
                    final cupon = _listaCupones[index];
                    final estaCanjeado = _idsCanjeados.contains(cupon.id);

                    return _construirTarjeta(cupon, estaCanjeado, context);
                  },
                ),
        ),
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

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa 1: Contenido central (Mensaje y Botón)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Un icono decorativo 
                Icon(
                  Icons.favorite_rounded,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Sorpresa!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Algo especial para alguien especial',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Botón de Entrar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    elevation: 4,
                  ),
                  onPressed: () {
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaVales(),
                      ),
                    );
                  },
                  child: const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Texto de la versión juas juas
          const Positioned(
            bottom: 16,
            right: 16,
            child: Text(
              'Versión 1.1',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  