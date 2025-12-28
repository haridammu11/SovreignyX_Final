import 'package:flutter/foundation.dart';

class ConfigService {
  static String get backendBaseUrl {
    if (kIsWeb) return 'https://4965r9l0-8000.inc1.devtunnels.ms';
    // 10.0.2.2 is the standard alias to host loopback interface for Android Emulator
    return 'https://4965r9l0-8000.inc1.devtunnels.ms';
  }
}
