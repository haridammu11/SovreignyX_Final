import 'package:flutter/material.dart';
import 'package:lms_app/screens/code_editor_screen.dart';
import 'package:lms_app/screens/course_search_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/scion_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/collaboration_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/privacy_settings_screen.dart';
import 'screens/progress_tracking_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/realtime_chat_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/role_management_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/social_feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/certificates_screen.dart'; // Add this import
import 'screens/course_detail_screen.dart'; // Add this import
import 'screens/ai_chat_screen.dart'; 
import 'screens/ide_screen.dart';
import 'screens/contest_list_screen.dart';
import 'screens/web_page_generator_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/ai_course_generator_screen.dart';
import 'screens/interests_selection_screen.dart';
import 'screens/job_board_screen.dart';
import 'screens/my_applications_screen.dart';
import 'models/project_model.dart';
import 'services/project_generator_service.dart';
import 'services/groq_service.dart';
import 'utils/constants.dart';
import 'services/auth_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await AuthService.initialize();

  runApp(const LMSApp());
}

class LMSApp extends StatelessWidget {
  const LMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scion',
      theme: ScionTheme.darkTheme,
      darkTheme: ScionTheme.darkTheme,
      themeMode: ThemeMode.dark, // Enforce Dark Mode for "Prime" look
      initialRoute: '/auth',
      onGenerateRoute: (settings) {
        // Extract arguments if provided
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/auth':
            return MaterialPageRoute(builder: (context) => const AuthScreen());
          case '/dashboard':
            // Pass the AuthService instance from AuthScreen if available
            final authService = args?['authService'] as AuthService?;
            return MaterialPageRoute(
              builder:
                  (context) => DashboardScreen(
                    authService: authService ?? AuthService(),
                  ),
            );
          case '/courses':
            return MaterialPageRoute(
              builder: (context) => const CoursesScreen(),
            );

          case '/course-detail':
            final args = settings.arguments as Map<String, dynamic>?;
            final courseId = args?['courseId'] as int?;
            final courseTitle = args?['courseTitle'] as String?;
            
            if (courseId == null) {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(child: Text('Course ID is required')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => CourseDetailScreen(
                courseId: courseId, 
                courseTitle: courseTitle ?? 'Course Detail'
              ),
            );
          case '/course-search':
            return MaterialPageRoute(
              builder: (context) => const CourseSearchScreen(),
            );
          case '/achievements':
            final userId = args?['userId']?.toString() ?? '';
            return MaterialPageRoute(
              builder:
                  (context) =>
                      AchievementsScreen(userId: userId, token: args?['token']),
            );
          case '/admin-dashboard':
            final userId = args?['userId']?.toString() ?? '';
            return MaterialPageRoute(
              builder:
                  (context) => AdminDashboardScreen(
                    userId: int.tryParse(userId) ?? 1,
                    token: args?['token'],
                    authService:
                        args?['authService']
                            as AuthService?, // Pass AuthService
                  ),
            );
          case '/analytics':
            return MaterialPageRoute(
              builder: (context) => const AnalyticsDashboardScreen(),
            );
          case '/chat':
            final userId = args?['userId']?.toString() ?? '';
            return MaterialPageRoute(
              builder:
                  (context) =>
                      ChatScreen(userId: int.tryParse(userId) ?? 1, token: args?['token']), // ChatScreen might need int?
            );
          case '/collaboration':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            final projectId =
                args?['projectId'] is String
                    ? int.tryParse(args?['projectId']) ?? 1
                    : args?['projectId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) => CollaborationScreen(
                    userId: userId,
                    userName: args?['userName'] ?? 'User $userId',
                    token: args?['token'],
                    projectId: projectId,
                    projectName: args?['projectName'] ?? 'Project',
                  ),
            );
          case '/leaderboard':
            final userId = args?['userId']?.toString() ?? '';
            return MaterialPageRoute(
              builder:
                  (context) =>
                      LeaderboardScreen(userId: userId, token: args?['token']),
            );
          case '/aichat':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) =>
                      AIChatScreen(userId: userId, apiKey: args?['apiKey']),
            );
          case '/payment':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) =>
                      PaymentScreen(userId: userId, token: args?['token']),
            );
          case '/privacy-settings':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) => PrivacySettingsScreen(
                    userId: userId,
                    token: args?['token'],
                  ),
            );
          case '/progress-tracking':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) => ProgressTrackingScreen(
                    userId: userId,
                    token: args?['token'],
                  ),
            );

          case '/code-editor':
            final userId = args?['userId'] ?? 'user-id';
            return MaterialPageRoute(
              builder: (context) => CodeEditorScreen(
                userId: userId,
              ),
            );

          case '/ide':
            final project = args?['project'] as Project?;
            final isChallenge = args?['isChallengeMode'] as bool? ?? false;
             if (project == null) {
              return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('No Project Provided'))));
            }
            final groqService = GroqService(apiKey: AppConstants.groqApiKey);
            return MaterialPageRoute(
              builder: (context) => IDEScreen(
                project: project,
                projectService: ProjectGeneratorService(groqService),
                isChallengeMode: isChallenge,
              ),
            );

          case '/realtime-chat':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            final chatRoomId =
                args?['chatRoomId'] is String
                    ? int.tryParse(args?['chatRoomId']) ?? 1
                    : args?['chatRoomId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) => RealtimeChatScreen(
                    userId: userId,
                    token: args?['token'],
                    chatRoomId: chatRoomId,
                  ),
            );
          case '/reports':
            return MaterialPageRoute(
              builder:
                  (context) => ReportsScreen(
                    reportType: args?['reportType'] ?? 'engagement',
                    token: args?['token'],
                  ),
            );
          case '/role-management':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) => RoleManagementScreen(
                    userId: userId,
                    token: args?['token'],
                  ),
            );
          case '/security-settings':
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder:
                  (context) => SecuritySettingsScreen(
                    userId: userId,
                    token: args?['token'],
                  ),
            );
          case '/social-feed':
            final userId = args?['userId']?.toString() ?? '';
            return MaterialPageRoute(
              builder:
                  (context) =>
                      SocialFeedScreen(userId: userId, token: args?['token']),
            );
          case '/profile': // Add profile route
            final authService = args?['authService'] as AuthService?;
            return MaterialPageRoute(
              builder:
                  (context) =>
                      ProfileScreen(authService: authService ?? AuthService()),
            );
          case '/create-post': // Add create post route
            final userId = args?['userId']?.toString() ?? '';
            return MaterialPageRoute(
              builder:
                  (context) =>
                      CreatePostScreen(userId: userId, token: args?['token']),
            );
          case '/certificates': // Add certificates route
            final userId =
                args?['userId'] is String
                    ? int.tryParse(args?['userId']) ?? 1
                    : args?['userId'] as int? ?? 1;
            return MaterialPageRoute(
              builder: (context) =>
                  CertificatesScreen(userId: userId, token: args?['token']),
            );
          case '/contests':
            return MaterialPageRoute(
              builder: (context) => const ContestListScreen(),
            );
          case '/web-generator':
            return MaterialPageRoute(
              builder: (context) => const WebPageGeneratorScreen(),
            );

          case '/reels':
            return MaterialPageRoute(
              builder: (context) => const ReelsScreen(),
            );
          case '/ai-course-generator':
            return MaterialPageRoute(
              builder: (context) => const AICourseGeneratorScreen(),
            );
          case '/interests-selection':
            return MaterialPageRoute(
              builder: (context) => const InterestsSelectionScreen(isFirstTime: true),
            );
          case '/job-board':
            return MaterialPageRoute(
              builder: (context) => const JobBoardScreen(),
            );
          case '/my-applications':
            return MaterialPageRoute(
              builder: (context) => const MyApplicationsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder:
                  (context) => const Scaffold(
                    body: Center(child: Text('Page not found')),
                  ),
            );
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
