import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ProjectAssignmentService {
  final _supabase = Supabase.instance.client;

  /// Manually assign a specific project to a team
  Future<bool> assignProjectToTeam({
    required int teamId,
    required int projectId,
  }) async {
    print('═══════════════════════════════════════════════════');
    print('🔵 [ASSIGNMENT] Assigning Project to Team');
    print('═══════════════════════════════════════════════════');
    print('🏷️  Team ID: $teamId');
    print('🎯 Project ID: $projectId');

    try {
      // Verify project exists
      print('📥 Verifying project exists...');
      final project = await _supabase
          .from('course_projects')
          .select('id, title, course_id')
          .eq('id', projectId)
          .maybeSingle();

      if (project == null) {
        print('❌ Project not found!');
        return false;
      }

      print('✅ Project found: ${project['title']}');

      // Verify team exists
      print('📥 Verifying team exists...');
      final team = await _supabase
          .from('study_groups')
          .select('id, name, course_id')
          .eq('id', teamId)
          .maybeSingle();

      if (team == null) {
        print('❌ Team not found!');
        return false;
      }

      print('✅ Team found: ${team['name']}');

      // Check if course IDs match
      if (project['course_id'] != team['course_id']) {
        print('⚠️  Warning: Course ID mismatch!');
        print('   Project Course: ${project['course_id']}');
        print('   Team Course: ${team['course_id']}');
      }

      // Assign project to team
      print('🚀 Updating study_groups table...');
      await _supabase
          .from('study_groups')
          .update({'assigned_project_id': projectId})
          .eq('id', teamId);

      print('✅ Assignment successful!');
      print('═══════════════════════════════════════════════════');
      print('🎉 Project "${project['title']}" assigned to team "${team['name']}"');
      print('═══════════════════════════════════════════════════');

      return true;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════');
      print('❌ ERROR assigning project!');
      print('═══════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace.toString());
      print('═══════════════════════════════════════════════════');
      return false;
    }
  }

  /// Auto-assign projects to all teams in a course (AI-style random assignment)
  Future<Map<String, dynamic>> autoAssignProjectsToCourse(String courseId) async {
    print('═══════════════════════════════════════════════════');
    print('🤖 [AI ASSIGNMENT] Auto-assigning projects to teams');
    print('═══════════════════════════════════════════════════');
    print('📚 Course ID: $courseId');

    try {
      // Get all approved projects for this course
      print('📥 Fetching approved projects...');
      final projects = await _supabase
          .from('course_projects')
          .select('id, title')
          .eq('course_id', courseId)
          .eq('is_approved', true);

      print('✅ Found ${(projects as List).length} approved projects');

      if ((projects as List).isEmpty) {
        print('⚠️  No approved projects found for this course!');
        return {'success': false, 'message': 'No approved projects available'};
      }

      // Get all teams for this course that need projects
      print('📥 Fetching teams without projects...');
      final teams = await _supabase
          .from('study_groups')
          .select('id, name, assigned_project_id')
          .eq('course_id', courseId)
          .is_('assigned_project_id', null);

      print('✅ Found ${(teams as List).length} teams without projects');

      if ((teams as List).isEmpty) {
        print('ℹ️  All teams already have projects assigned');
        return {'success': true, 'message': 'All teams already assigned', 'assigned': 0};
      }

      // Randomly assign projects to teams
      final random = Random();
      int assignedCount = 0;

      for (final team in teams) {
        // Pick a random project
        final randomProject = projects[random.nextInt(projects.length)];

        print('🎲 Assigning "${randomProject['title']}" to team "${team['name']}"');

        await _supabase
            .from('study_groups')
            .update({'assigned_project_id': randomProject['id']})
            .eq('id', team['id']);

        assignedCount++;
      }

      print('═══════════════════════════════════════════════════');
      print('🎉 Auto-assignment complete!');
      print('   Teams assigned: $assignedCount');
      print('═══════════════════════════════════════════════════');

      return {
        'success': true,
        'assigned': assignedCount,
        'message': 'Successfully assigned projects to $assignedCount teams'
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════');
      print('❌ ERROR in auto-assignment!');
      print('═══════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace.toString());
      print('═══════════════════════════════════════════════════');

      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Get assignment statistics for a course
  Future<Map<String, dynamic>> getAssignmentStats(String courseId) async {
    try {
      // Total teams
      final allTeams = await _supabase
          .from('study_groups')
          .select('id')
          .eq('course_id', courseId);

      // Teams with projects
      final teamsWithProjects = await _supabase
          .from('study_groups')
          .select('id')
          .eq('course_id', courseId)
          .not('assigned_project_id', 'is', null);

      // Available projects
      final availableProjects = await _supabase
          .from('course_projects')
          .select('id')
          .eq('course_id', courseId)
          .eq('is_approved', true);

      return {
        'total_teams': (allTeams as List).length,
        'teams_with_projects': (teamsWithProjects as List).length,
        'teams_without_projects': (allTeams as List).length - (teamsWithProjects as List).length,
        'available_projects': (availableProjects as List).length,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {};
    }
  }

  /// Remove project assignment from a team
  Future<bool> unassignProject(int teamId) async {
    try {
      await _supabase
          .from('study_groups')
          .update({'assigned_project_id': null})
          .eq('id', teamId);

      print('✅ Project unassigned from team $teamId');
      return true;
    } catch (e) {
      print('❌ Error unassigning project: $e');
      return false;
    }
  }
}
