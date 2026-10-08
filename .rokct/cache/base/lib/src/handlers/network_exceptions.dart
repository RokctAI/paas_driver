// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_exceptions.freezed.dart';

@freezed
sealed class NetworkExceptions with _$NetworkExceptions {
  const factory NetworkExceptions.requestCancelled() = RequestCancelled;

  const factory NetworkExceptions.unauthorisedRequest() = UnauthorisedRequest;

  const factory NetworkExceptions.badRequest() = BadRequest;

  const factory NetworkExceptions.notFound(String reason) = NotFound;

  const factory NetworkExceptions.methodNotAllowed() = MethodNotAllowed;

  const factory NetworkExceptions.notAcceptable() = NotAcceptable;

  const factory NetworkExceptions.requestTimeout() = RequestTimeout;

  const factory NetworkExceptions.sendTimeout() = SendTimeout;

  const factory NetworkExceptions.conflict() = Conflict;

  const factory NetworkExceptions.internalServerError() = InternalServerError;

  const factory NetworkExceptions.notImplemented() = NotImplemented;

  const factory NetworkExceptions.serviceUnavailable() = ServiceUnavailable;

  const factory NetworkExceptions.noInternetConnection() = NoInternetConnection;

  const factory NetworkExceptions.formatException() = FormatException;

  const factory NetworkExceptions.unableToProcess() = UnableToProcess;

  const factory NetworkExceptions.defaultError(String error) = DefaultError;

  const factory NetworkExceptions.unexpectedError() = UnexpectedError;

  /// Classifies a thrown error into one of the variants above.
  ///
  /// Every arm used to be a bare `break` that fell through to a single
  /// `noInternetConnection()` return, so a refused connection, an expired
  /// certificate, a timeout, a cancelled request and every HTTP status
  /// alike came back as "the reader has no internet". That is the wrong
  /// answer for all but one of them, and it is the answer
  /// `AppHelpers.errorHandler` turned into a student-facing line — Ray,
  /// 2026-09-19: "not check your connection but check your network
  /// connection", on a phone whose network was fine and whose backend was
  /// not answering. Each arm now returns the variant it names.
  ///
  /// No new union member: a transport that never reached a responding
  /// server still answers [NoInternetConnection] here, and the
  /// offline-versus-unreachable wording is decided by
  /// `AppHelpers.errorHandler`, which holds the [DioException] itself.
  static NetworkExceptions getDioException(error) {
    if (error is Exception) {
      try {
        if (error is DioException) {
          switch (error.type) {
            case DioExceptionType.cancel:
              return const NetworkExceptions.requestCancelled();
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.transformTimeout:
              return const NetworkExceptions.requestTimeout();
            case DioExceptionType.sendTimeout:
              return const NetworkExceptions.sendTimeout();
            case DioExceptionType.badResponse:
              // `?.` not `!`: a badResponse carrying no response object
              // used to throw straight into the catch below and come back
              // as an unexpectedError. The default arm covers it.
              switch (error.response?.statusCode) {
                case 400:
                  return const NetworkExceptions.badRequest();
                case 401:
                case 403:
                  return const NetworkExceptions.unauthorisedRequest();
                case 404:
                  return NetworkExceptions.notFound(
                    error.response?.statusMessage ?? 'Not found',
                  );
                case 405:
                  return const NetworkExceptions.methodNotAllowed();
                case 406:
                  return const NetworkExceptions.notAcceptable();
                case 408:
                  return const NetworkExceptions.requestTimeout();
                case 409:
                  return const NetworkExceptions.conflict();
                case 500:
                  return const NetworkExceptions.internalServerError();
                case 501:
                  return const NetworkExceptions.notImplemented();
                case 503:
                  return const NetworkExceptions.serviceUnavailable();
                default:
                  return const NetworkExceptions.unexpectedError();
              }
            case DioExceptionType.badCertificate:
            case DioExceptionType.connectionError:
            case DioExceptionType.unknown:
              // Nothing ever answered: offline, DNS failure, connection
              // refused, a server that is simply not there, or a
              // certificate the client would not accept.
              return const NetworkExceptions.noInternetConnection();
            // No default: the switch is exhaustive over DioExceptionType on
            // purpose. A dio release that adds a type should fail this
            // build and be classified deliberately, rather than land
            // silently in whichever arm a catch-all happened to point at.
          }
        } else if (error is SocketException) {
          return const NetworkExceptions.noInternetConnection();
        }
        return const NetworkExceptions.unexpectedError();
      } on FormatException catch (_) {
        return const NetworkExceptions.formatException();
      } catch (_) {
        return const NetworkExceptions.unexpectedError();
      }
    } else {
      if (error.toString().contains("is not a subtype of")) {
        return const NetworkExceptions.unableToProcess();
      } else {
        return const NetworkExceptions.unexpectedError();
      }
    }
  }

  static int getDioStatus(error) {
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
            default:
              status = 500;
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

  static String getErrorMessage(NetworkExceptions networkExceptions) {
    var errorMessage = "";
    networkExceptions.when(
      notImplemented: () {
        errorMessage = "Not Implemented";
      },
      requestCancelled: () {
        errorMessage = "Request Cancelled";
      },
      internalServerError: () {
        errorMessage = "Internal Server Error";
      },
      notFound: (String reason) {
        errorMessage = reason;
      },
      serviceUnavailable: () {
        errorMessage = "Service unavailable";
      },
      methodNotAllowed: () {
        errorMessage = "Method Allowed";
      },
      badRequest: () {
        errorMessage = "Bad request";
      },
      unauthorisedRequest: () {
        errorMessage = "Unauthorised request";
      },
      unexpectedError: () {
        errorMessage = "Unexpected error occurred";
      },
      requestTimeout: () {
        errorMessage = "Connection request timeout";
      },
      noInternetConnection: () {
        errorMessage = "No internet connection";
      },
      conflict: () {
        errorMessage = "Error due to a conflict";
      },
      sendTimeout: () {
        errorMessage = "Send timeout in connection with API server";
      },
      unableToProcess: () {
        errorMessage = "Unable to process the data";
      },
      defaultError: (String error) {
        errorMessage = error;
      },
      formatException: () {
        errorMessage = "Unexpected error occurred";
      },
      notAcceptable: () {
        errorMessage = "Not acceptable";
      },
    );
    return errorMessage;
  }
}
