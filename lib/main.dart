import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScamtoApp());
}

class ScamtoApp extends StatelessWidget {
  const ScamtoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCAMTO IA',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: const BluetoothDiscoveryPage(),
    );
  }
}

class BluetoothDiscoveryPage extends StatefulWidget {
  const BluetoothDiscoveryPage({super.key});
  @override
  State<BluetoothDiscoveryPage> createState() => _BluetoothDiscoveryPageState();
}

class _BluetoothDiscoveryPageState extends State<BluetoothDiscoveryPage> {
  late IO.Socket _socket;

  String? _miGenero;
  String? _miPreferencia;
  String? _miDeseo;
  bool _estaProcesandoIA = false;
  double _progresoIA = 0.0;
  bool _confirmarGeneroManual = false;
  bool _estaEscaneando = false;

  List<Map<String, dynamic>> _usuariosCercanos = [];
  final String _myId = "U${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

  @override
  void initState() {
    super.initState();
    _conectarServidorGratuito();
  }

  void _conectarServidorGratuito() {
    _socket = IO.io('https://scanto-server-production.up.railway.app', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      print('¡Conectado al servidor de Scanto exitosamente!');
    });

    _socket.on('recibir_mensaje', (data) {
      _mostrarModalChatEntrante(data['remitenteId'], data['mensaje']);
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  void _iniciarReconocimientoSimulado(String generoDetectado) {
    setState(() {
      _estaProcesandoIA = true;
      _progresoIA = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 30), (t) {
      if (!mounted || _progresoIA >= 1.0) {
        t.cancel();
        setState(() {
          _miGenero = generoDetectado;
          _estaProcesandoIA = false;
          _confirmarGeneroManual = true;
        });
      } else {
        setState(() => _progresoIA += 0.05);
      }
    });
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _activarRadar() async {
    setState(() {
      _confirmarGeneroManual = false;
      _estaEscaneando = true;
      _usuariosCercanos.clear();
    });

    _socket.emit('buscar_cercanos', {
      'id': _myId,
      'genero': _miGenero,
      'deseo': _miDeseo,
      'busca': _miPreferencia
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _estaEscaneando = false;
        _usuariosCercanos.add({
          "id": "U999888",
          "genero": _miPreferencia ?? "Hombre",
          "deseo": _miDeseo ?? "Hablar"
        });
      });
    }
  }

  void _mostrarModalTabChat(String receptorId) {
    TextEditingController mensajeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enviar Mensaje para Romper el Hielo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: mensajeCtrl,
              decoration: const InputDecoration(hintText: "Escribe algo amigable..."),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _socket.emit('enviar_mensaje', {
                  'remitenteId': _myId,
                  'destinatarioId': receptorId,
                  'mensaje': mensajeCtrl.text,
                });
                Navigator.pop(context);
                _showSnack("Solicitud de chat enviada 🚀");
              },
              child: const Text("Enviar Solicitud"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarModalChatEntrante(String remitenteId, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¡Nueva Solicitud de Chat!"),
        content: Text("Un usuario cercano te escribe:\n\n\"$mensaje\""),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ignorar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack("¡Conectados! Ya pueden interactuar.");
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: _buildFlujo()),
      );

  Widget _buildFlujo() {
    if (_estaProcesandoIA) return _pantallaCarga();
    if (_miGenero == null || _confirmarGeneroManual) return _pantallaBio();
    if (_miPreferencia == null) return _pantallaPreferencia();
    if (_miDeseo == null) return _pantallaDeseos();
    return _pantallaRadar();
  }

  Widget _pantallaCarga() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text("SCAMTO IA", style: TextStyle(letterSpacing: 8, fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 40),
          SizedBox(width: 200, child: LinearProgressIndicator(value: _progresoIA, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("Simulando biometría...", style: TextStyle(color: Colors.grey)),
        ]),
      );

  Widget _pantallaBio() => SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 40),
          const Text("VERIFICACIÓN", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.deepPurple)),
          const Text("Selecciona tu perfil (Versión Web)", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          Center(
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple.shade50,
                  border: Border.all(color: Colors.deepPurple.shade200, width: 6)),
              child: const Icon(Icons.face_retouching_natural, size: 90, color: Colors.deepPurple),
            ),
          ),
          const SizedBox(height: 40),
          _btn("SOY HOMBRE", Icons.male, Colors.blue, () => _iniciarReconocimientoSimulado("Hombre")),
          const SizedBox(height: 12),
          _btn("SOY MUJER", Icons.female, Colors.pink, () => _iniciarReconocimientoSimulado("Mujer")),
        ]),
      );

  Widget _pantallaPreferencia() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("QUIERO CONOCER:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 40),
        _btn("MUJERES", Icons.female, Colors.pink, () => setState(() => _miPreferencia = "Mujer")),
        const SizedBox(height: 15),
        _btn("HOMBRES", Icons.male, Colors.blue, () => setState(() => _miPreferencia = "Hombre")),
      ]);

  Widget _pantallaDeseos() => Column(children: [
        const SizedBox(height: 60),
        const Text("¿QUÉ TE APETECE HOY?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(25),
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _cardDeseo('Hablar', Icons.chat_bubble_outline, Colors.orange),
              _cardDeseo('Comer', Icons.restaurant_menu, Colors.red),
              _cardDeseo('Bailar', Icons.nightlife, Colors.purple),
              _cardDeseo('Cine', Icons.local_movies, Colors.blue),
            ],
          ),
        ),
      ]);

  Widget _cardDeseo(String t, IconData i, Color c) => InkWell(
      onTap: () {
        setState(() => _miDeseo = t);
        _activarRadar();
      },
      child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(i, color: c, size: 40),
            const SizedBox(height: 10),
            Text(t, style: const TextStyle(fontWeight: FontWeight.bold))
          ])));

  Widget _pantallaRadar() => Column(children: [
        ListTile(
          title: Text("Buscando $_miPreferencia cerca", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Mi perfil: $_miGenero • Mood: $_miDeseo"),
          trailing: _estaEscaneando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.refresh), onPressed: _activarRadar),
        ),
        if (_estaEscaneando) const LinearProgressIndicator(),
        Expanded(
            child: _usuariosCercanos.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text("No hay nadie cerca por ahora...", style: TextStyle(color: Colors.grey)),
                    ],
                  ))
                : ListView.builder(
                    itemCount: _usuariosCercanos.length,
                    itemBuilder: (c, i) {
                      final user = _usuariosCercanos[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundColor: user['genero'] == "Hombre" ? Colors.blue : Colors.pink,
                              child: const Icon(Icons.person, color: Colors.white)),
                          title: const Text("Usuario Detectado"),
                          subtitle: Text("Interés: ${user['deseo']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.bolt, color: Colors.amber),
                            onPressed: () => _mostrarModalTabChat(user['id']),
                          ),
                        ),
                      );
                    }))
      ]);

  Widget _btn(String t, IconData i, Color c, VoidCallback a) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: ElevatedButton.icon(
            onPressed: a,
            icon: Icon(i),
            label: Text(t),
            style: ElevatedButton.styleFrom(
                backgroundColor: c,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
      );
}