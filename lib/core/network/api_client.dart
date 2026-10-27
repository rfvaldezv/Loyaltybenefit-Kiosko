import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;
  String? _kioskToken;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.loyaltybenefit.com',
	    //baseUrl: 'http://localhost:5265',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_kioskToken != null) {
          options.headers['X-Kiosk-Token'] = _kioskToken;
        }
        return handler.next(options);
      },
    ));
  }

  void setKioskToken(String token) {
    _kioskToken = token;
    _dio.options.headers['X-Kiosk-Token'] = token;
  }

  void clearToken() {
    _kioskToken = null;
    _dio.options.headers.remove('X-Kiosk-Token');
  }

  // --- PAIRING ---
  Future<Response> pairKiosk(String pairingCode) {
    return _dio.post('/api/kiosks/pair', data: {
      'pairingCode': pairingCode,
    });
  }

  Future<Response> validateToken(String token) {
    return _dio.get('/api/kiosks/me', queryParameters: {
      'kioskToken': token,
    });
  }

  // --- MÉTODOS DEL KIOSKO ---
  
  Future<Response> getTenantBranding(String tenantId) {
    return _dio.get('/api/portal/branding', queryParameters: {
      'tenantId': tenantId,
    });
  }

  // Aquí están los cambios: ahora usan {} (parámetros nombrados)
  Future<Response> getBalance({required String email, required String tenantId}) {
    return _dio.get('/api/portal/balance', queryParameters: {
      'email': email,
      'tenantId': tenantId,
    });
  }

  Future<Response> createCustomer({
    required String name,
    required String email,
    required String tenantId,
    String? phone,
  }) {
    return _dio.post('/api/customers', data: {
      'name': name,
      'email': email,
      'phone': phone,
    }, options: Options(
      headers: {'X-Tenant-Id': tenantId},
    ));
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
