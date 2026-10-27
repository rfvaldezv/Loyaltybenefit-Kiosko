import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/kiosk/kiosk_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: KioskApp(),
    ),
  );
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Uri uri = Uri.base;
    final String? tenantIdFromUrl = uri.queryParameters['tenant'];
    final String tenantId = tenantIdFromUrl ?? 'd8d6cb00-2600-4a83-9c4e-02f76065210d';

    return MaterialApp(
      title: 'Kiosko de Lealtad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: KioskScreen(tenantId: tenantId),
    );
  }
}
