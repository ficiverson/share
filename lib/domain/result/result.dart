/// Política de obtención de datos (para repositorios que combinan caché local
/// y origen remoto).
enum DataPolicy { cache, network, networkCache }

/// Estado de un [Result]: éxito o fallo.
enum Status { ok, fail }

/// Origen de los datos devueltos.
enum DataProvider { local, network }

/// Resultado genérico que devuelve cualquier caso de uso a través del
/// [Invoker]. La UI distingue entre [Success] y [Error] usando `is`.
class Result<T> {
  Status? status;
  DataProvider? provider;
  T? data;

  Result(this.status, this.data);

  T? getData() => data;

  Status? getStatus() => status;
}

class Success<T> extends Result<T> {
  Success(T data, Status dataStatus) : super(dataStatus, data);
}

class Error<T> extends Result<T> {
  String error;

  Error(T data, Status dataStatus, this.error) : super(dataStatus, data);

  String getError() => error;
}
