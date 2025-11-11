class CustomException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  CustomException(this.message, {this.code, this.stackTrace});

  @override
  String toString() => 'CustomException(code: $code, message: $message)';
}
