import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;
  String? _kioskToken;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:5265',
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
  }

  void clearToken() {
    _kioskToken = null;
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

  // --- BRANDING ---
  Future<Response> getBranding(String tenantId) {
    return _dio.get('/api/portal/branding', queryParameters: {
      'tenantId': tenantId,
    });
  }

  // --- HUÉSPEDES ---
  Future<Response> getBalance(String email, String tenantId) {
    return _dio.get('/api/portal/balance', queryParameters: {
      'email': email,
      'tenantId': tenantId,
    });
  }

  Future<Response> createCustomer({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) {
    return _dio.post('/api/customers', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    });
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
