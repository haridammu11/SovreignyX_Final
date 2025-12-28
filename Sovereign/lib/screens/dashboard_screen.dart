import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/theme_provider.dart';
import '../utils/ats_colors.dart';
import 'candidates_screen.dart';
import 'contests_screen.dart';
import 'proctor_screen.dart';
import 'manage_courses_screen.dart';
import 'job_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const CandidatesScreen(),
    const JobDashboardScreen(),
    const ContestsScreen(),
    const ProctorScreen(),
    const ManageCoursesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureCompanyProfileExists();
  }

  Future<void> _ensureCompanyProfileExists() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) return;

    try {
      final company = await supabase
          .from('companies')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (company == null) {
        await supabase.from('companies').insert({
          'id': user.id,
          'name': user.email?.split('@')[0] ?? 'Company',
          'email': user.email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error ensuring company profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.business_rounded,
                color: cs.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sovereign',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
                bottom: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.2), width: 1)),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () =>
                themeProvider.toggleTheme(!themeProvider.isDarkMode),
            tooltip: 'Toggle theme',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: cs.surfaceContainerHighest,
            onSelected: (value) async {
              if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: cs.error, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                          color: cs.error, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: cs.surface,
        indicatorColor: cs.secondary.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: cs.primary),
            label: 'Candidates',
          ),
          NavigationDestination(
            icon: const Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded, color: cs.primary),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded, color: cs.primary),
            label: 'Contests',
          ),
          NavigationDestination(
            icon: const Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security_rounded, color: cs.primary),
            label: 'Proctor',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: cs.primary),
            label: 'Courses',
          ),
        ],
      ),
    );
  }
}
