import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://emkc.org/api/v2/piston/execute');
  print('Testing URL: $url');
  
  final payload = {
    "language": "typescript",
    "version": "*", 
    "files": [
      {
        "content": "console.log('hello from typescript')"
      }
    ]
  };
  
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 404) {
        print('Trying runtimes endpoint...');
        final runtimesUrl = Uri.parse('https://emkc.org/api/v2/piston/runtimes');
        final runtimesResponse = await http.get(runtimesUrl);
        print('Runtimes Status: ${runtimesResponse.statusCode}');
        // print('Runtimes Body: ${runtimesResponse.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
