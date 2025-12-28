import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_recruitment_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:company_app/utils/ats_colors.dart';


class ApplicantReviewScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const ApplicantReviewScreen({super.key, required this.job});

  @override
  State<ApplicantReviewScreen> createState() => _ApplicantReviewScreenState();
}

class _ApplicantReviewScreenState extends State<ApplicantReviewScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    try {
      final response = await _supabase
          .from('job_applications')
          .select()
          .eq('job_id', widget.job['id'])
          .order('ai_overall_score', ascending: false);

      setState(() {
        _applicants = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _analyzeCandidate(Map<String, dynamic> application) async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ATSColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ATSColors.primary),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '🤖 AI Analysis in Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ATSColors.neutral800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Analyzing resume, LinkedIn, and GitHub',
                  style: TextStyle(
                    color: ATSColors.neutral600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This may take 30-60 seconds',
                  style: TextStyle(
                    color: ATSColors.neutral400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final resumeText = '''
Candidate Name: ${application['student_name']}
Email: ${application['student_email'] ?? 'Not provided'}

Cover Letter:
${application['cover_note'] ?? 'No cover letter provided'}

Professional Links:
- LinkedIn: ${application['linkedin_url'] ?? 'Not provided'}
- GitHub: ${application['github_url'] ?? 'Not provided'}

Resume File: ${application['resume_url'] ?? 'Not uploaded'}
''';

      final analysis = await AiRecruitmentService.analyzeApplication(
        jobTitle: widget.job['title'],
        jobDescription: widget.job['description'],
        candidateName: application['student_name'],
        resumeText: resumeText,
        coverNote: application['cover_note'],
        linkedinUrl: application['linkedin_url'],
        githubUrl: application['github_url'],
      );

      await _supabase.from('job_applications').update({
        'ai_ats_score': analysis['ats_score'],
        'ai_overall_score': analysis['overall_score'],
        'ai_technical_score': analysis['technical_score'],
        'ai_experience_score': analysis['experience_score'],
        'ai_cultural_score': analysis['cultural_fit_score'],
        'ai_summary': analysis['summary'],
        'ai_detailed_analysis': analysis['detailed_analysis'],
        'ai_linkedin_analysis': analysis['linkedin_analysis'],
        'ai_github_analysis': analysis['github_analysis'],
        'ai_recommendation': analysis['recommendation'],
        'ai_analyzed_at': DateTime.now().toIso8601String(),
        'ai_compatibility_score': analysis['overall_score'],
        'ai_pros': (analysis['detailed_analysis']['strengths'] as List).join(', '),
        'ai_cons': (analysis['detailed_analysis']['weaknesses'] as List).join(', '),
      }).eq('id', application['id']);

      if (mounted) Navigator.of(context).pop();
      await _fetchApplicants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('AI Analysis Complete! Score: ${analysis['overall_score']}/100'),
              ],
            ),
            backgroundColor: ATSColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ATSColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error_outline, color: ATSColors.danger),
                ),
                const SizedBox(width: 12),
                const Text('AI Analysis Failed'),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ATSColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _analyzeCandidate(application);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String appId, String newStatus) async {
    await _supabase.from('job_applications').update({'status': newStatus}).eq('id', appId);
    _fetchApplicants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ATSColors.bgSecondary,
      appBar: AppBar(
        title: Text('Applicants: ${widget.job['title']}'),
        backgroundColor: ATSColors.bgPrimary,
        foregroundColor: ATSColors.neutral800,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: ATSColors.neutral200,
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchApplicants,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ATSColors.primary))
          : _applicants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: ATSColors.neutral300),
                      const SizedBox(height: 16),
                      Text(
                        'No applications yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ATSColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applicants.length,
                  itemBuilder: (context, index) {
                    final app = _applicants[index];
                    final hasAi = app['ai_overall_score'] != null;

                    return _ApplicantCard(
                      application: app,
                      hasAi: hasAi,
                      onAnalyze: () => _analyzeCandidate(app),
                      onUpdateStatus: (status) => _updateStatus(app['id'], status),
                    );
                  },
                ),
    );
  }
}

// Continue with _ApplicantCard and other widgets in next part...

