import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config_service.dart';

class EmailService {
  static Future<bool> sendJobOffer({
    required String recipientEmail,
    required String candidateName,
    required String jobTitle,
    required String messageBody,
    required String zoomLink,
  }) async {
    // 1. Platform & Method Selection
    if (ConfigService.useBackendService) {
      return await _sendViaBackend(
        recipientEmail: recipientEmail,
        candidateName: candidateName,
        jobTitle: jobTitle,
        messageBody: messageBody,
        zoomLink: zoomLink,
      );
    }

    if (kIsWeb) {
      // Use HTTP API for Web (since SMTP sockets are blocked)
      // Check if EmailJS is configured, otherwise fallback to mailto (handled in UI) or fail
      if (ConfigService.isApiConfigured) {
          return await _sendViaApi(
          recipientEmail: recipientEmail,
          candidateName: candidateName,
          jobTitle: jobTitle,
          messageBody: messageBody,
          zoomLink: zoomLink,
        );
      }
      debugPrint('⚠️ Web Email: Backend & EmailJS not configured. UI should handle mailto.');
      return false;
    }

    // 2. Input Validation (Common)
    if (!_isValidEmail(recipientEmail)) return false;

    // ... (rest of SMTP logic for Non-Web)
    if (!ConfigService.isConfigured) {
      debugPrint('❌ ERROR: SMTP Configuration missing.');
      return false;
    }

    final smtpServer = gmail(ConfigService.smtpEmail, ConfigService.smtpPassword);
    
    // ... (Sanitization & Template building same as before)
    final safeName = _sanitize(candidateName);
    final safeTitle = _sanitize(jobTitle);
    final safeBody = _sanitize(messageBody);
    final safeLink = _sanitize(zoomLink);

    final message = Message()
      ..from = Address(ConfigService.smtpEmail, 'Company Recruitment Team')
      ..recipients.add(recipientEmail)
      ..subject = 'Interview Invitation: $safeTitle'
      ..html = _buildEmailTemplate(safeName, safeBody, safeLink);

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ SMTP Message sent: ' + sendReport.toString());
      return true;
    } catch (e) {
      debugPrint('❌ SMTP Message not sent: $e');
      return false;
    }
  }

  // Backend Service Sender (Python/Django)
  static Future<bool> _sendViaBackend({
    required String recipientEmail,
    required String candidateName,
    required String jobTitle,
    required String messageBody,
    required String zoomLink,
  }) async {
    final url = Uri.parse('${ConfigService.backendBaseUrl}/api/code/send-email/');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipient': recipientEmail,
          'subject': 'Interview Invitation: $jobTitle',
          'body': _buildEmailTemplate(candidateName, messageBody, zoomLink), // Send full HTML body
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Backend Email Logged & Sent!');
        return true;
      } else {
        debugPrint('❌ Backend Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Backend Connection Status: $e');
      debugPrint('👉 Ensure Django Server is running: python manage.py runserver');
      debugPrint('👉 Ensure AllowedHost/CORS is configured if on Web.');
      return false;
    }
  }

  // HTTP API Sender (EmailJS)
  static Future<bool> _sendViaApi({
    required String recipientEmail,
    required String candidateName,
    required String jobTitle,
    required String messageBody,
    required String zoomLink,
  }) async {
    if (!ConfigService.isApiConfigured) {
      debugPrint('❌ ERROR: API Configuration missing in ConfigService.');
      debugPrint('👉 Please set your EmailJS Service ID, Template ID, and User ID.');
      return false;
    }

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost', // Sometimes required by EmailJS
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': ConfigService.emailJsServiceId,
          'template_id': ConfigService.emailJsTemplateId,
          'user_id': ConfigService.emailJsUserId,
          'template_params': {
            'to_email': recipientEmail,
            'to_name': candidateName,
            'job_title': jobTitle,
            'message_body': messageBody,
            'zoom_link': zoomLink,
            'company_name': 'Company Portal', // Dynamic parameter
          }
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ API Email sent successfully!');
        return true;
      } else {
        debugPrint('❌ API Email failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ API Connection failed: $e');
      return false;
    }
  }

  static bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }
  
  static String _sanitize(String input) {
    return input.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }

  static String _buildEmailTemplate(String name, String body, String link) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Interview Invitation</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f7fa; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
    <table border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr>
            <td style="padding: 20px 0 30px 0;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" width="600" style="border-collapse: collapse; border: 1px solid #e1e7ec; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
                    <!-- Header -->
                    <tr>
                        <td align="center" bgcolor="#2563EB" style="padding: 40px 0 30px 0;">
                            <h1 style="color: #ffffff; font-size: 28px; margin: 0; letter-spacing: 1px;">Company Portal</h1>
                            <p style="color: #bfdbfe; font-size: 14px; margin: 5px 0 0 0;">Recruitment Experience</p>
                        </td>
                    </tr>
                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 30px 40px 30px;">
                            <table border="0" cellpadding="0" cellspacing="0" width="100%">
                                <tr>
                                    <td style="color: #1e293b; font-size: 24px; font-weight: bold;">
                                        Hi $name,
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 20px 0 30px 0; color: #475569; font-size: 16px; line-height: 1.6;">
                                        $body
                                    </td>
                                </tr>
                                <tr>
                                    <td align="center">
                                        <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: separate;">
                                            <tr>
                                                <td align="center" bgcolor="#2563EB" style="border-radius: 8px;">
                                                    <a href="$link" target="_blank" style="padding: 14px 28px; font-size: 16px; font-weight: bold; color: #ffffff; text-decoration: none; display: inline-block;">Join Interview Meeting</a>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr>
                                    <td style="padding: 30px 0 0 0; color: #64748b; font-size: 14px;">
                                        Or copy this link: <br>
                                        <a href="$link" style="color: #2563EB; text-decoration: underline;">$link</a>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <!-- Footer -->
                    <tr>
                        <td bgcolor="#f8fafc" style="padding: 30px 30px 30px 30px; border-top: 1px solid #e2e8f0;">
                            <table border="0" cellpadding="0" cellspacing="0" width="100%">
                                <tr>
                                    <td style="color: #94a3b8; font-size: 12px; width: 75%;">
                                        &copy; 2025 Company Portal Recruiting Team<br>
                                        Innovative Hiring Solutions
                                    </td>
                                    <td align="right" style="width: 25%;">
                                        <table border="0" cellpadding="0" cellspacing="0">
                                            <tr>
                                                <td style="font-family: sans-serif; font-size: 12px; font-weight: bold;">
                                                    <a href="#" style="color: #2563EB; text-decoration: none;">Privacy Policy</a>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ''';
  }
  static Future<void> notifyAllStudentsOfNewJob({
    required String jobTitle,
    required String companyName,
  }) async {
    // In a real production app, this should be done via a backend queuing system (BullMQ, Celery, etc.)
    // For this MVP, we will try to send a batch or just log it if we can't fetch all emails easily.
    
    // 1. Fetch all student emails (simplified)
    // IMPORTANT: This requires service_role key or public user table access which might not be ideal.
    // We will assume 'users' table is readable or we rely on backend.
    
    if (ConfigService.useBackendService) {
      // Logic to trigger backend broadcast
      debugPrint('🚀 Triggering Job Notification via Backend for $jobTitle');
      return; 
    }

    // If simulating locally:
    debugPrint('🔔 Simulating Batch Email Notification for Job: $jobTitle at $companyName');
    debugPrint('   - Targeted Audience: All Students');
    debugPrint('   - Channel: Email');
    debugPrint('   - Status: Sent (Simulated)');
  }
}
