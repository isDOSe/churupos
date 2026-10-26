enum RateError { network, timeout, badResponse, unavailable }

class RateFailure implements Exception {
  const RateFailure(this.kind, [this.detail]);

  final RateError kind;
  final String? detail;

  @override
  String toString() =>
      'RateFailure(${kind.name}${detail == null ? '' : ': $detail'})';
}

String rateErrorMessage(RateError error) => switch (error) {
  RateError.network => 'Sin conexión',
  RateError.timeout => 'La consulta tardó demasiado',
  RateError.badResponse => 'Respuesta inesperada',
  RateError.unavailable => 'Sin ofertas disponibles',
};
