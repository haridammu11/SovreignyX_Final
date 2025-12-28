import 'package:flutter/foundation.dart';

class ConfigService {
  // In a real production app, use 'flutter_dotenv' to load these from a .env file.
  // For this environment, we use a centralized config class.
  
  // SMTP Credentials (Windows/Mobile)
  static String get smtpEmail => 'chidwilash123@gmail.com'; 
  static String get smtpPassword => 'yawxqdvuksvynzxq'; 
  
  // API Credentials (Web - EmailJS Example)
  // Register at https://www.emailjs.com/ to get these keys entirely for free.
  static String get emailJsServiceId => 'service_wo6wmyd';
  static String get emailJsTemplateId => 'YOUR_TEMPLATE_ID';
  static String get emailJsUserId => 'YOUR_PUBLIC_KEY'; // "Public Key" in Account Settings

  static bool get isConfigured => smtpEmail.isNotEmpty && smtpPassword.isNotEmpty;
  
  static bool get isApiConfigured => emailJsServiceId != 'YOUR_SERVICE_ID' && emailJsServiceId.isNotEmpty;
  
  // Backend Service Config (Python Django)
  // For Android Emulator (Standard): 'http://10.0.2.2:8000'
  // For iOS Simulator: 'http://localhost:8000'
  // For Web: 'http://localhost:8000' (or your production URL)
  
  static String get backendBaseUrl {
    if (kIsWeb) return 'https://4965r9l0-8000.inc1.devtunnels.ms';
    // Check for Android (Platform check requires dart:io not available on web, so guarded by kIsWeb)
    // Actually, we can just use 10.0.2.2 as default for mobile development or logic below
    return 'http://127.0.0.1:8000'; 
  }
  
  static bool get useBackendService => true; // Set to true to use the Python Backend for emails
}
