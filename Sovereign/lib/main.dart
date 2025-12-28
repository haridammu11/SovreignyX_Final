import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/company_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rygssvwlqwnzkarmihvd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5Z3NzdndscXduemthcm1paHZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjAxNzIsImV4cCI6MjA4MDkzNjE3Mn0.XiXbLY8pldr_fMe0YLZ6Fq7syLyQP1LO-NWv2wfAeUA',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const CompanyApp(),
    ),
  );
}

class CompanyApp extends StatelessWidget {
  const CompanyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Sovereign',
          theme: CompanyTheme.lightTheme,
          darkTheme: CompanyTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}


