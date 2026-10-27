import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'features/kiosk/kiosk_screen.dart';
import 'features/kiosk/pairing_screen.dart';

void main() {
  runApp(const ProviderScope(child: KioskApp()));
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loyalty Benefit Kiosko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF4F46E5),
      ),
      home: const _AuthWrapper(),
    );
  }
}

class _AuthWrapper extends ConsumerStatefulWidget {
  const _AuthWrapper();

  @override
  ConsumerState<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<_AuthWrapper> {
  bool _isLoading = true;
  bool _isPaired = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'kiosk_token');

    if (token != null && token.isNotEmpty) {
      try {
        final api = ref.read(apiClientProvider);
        api.setKioskToken(token);
        final response = await api.validateToken(token);
        
        if (response.statusCode == 200) {
          _isPaired = true;
        }
      } catch (e) {
        // Si el token expiró o falló, forzamos re-vincular
        await storage.delete(key: 'kiosk_token');
        _isPaired = false;
      }
    } else {
      _isPaired = false;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }

    return _isPaired ? const KioskScreen() : const PairingScreen();
  }
}