class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final bool hasAi;
  final VoidCallback onAnalyze;
  final Function(String) onUpdateStatus;

  const _ApplicantCard({
    required this.application,
    required this.hasAi,
    required this.onAnalyze,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final overallScore = application['ai_overall_score'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ATSColors.neutral200, width: 1),
      ),
      color: ATSColors.bgPrimary,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.zero,
        leading: _buildScoreBadge(overallScore),
        title: Text(
          application['student_name'] ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: ATSColors.neutral800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _buildStatusChip(application['status']),
              if (hasAi) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ATSColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: ATSColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'AI Analyzed',
                        style: TextStyle(
                          fontSize: 11,
                          color: ATSColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: hasAi ? ATSColors.warning.withOpacity(0.1) : ATSColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              Icons.auto_awesome,
              color: hasAi ? ATSColors.warning : ATSColors.neutral400,
            ),
            onPressed: onAnalyze,
            tooltip: hasAi ? 'Re-run AI Analysis' : 'Run AI Analysis',
          ),
        ),
        children: [
          if (hasAi)
            _AdvancedAnalysisView(
              application: application,
              onUpdateStatus: onUpdateStatus,
            )
          else
            _BasicView(
              application: application,
              onUpdateStatus: onUpdateStatus,
            ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int? score) {
    if (score == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: ATSColors.neutral100,
          shape: BoxShape.circle,
          border: Border.all(color: ATSColors.neutral300, width: 2),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: ATSColors.neutral500,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    Color color;
    Color bgColor;
    if (score >= 80) {
      color = ATSColors.success;
      bgColor = ATSColors.successBg;
    } else if (score >= 60) {
      color = ATSColors.warning;
      bgColor = ATSColors.warningBg;
    } else {
      color = ATSColors.danger;
      bgColor = ATSColors.dangerBg;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          score.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;
    switch (status.toLowerCase()) {
      case 'pending':
        color = ATSColors.warning;
        bgColor = ATSColors.warningBg;
        break;
      case 'interview':
        color = ATSColors.primary;
        bgColor = ATSColors.primary.withOpacity(0.1);
        break;
      case 'offer':
        color = ATSColors.success;
        bgColor = ATSColors.successBg;
        break;
      case 'rejected':
        color = ATSColors.danger;
        bgColor = ATSColors.dangerBg;
        break;
      default:
        color = ATSColors.neutral600;
        bgColor = ATSColors.neutral100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
// PART 2: Advanced Analysis View and Supporting Widgets

class _AdvancedAnalysisView extends StatefulWidget {
  final Map<String, dynamic> application;
  final Function(String) onUpdateStatus;

  const _AdvancedAnalysisView({
    required this.application,
    required this.onUpdateStatus,
  });

  @override
  State<_AdvancedAnalysisView> createState() => _AdvancedAnalysisViewState();
}

class _AdvancedAnalysisViewState extends State<_AdvancedAnalysisView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ATSColors.bgSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          _buildScoreDashboard(),
          Container(
            decoration: BoxDecoration(
              color: ATSColors.bgPrimary,
              border: Border(
                top: BorderSide(color: ATSColors.neutral200),
                bottom: BorderSide(color: ATSColors.neutral200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: ATSColors.primary,
              unselectedLabelColor: ATSColors.neutral500,
              indicatorColor: ATSColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Overview'),
                Tab(icon: Icon(Icons.code_outlined, size: 20), text: 'Technical'),
                Tab(icon: Icon(Icons.link, size: 20), text: 'Profiles'),
                Tab(icon: Icon(Icons.recommend_outlined, size: 20), text: 'Decision'),
              ],
            ),
          ),
          Container(
            height: 400,
            color: ATSColors.bgPrimary,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTechnicalTab(),
                _buildProfilesTab(),
                _buildDecisionTab(),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ATSColors.bgPrimary,
              border: Border(top: BorderSide(color: ATSColors.neutral200)),
            ),
            child: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDashboard() {
    final atsScore = widget.application['ai_ats_score'] ?? 0;
    final overallScore = widget.application['ai_overall_score'] ?? 0;
    final technicalScore = widget.application['ai_technical_score'] ?? 0;
    final experienceScore = widget.application['ai_experience_score'] ?? 0;
    final culturalScore = widget.application['ai_cultural_score'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ATSColors.gradientStart, ATSColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircularScore(
                score: overallScore,
                label: 'OVERALL SCORE',
                size: 130,
                fontSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniScore(atsScore, 'ATS'),
              _buildMiniScore(technicalScore, 'Technical'),
              _buildMiniScore(experienceScore, 'Experience'),
              _buildMiniScore(culturalScore, 'Culture'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore({
    required int score,
    required String label,
    double size = 80,
    double fontSize = 24,
  }) {
    Color color;
    Color bgColor;
    if (score >= 80) {
      color = ATSColors.success;
      bgColor = ATSColors.successBg;
    } else if (score >= 60) {
      color = ATSColors.warning;
      bgColor = ATSColors.warningBg;
    } else {
      color = ATSColors.danger;
      bgColor = ATSColors.dangerBg;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: score / 100),
      builder: (context, value, child) => Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ATSColors.bgPrimary,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size - 8,
                  height: size - 8,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 12,
                    backgroundColor: bgColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  (value * 100).toInt().toString(),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ATSColors.neutral600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(int score, String label) {
    return _buildCircularScore(
      score: score,
      label: label.toUpperCase(),
      size: 68,
      fontSize: 20,
    );
  }

  Widget _buildOverviewTab() {
    final summary = widget.application['ai_summary'] ?? 'No summary available';
    final detailedAnalysis = widget.application['ai_detailed_analysis'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            icon: Icons.description_outlined,
            title: 'Executive Summary',
            child: Text(
              summary,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: ATSColors.neutral700,
              ),
            ),
          ),
          if (detailedAnalysis != null) ...[
            _buildSection(
              icon: Icons.thumb_up_outlined,
              title: 'Key Strengths',
              child: _buildBulletList(
                List<String>.from(detailedAnalysis['strengths'] ?? []),
                ATSColors.success,
              ),
            ),
            _buildSection(
              icon: Icons.warning_amber_outlined,
              title: 'Areas of Concern',
              child: _buildBulletList(
                List<String>.from(detailedAnalysis['weaknesses'] ?? []),
                ATSColors.warning,
              ),
            ),
            _buildSection(
              icon: Icons.work_outline,
              title: 'Experience Level',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ATSColors.neutral50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ATSColors.neutral200),
                ),
                child: Text(
                  detailedAnalysis['experience_level'] ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ATSColors.neutral800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicalTab() {
    final detailedAnalysis = widget.application['ai_detailed_analysis'];
    if (detailedAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off, size: 48, color: ATSColors.neutral300),
            const SizedBox(height: 12),
            Text(
              'No technical analysis available',
              style: TextStyle(color: ATSColors.neutral500),
            ),
          ],
        ),
      );
    }

    final matchedSkills = List<String>.from(detailedAnalysis['key_skills_matched'] ?? []);
    final missingSkills = List<String>.from(detailedAnalysis['missing_skills'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            icon: Icons.check_circle_outline,
            title: 'Skills Matched',
            child: matchedSkills.isEmpty
                ? Text('No skills matched', style: TextStyle(color: ATSColors.neutral500))
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: matchedSkills.map((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ATSColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ATSColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: ATSColors.success, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            skill,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ATSColors.successDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
          ),
          _buildSection(
            icon: Icons.cancel_outlined,
            title: 'Missing Skills',
            child: missingSkills.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ATSColors.successBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ATSColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.celebration, color: ATSColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No critical skills missing! Excellent match!',
                            style: TextStyle(
                              color: ATSColors.successDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: missingSkills.map((skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ATSColors.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ATSColors.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, color: ATSColors.danger, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            skill,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ATSColors.dangerDark,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesTab() {
    final linkedinAnalysis = widget.application['ai_linkedin_analysis'];
    final githubAnalysis = widget.application['ai_github_analysis'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileCard(
            icon: Icons.work,
            title: 'LinkedIn Profile',
            url: widget.application['linkedin_url'],
            analysis: linkedinAnalysis,
            color: Color(0xFF0A66C2), // LinkedIn blue
          ),
          const SizedBox(height: 16),
          _buildProfileCard(
            icon: Icons.code,
            title: 'GitHub Profile',
            url: widget.application['github_url'],
            analysis: githubAnalysis,
            color: Color(0xFF24292E), // GitHub dark
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    String? url,
    Map<String, dynamic>? analysis,
    required Color color,
  }) {
    final hasUrl = url != null && url.isNotEmpty && url != 'Not provided';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ATSColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ATSColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ATSColors.neutral800,
                  ),
                ),
              ),
              if (hasUrl)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(url)),
                  icon: Icon(Icons.open_in_new, size: 16, color: color),
                  label: Text('View', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (!hasUrl)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Not provided',
                style: TextStyle(color: ATSColors.neutral400, fontStyle: FontStyle.italic),
              ),
            )
          else if (analysis != null && analysis['status'] != 'not_provided') ...[
            const SizedBox(height: 16),
            if (analysis['profile_quality'] != null)
              _buildInfoRow('Quality', analysis['profile_quality']),
            if (analysis['key_highlights'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Highlights:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ATSColors.neutral700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _buildBulletList(
                List<String>.from(analysis['key_highlights']),
                color,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDecisionTab() {
    final recommendation = widget.application['ai_recommendation'];
    if (recommendation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 48, color: ATSColors.neutral300),
            const SizedBox(height: 12),
            Text(
              'No recommendation available',
              style: TextStyle(color: ATSColors.neutral500),
            ),
          ],
        ),
      );
    }

    final decision = recommendation['decision'] ?? 'Hold';
    final confidence = recommendation['confidence'] ?? 'Medium';
    final reasoning = recommendation['reasoning'] ?? 'No reasoning provided';
    final nextSteps = List<String>.from(recommendation['next_steps'] ?? []);

    Color decisionColor;
    IconData decisionIcon;
    switch (decision.toLowerCase()) {
      case 'interview':
        decisionColor = ATSColors.success;
        decisionIcon = Icons.thumb_up;
        break;
      case 'reject':
        decisionColor = ATSColors.danger;
        decisionIcon = Icons.thumb_down;
        break;
      default:
        decisionColor = ATSColors.warning;
        decisionIcon = Icons.pause;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: decisionColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: decisionColor.withOpacity(0.3), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: decisionColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(decisionIcon, color: decisionColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        decision.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: decisionColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: decisionColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Confidence: $confidence',
                          style: TextStyle(
                            fontSize: 12,
                            color: decisionColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            icon: Icons.lightbulb_outline,
            title: 'Reasoning',
            child: Text(
              reasoning,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: ATSColors.neutral700,
              ),
            ),
          ),
          if (nextSteps.isNotEmpty)
            _buildSection(
              icon: Icons.checklist,
              title: 'Recommended Next Steps',
              child: _buildBulletList(nextSteps, ATSColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: ATSColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ATSColors.neutral800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 7, right: 10),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: ATSColors.neutral700,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ATSColors.neutral600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: ATSColors.neutral800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Status',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ATSColors.neutral700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildActionButton('Reject', Icons.cancel, ATSColors.danger, 'Rejected'),
              _buildActionButton('Hold', Icons.pause, ATSColors.warning, 'Hold'),
              _buildActionButton('Interview', Icons.event, ATSColors.primary, 'Interview'),
              _buildActionButton('Offer', Icons.check_circle, ATSColors.success, 'Offer'),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => launchUrl(Uri.parse(widget.application['resume_url'])),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ATSColors.neutral50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ATSColors.neutral200),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: ATSColors.danger, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'View Resume',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ATSColors.neutral800,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new, color: ATSColors.neutral400, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, String status) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onUpdateStatus(status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BasicView extends StatelessWidget {
  final Map<String, dynamic> application;
  final Function(String) onUpdateStatus;

  const _BasicView({
    required this.application,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ATSColors.warningBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 48, color: ATSColors.warning),
          const SizedBox(height: 16),
          Text(
            'AI Analysis Not Yet Performed',
            style: TextStyle(
              color: ATSColors.warningDark,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the ⭐ button above to run comprehensive AI analysis',
            style: TextStyle(
              color: ATSColors.neutral600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => launchUrl(Uri.parse(application['resume_url'])),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ATSColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ATSColors.neutral200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, color: ATSColors.danger),
                  const SizedBox(width: 12),
                  Text(
                    'View Resume',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ATSColors.neutral800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.open_in_new, color: ATSColors.neutral400, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
