import 'dart:io';
import 'package:dio/dio.dart';

class NetworkExceptions {
  static int getDioStatus(dynamic error) {
    if (error is Exception) {
      try {
        int? status;
        if (error is DioException) {
          switch (error.type) {
            case DioExceptionType.cancel:
              status = 500;
              break;
            case DioExceptionType.connectionTimeout:
              status = 500;
              break;
            case DioExceptionType.unknown:
              status = 500;
              break;
            case DioExceptionType.receiveTimeout:
              status = 500;
              break;
            case DioExceptionType.badResponse:
              switch (error.response!.statusCode) {
                case 400:
                  status = 400;
                  break;
                case 401:
                  status = 401;
                  break;
                case 403:
                  status = 403;
                  break;
                case 404:
                  status = 404;
                  break;
                case 409:
                  status = 409;
                  break;
                case 422:
                  status = 422;
                  break;
                case 408:
                  status = 408;
                  break;
                case 500:
                  status = 500;
                  break;
                case 503:
                  status = 503;
                  break;
                default:
                  status = 500;
              }
              break;
            case DioExceptionType.sendTimeout:
              status = 500;
              break;
            case DioExceptionType.badCertificate:
              // TODO: Handle this case.
              break;
            case DioExceptionType.connectionError:
              // TODO: Handle this case.
              break;
          }
        } else if (error is SocketException) {
          status = 500;
        } else {
          status = 500;
        }
        return status ?? 500;
      } on FormatException catch (_) {
        return 500;
      } catch (_) {
        return 500;
      }
    } else {
      if (error.toString().contains("is not a subtype of")) {
        return 500;
      } else {
        return 500;
      }
    }
  }
}
