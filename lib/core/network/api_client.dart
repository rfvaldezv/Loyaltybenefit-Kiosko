import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.loyaltybenefit.com', // Producción
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<Response> getBalance({required String tenantId, required String email}) async {
    return _dio.get('/api/portal/balance', 
      queryParameters: {'email': email, 'tenantId': tenantId},
    );
  }

  Future<Response> createCustomer({
    required String tenantId,
    required String name,
    required String email,
  }) async {
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return _dio.post('/api/customers', 
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      },
      options: Options(headers: {'X-Tenant-Id': tenantId}),
    );
  }

  Future<Response> getTenantBranding(String tenantId) async {
    return _dio.get('/api/portal/branding/$tenantId');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
