// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class KioskScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const KioskScreen({super.key, this.tenantId = 'D8D6CB00-2600-4A83-9C4E-02F76065210D'});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  // Controladores
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  String? _errorMessage;
  
  // Pantallas: 0 = Inicio, 1 = Registro, 2 = Saldo/Bienvenida, 3 = Registro Exitoso
  int _currentScreen = 0; 
  
  String? _clientName;
  int? _clientPoints;

  Color _primaryColor = const Color(0xFF4F46E5);
  Color _secondaryColor = const Color(0xFF8B5CF6);
  String? _logoUrl;

  bool get _isWebLocal {
    if (!kIsWeb) return false;
    try {
      return html.window.location.hostname == 'localhost';
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarBranding();
  }

  Future<void> _cargarBranding() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getBranding(widget.tenantId);
      if (response.statusCode == 200) {
        setState(() {
          _primaryColor = _hexToColor(response.data['primaryColor'] ?? '#4F46E5');
          _secondaryColor = _hexToColor(response.data['secondaryColor'] ?? '#8B5CF6');
          _logoUrl = response.data['logoUrl'];
        });
      }
    } catch (e) {
      // Ignorar
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // --- LÓGICA ---
  Future<void> _buscarCliente() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getBalance(email, widget.tenantId);

      if (response.statusCode == 200) {
        setState(() {
          _clientName = response.data['cliente'];
          _clientPoints = response.data['puntos'];
          _currentScreen = 2; // Ir a pantalla de Saldo
        });
        _iniciarTimerRegreso();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Cliente no existe -> Ir a Registro
        setState(() {
          _currentScreen = 1;
        });
      } else {
        setState(() => _errorMessage = 'Error de conexión. Intenta de nuevo.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarCliente() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim().isEmpty ? "Sin Apellido" : _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre y el correo son obligatorios'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      await api.createCustomer(
        firstName: firstName, 
        lastName: lastName, 
        email: email, 
        phone: phone.isEmpty ? null : phone, 
      );
      
      // Si el registro fue exitoso, mostramos la pantalla de ÉXITO (no error)
      setState(() {
        _clientName = firstName.trim(); // <-- .trim() para quitar espacios o caracteres raros
        _currentScreen = 3; // Pantalla de Registro Exitoso
      });

    } on DioException catch (e) {
      if (e.response?.statusCode == 409 || e.response?.statusCode == 400) {
        // Si el correo ya existe, también lo tratamos como ÉXITO (ya está registrado)
        setState(() {
          _clientName = firstName;
          _currentScreen = 3; // Pantalla de Registro Exitoso
        });
      } else {
        setState(() => _errorMessage = 'Error al registrar. Intenta de nuevo.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _iniciarTimerRegreso() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _currentScreen == 2) {
        _resetearPantalla();
      }
    });
  }

  void _resetearPantalla() {
    setState(() {
      _currentScreen = 0;
      _emailController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _clientName = null;
      _clientPoints = null;
      _errorMessage = null;
    });
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ENCABEZADO (Arreglado para que no se mueva)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_primaryColor, _secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  if (_logoUrl != null && _logoUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Image.network(
                        // Si es web local, usamos localhost. Si no, producción.
                        _isWebLocal ? 'http://localhost:5265$_logoUrl' : 'https://api.loyaltybenefit.com$_logoUrl', 
                        height: 80, 
                        errorBuilder: (c, e, s) {
                          // Si el logo no carga, mostramos un ícono genérico
                          return const Icon(Icons.business, color: Colors.white, size: 80);
                        }
                      ),
                    ),
                  const Text('Bienvenido', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Ingresa tu correo para acumular o consultar puntos', style: TextStyle(fontSize: 20, color: Colors.white70)),
                ],
              ),
            ),

            // CONTENIDO
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(32.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentScreen(),
                  ),
                ),
              ),
            ),

            // PIE DE PÁGINA
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Powered by Loyalty Benefit', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_isLoading) {
      return const Center(key: ValueKey('loading'), child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    if (_errorMessage != null) {
      return Column(
        key: const ValueKey('error'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _resetearPantalla, child: const Text('Volver a intentar')),
        ],
      );
    }

    switch (_currentScreen) {
      case 1:
        return _buildRegistrationScreen();
      case 2:
        return _buildSuccessScreen();
      case 3:
        return _buildRegistrationSuccessScreen();
      default:
        return _buildIdleScreen();
    }
  }

  // PANTALLA 0: INGRESO DE CORREO
  Widget _buildIdleScreen() {
    return Column(
      key: const ValueKey('idle'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          decoration: InputDecoration(
            hintText: 'Tu correo electrónico',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.email, color: Colors.white54, size: 30),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 70,
          child: ElevatedButton(
            onPressed: _buscarCliente,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 10,
              shadowColor: Colors.greenAccent.withValues(alpha: 0.5),
            ),
            child: const Text('INGRESAR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  // PANTALLA 1: REGISTRO
  Widget _buildRegistrationScreen() {
    return SingleChildScrollView(
      key: const ValueKey('registration'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white54),
                onPressed: _resetearPantalla,
              ),
              const Expanded(
                child: Text('¡Parece que eres nuevo!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text('El correo ${_emailController.text} no está registrado.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 32),
          
          TextField(
            controller: _firstNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Nombre(s)'),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _lastNameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Apellidos'),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Teléfono (Opcional)'),
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _registrarCliente,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Registrarme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // PANTALLA 2: SALDO
  Widget _buildSuccessScreen() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 100),
        const SizedBox(height: 24),
        Text('¡Hola, $_clientName!', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const Text('Tu saldo actual es:', style: TextStyle(color: Colors.white54, fontSize: 22)),
        const SizedBox(height: 8),
        Text('$_clientPoints Puntos', style: TextStyle(color: _primaryColor, fontSize: 64, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        const Text('Por favor, pasa a recepción para canjear tus premios.', style: TextStyle(color: Colors.white54, fontSize: 18), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton(
            onPressed: _resetearPantalla,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // PANTALLA 3: REGISTRO EXITOSO
  Widget _buildRegistrationSuccessScreen() {
    return Column(
      key: const ValueKey('registration_success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo del hotel (si existe) o ícono de verificación
        if (_logoUrl != null && _logoUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Image.network(
              _isWebLocal ? 'http://localhost:5265$_logoUrl' : 'https://api.loyaltybenefit.com$_logoUrl', 
              height: 80, 
              errorBuilder: (c, e, s) => const SizedBox.shrink()
            ),
          )
        else
          const Icon(Icons.verified, color: Colors.greenAccent, size: 100),
          
        const SizedBox(height: 24),
        
        // Título con el nombre del cliente (usando trim para evitar la J)
        Text(
          '¡Registro Exitoso, $_clientName!', 
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold), 
          textAlign: TextAlign.center
        ),
        const SizedBox(height: 16),
        
        // Subtítulo
        const Text(
          'Ya eres parte de nuestro programa de lealtad.', 
          style: TextStyle(color: Colors.white54, fontSize: 20), 
          textAlign: TextAlign.center
        ),
        const SizedBox(height: 40),
        
        // Botón con el color del hotel
        SizedBox(
          width: 300,
          height: 60,
          child: ElevatedButton(
            onPressed: _resetearPantalla,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor, // Usa el color primario del hotel
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 8,
              shadowColor: _primaryColor.withValues(alpha: 0.5),
            ),
            child: const Text('Consultar mis Puntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
