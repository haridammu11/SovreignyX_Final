import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/company_service.dart';
import '../services/email_service.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final CompanyService _service = CompanyService();
  List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    final candidates = await _service.getRankedCandidates();
    if (mounted) {
      setState(() {
        _candidates = candidates;
        _isLoading = false;
      });
    }
  }

  void _showRecruitmentDialog(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    // ... (Keep existing dialog logic but maybe style it later if needed, mostly functional)
    // For now, keeping logic same to ensure functionality preservation
    final titleController = TextEditingController(text: 'Job Interview Invitation');
    final messageController = TextEditingController(text: 'We were impressed by your profile and coding streak. We would like to invite you for an interview.');
    final linkController = TextEditingController(text: 'https://zoom.us/j/123456789');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isSending = false;
          String? resultMessage;
          bool isSuccess = false;

          return AlertDialog(
            title: Text('Recruit ${user['first_name'] ?? 'Candidate'}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    enabled: !isSending,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    enabled: !isSending,
                    decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: linkController,
                    enabled: !isSending,
                    decoration: const InputDecoration(labelText: 'Zoom Link', border: OutlineInputBorder()),
                  ),
                  if (resultMessage != null) ...[
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSuccess ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5), width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded, 
                            color: isSuccess ? Colors.green : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              resultMessage!, 
                              style: GoogleFonts.inter(
                                color: isSuccess ? Colors.green[900] : Colors.red[900],
                                fontWeight: FontWeight.w600,
                              )
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!isSending)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant)),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSending ? null : () async {
                  setState(() {
                    isSending = true;
                    resultMessage = null;
                  });

                  try {
                    // 1. Process Event: Trigger Backend Notification
                    final successDb = await _service.sendJobOffer(
                      userId: user['id'],
                      title: titleController.text,
                      message: messageController.text,
                      zoomLink: linkController.text,
                    );
                    
                    bool successEmail = false;

                    // 2. Process Event: Trigger Secure Email
                    if (user['email'] != null && user['email'].toString().isNotEmpty) {
                      successEmail = await EmailService.sendJobOffer(
                          recipientEmail: user['email'],
                          candidateName: '${user['first_name']} ${user['last_name']}',
                          jobTitle: titleController.text,
                          messageBody: messageController.text,
                          zoomLink: linkController.text,
                        );
                    }

                    if (context.mounted) {
                      setState(() {
                        isSending = false;
                        isSuccess = successDb && successEmail;
                        
                        if (successDb) {
                          resultMessage = "Recruitment process started!";
                          if (!successEmail) {
                             resultMessage = "$resultMessage (Email service failed)";
                          } else {
                             resultMessage = "Professional offer email sent successfully!";
                          }
                          
                          if (isSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Job offer sent to ${user['first_name']}!'),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              if (context.mounted) Navigator.pop(context);
                            });
                          }
                        } else {
                          resultMessage = "Failed to update recruitment status.";
                        }
                      });
                    }
                  } catch (e) {
                     if (context.mounted) {
                        setState(() {
                           isSending = false;
                           resultMessage = "Error: ${e.toString()}";
                           isSuccess = false;
                        });
                     }
                  }
                },
                child: isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Send Professional Offer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _candidates[index];
                        final streak = user['streak'] ?? 0;
                        final rank = index + 1;
                        
                        return _buildCandidateCard(user, streak, rank, theme);
                      },
                      childCount: _candidates.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> user, int streak, int rank, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showAIAnalysisDialog(user),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? const Color(0xFFFFD700).withOpacity(0.2) : theme.colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                    border: rank <= 3 ? Border.all(color: const Color(0xFFFFD700)) : null,
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? const Color(0xFFD97706) : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: ClipOval(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: user['profile_picture_url'] != null
                          ? Image.network(
                              user['profile_picture_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    '${(user['first_name'] != null && user['first_name'].isNotEmpty) ? user['first_name'][0] : 'U'}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                '${(user['first_name'] != null && user['first_name'].isNotEmpty) ? user['first_name'][0] : 'U'}',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['first_name']} ${user['last_name']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user['username']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$streak Day Streak',
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.psychology_rounded),
                      tooltip: 'AI Analysis',
                      onPressed: () => _showAIAnalysisDialog(user),
                    ),
                    const SizedBox(height: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.person_add_rounded),
                      tooltip: 'Recruit',
                      onPressed: () => _showRecruitmentDialog(user),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAIAnalysisDialog(Map<String, dynamic> user) async {
    // Show loading first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // Simulate AI Analysis of Links
    final github = user['github_link'] ?? '';
    final linkedin = user['linkedin_link'] ?? '';
    final portfolio = user['portfolio_link'] ?? '';
    
    String analysis = await _service.analyzeCandidateProfile(
      name: "${user['first_name']} ${user['last_name']}",
      github: github,
      linkedin: linkedin,
      portfolio: portfolio,
    );

    if (mounted) {
      Navigator.pop(context); // Pop loading
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.purple),
              const SizedBox(width: 8),
              Text('AI Analysis', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Candidate: ${user['first_name']} ${user['last_name']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (github.isNotEmpty) ...[
                   _buildLinkRow(Icons.code, 'GitHub', github, Theme.of(context)),
                   const SizedBox(height: 4),
                ],
                if (linkedin.isNotEmpty) ...[
                   _buildLinkRow(Icons.business, 'LinkedIn', linkedin, Theme.of(context)),
                   const SizedBox(height: 4),
                ],
                if (portfolio.isNotEmpty) ...[
                   _buildLinkRow(Icons.language, 'Portfolio', portfolio, Theme.of(context)),
                   const SizedBox(height: 12),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Text('AI Summary:', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                  ),
                  child: Text(analysis, style: GoogleFonts.inter(height: 1.5)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () {
                 Navigator.pop(ctx);
                 _showRecruitmentDialog(user);
              },
              icon: const Icon(Icons.check),
              label: const Text('Recruit'),
            )
          ],
        ),
      );
    }
  }

  Widget _buildLinkRow(IconData icon, String label, String url, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            url, 
            style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline),
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          )
        ),
      ],
    );
  }
}
