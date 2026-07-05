class ApiConfig {
  ApiConfig._();

  // Android emulator: 10.0.2.2 points to the development computer.
  // Replace it with the computer's local IP when using a physical device.
  static const String baseUrl = 'http://10.0.2.2:3000';
}
