import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/company_service.dart';

class ContestsScreen extends StatefulWidget {
  const ContestsScreen({super.key});

  @override
  State<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends State<ContestsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _difficulty = 'Beginner';
  int _duration = 60;
  int _points = 100;
  final CompanyService _service = CompanyService();
  bool _isSubmitting = false;
  
  late TabController _tabController;
  List<Map<String, dynamic>> _activeContests = [];
  bool _isLoadingContests = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchContests();
  }

  Future<void> _fetchContests() async {
    setState(() => _isLoadingContests = true);
    final contests = await _service.getContests();
    if (mounted) {
      setState(() {
        _activeContests = contests;
        _isLoadingContests = false;
      });
    }
  }

  Future<void> _createContest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    final success = await _service.createContest(
      title: _titleController.text,
      description: _descController.text,
      difficulty: _difficulty,
      durationMinutes: _duration,
      points: _points,
    );
    
    setState(() => _isSubmitting = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Contest Created Successfully!' : 'Failed to create contest'),
          backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (success) {
        _titleController.clear();
        _descController.clear();
        _fetchContests();
        _tabController.animateTo(1);
      }
    }
  }

  void _showLeaderboard(Map<String, dynamic> contest) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaderboardSheet(contest: contest, service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Launch New'),
              Tab(text: 'Manage Active'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateTab(theme),
          _buildManageTab(theme),
        ],
      ),
    );
  }

  Widget _buildCreateTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Contest',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildCreateForm(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Contest Title', prefixIcon: Icon(Icons.title)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: ['Beginner', 'Intermediate', 'Advanced', 'Production-Level']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis, maxLines: 1)))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: '60',
                    decoration: const InputDecoration(labelText: 'Duration (Min)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _duration = int.tryParse(v) ?? 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _createContest,
                icon: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.rocket_launch),
                label: Text(_isSubmitting ? 'Launching...' : 'Launch Contest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTab(ThemeData theme) {
    if (_isLoadingContests) return const Center(child: CircularProgressIndicator());
    if (_activeContests.isEmpty) return const Center(child: Text('No active contests found.'));

    return RefreshIndicator(
      onRefresh: _fetchContests,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _activeContests.length,
        itemBuilder: (context, index) {
          final contest = _activeContests[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events, color: theme.colorScheme.primary),
              ),
              title: Text(contest['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${contest['difficulty']} • ${contest['duration_minutes']} mins'),
              trailing: ElevatedButton.icon(
                onPressed: () => _showLeaderboard(contest),
                icon: const Icon(Icons.leaderboard_rounded, size: 18),
                label: const Text('Leaderboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardSheet extends StatelessWidget {
  final Map<String, dynamic> contest;
  final CompanyService service;

  const _LeaderboardSheet({required this.contest, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LEADERBOARD', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        Text(contest['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: service.getContestLeaderboard(contest['id'].toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No participants yet.'));

                  final leaderboard = snapshot.data!;
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: leaderboard.length,
                    itemBuilder: (context, index) {
                      final item = leaderboard[index];
                      final user = item['users'] as Map<String, dynamic>;
                      final isTop3 = index < 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isTop3 ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isTop3 ? theme.colorScheme.primary.withOpacity(0.3) : theme.dividerColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Text('#${index + 1}', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null ? Text(user['full_name'][0]) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                              child: Text('${item['score']} pts', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
