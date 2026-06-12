import 'package:http/http.dart' as http;

/// Cliente HTTP autenticado, compartido por los datasources remotos de
/// Drive y Sheets. Envuelve cada petición añadiendo las cabeceras OAuth
/// obtenidas de [AuthRemoteDataSource.getAuthHeaders].
class GoogleApiClient extends http.BaseClient {
  final http.Client _inner;
  final Future<Map<String, String>> Function() getAuthHeaders;

  GoogleApiClient({required this.getAuthHeaders, http.Client? inner})
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await getAuthHeaders();
    request.headers.addAll(headers);
    return _inner.send(request);
  }
}
