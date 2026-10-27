import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class KioskScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const KioskScreen({super.key, required this.tenantId});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';

  // 👇 Variables para el Branding
  String _brandingName = 'Bienvenido';
  String? _brandingLogoUrl;
  Color _brandingPrimary = Colors.indigo.shade900;

  // 👇 Variable para detectar si el cliente ya existe
  Map<String, dynamic>? _clienteExistente;

  @override
  void initState() {
    super.initState();
    _cargarBranding();
  }

  Future<void> _cargarBranding() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getTenantBranding(widget.tenantId);
      
      if (mounted) {
        setState(() {
          _brandingName = response.data['nombre'] ?? 'Bienvenido';
          _brandingLogoUrl = response.data['logoUrl'];
          String hexPrimary = (response.data['colorPrimario'] ?? '#1A237E').replaceAll('#', '');
          _brandingPrimary = Color(int.parse('FF$hexPrimary', radix: 16));
        });
      }
    } catch (e) {
      // Default
    }
  }

  Future<void> _buscarORegistrar() async {
    if (_emailController.text.isEmpty) {
      setState(() => _statusMessage = 'Por favor, ingresa tu correo.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Buscando...';
    });

    try {
      final api = ref.read(apiClientProvider);
      
      // 1. Intentamos buscar al cliente
      try {
        final response = await api.getBalance(tenantId: widget.tenantId, email: _emailController.text);
        
        // ¡El cliente existe! Mostramos su tarjeta de puntos
        if (mounted) {
          setState(() {
            _clienteExistente = response.data;
            _isLoading = false;
            _statusMessage = '';
          });
        }
      } catch (e) {
        // 2. Si no existe (404), preparamos el registro
        if (e.toString().contains('404')) {
          if (_nameController.text.isEmpty) {
            setState(() {
              _statusMessage = 'No te encontramos. Ingresa tu nombre para registrarte.';
              _isLoading = false;
            });
          } else {
            // Ya tenemos el nombre, lo registramos
            await api.createCustomer(
              tenantId: widget.tenantId,
              name: _nameController.text,
              email: _emailController.text,
            );
            // Después de registrarlo, lo buscamos de nuevo para mostrar su tarjeta
            final newResponse = await api.getBalance(tenantId: widget.tenantId, email: _emailController.text);
            
            if (mounted) {
              setState(() {
                _clienteExistente = newResponse.data;
                _isLoading = false;
                _statusMessage = '';
              });
            }
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error de conexión. Contacta a recepción.';
        _isLoading = false;
      });
    }
  }

  void _resetearKiosko() {
    setState(() {
      _clienteExistente = null;
      _emailController.clear();
      _nameController.clear();
      _statusMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // 👇 Si el cliente existe, mostramos su tarjeta (Modo Consulta)
    if (_clienteExistente != null) {
      return _buildTarjetaCliente();
    }

    // 👇 Si no existe, mostramos el formulario (Modo Registro/Login)
    return Scaffold(
      backgroundColor: _brandingPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_brandingLogoUrl != null && _brandingLogoUrl!.isNotEmpty)
                Image.network(_brandingLogoUrl!, height: 100, errorBuilder: (_, __, ___) => const Icon(Icons.touch_app, size: 100, color: Colors.white))
              else
                const Icon(Icons.touch_app, size: 100, color: Colors.white),
              
              const SizedBox(height: 20),
              Text(_brandingName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Ingresa tu correo para acumular o consultar puntos', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.white70)),
              const SizedBox(height: 40),
              
              // Email
              SizedBox(
                width: 500,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(fontSize: 24),
                  decoration: InputDecoration(
                    hintText: 'Tu correo electrónico',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    prefixIcon: const Icon(Icons.email, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nombre (solo se muestra si el mensaje pide registro)
              if (_statusMessage.contains('Ingresa tu nombre')) ...[
                SizedBox(
                  width: 500,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      hintText: 'Tu nombre completo',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      prefixIcon: const Icon(Icons.person, size: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 20),
              
              // Botón Principal
              SizedBox(
                width: 500,
                height: 80,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buscarORegistrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _statusMessage.contains('Ingresa tu nombre') ? 'REGISTRARME' : 'INGRESAR', 
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                        ),
                ),
              ),
              const SizedBox(height: 30),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, color: Colors.yellowAccent)),
            ],
          ),
        ),
      ),
    );
  }

  // 👇 Pantalla que ve el cliente que YA está registrado
  Widget _buildTarjetaCliente() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_brandingPrimary, _brandingPrimary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: _brandingPrimary.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text('¡Hola, ${_clienteExistente!['cliente']}!', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                const Text('TUS PUNTOS', style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 2)),
                Text('${_clienteExistente!['puntos']}', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text('Nivel: ${_clienteExistente!['nivel']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _resetearKiosko,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Finalizar / Siguiente Cliente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _brandingPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
