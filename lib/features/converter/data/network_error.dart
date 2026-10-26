import 'package:dio/dio.dart';

import '../domain/rate_error.dart';

RateError mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return RateError.timeout;
    case DioExceptionType.badResponse:
      return RateError.badResponse;
    case DioExceptionType.transformTimeout:
      return RateError.timeout;
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return RateError.network;
  }
}
