import 'package:flutter/material.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String? token;

  const AnalyticsDashboardScreen({super.key, this.token});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _metricsAnimationController;
  late AnimationController _chartsAnimationController;

  @override
  void initState() {
    super.initState();
    _metricsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _metricsAnimationController.dispose();
    _chartsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isLoading = false;
      });
      _metricsAnimationController.forward();
      _chartsAnimationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.cyan.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Analytics Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.blue.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              // Export data
            },
            tooltip: 'Export Data',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.03),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAnalyticsData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadAnalyticsData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Key metrics header
                          Row(
                            children: [
                              Icon(
                                Icons.dashboard,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Key Metrics',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Metrics grid
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.1,
                            children: [
                              _MetricCard(
                                title: 'Active Users',
                                value: '1,248',
                                change: '+12%',
                                icon: Icons.people,
                                gradientColors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                                index: 0,
                                animation: _metricsAnimationController,
                              ),
                              _MetricCard(
                                title: 'Course Completions',
                                value: '342',
                                change: '+8%',
                                icon: Icons.school,
                                gradientColors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                                index: 1,
                                animation: _metricsAnimationController,
                              ),
                              _MetricCard(
                                title: 'Avg. Engagement',
                                value: '72%',
                                change: '+5%',
                                icon: Icons.bar_chart,
                                gradientColors: [
                                  Colors.orange.shade400,
                                  Colors.orange.shade600,
                                ],
                                index: 2,
                                animation: _metricsAnimationController,
                              ),
                              _MetricCard(
                                title: 'Revenue',
                                value: '\$12,480',
                                change: '+15%',
                                icon: Icons.attach_money,
                                gradientColors: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade600,
                                ],
                                index: 3,
                                animation: _metricsAnimationController,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Charts section
                          FadeTransition(
                            opacity: _chartsAnimationController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Weekly Engagement
                                Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Weekly Engagement',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _ChartCard(
                                  height: 220,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.show_chart,
                                        size: 48,
                                        color: Colors.blue.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Engagement Chart',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Interactive visualization coming soon',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Monthly Revenue
                                Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Monthly Revenue',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _ChartCard(
                                  height: 220,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.area_chart,
                                        size: 48,
                                        color: Colors.green.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Revenue Trend',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Interactive visualization coming soon',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Course Performance
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assessment,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Course Performance',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _ChartCard(
                                  height: 220,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pie_chart,
                                        size: 48,
                                        color: Colors.purple.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Performance Analysis',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Interactive visualization coming soon',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Detailed Reports
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Detailed Reports',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      _ReportItem(
                                        title: 'User Engagement Report',
                                        description:
                                            'Detailed analysis of user activity and engagement patterns',
                                        icon: Icons.people_outline,
                                        color: Colors.blue,
                                        onTap: () {},
                                      ),
                                      Divider(
                                        height: 1,
                                        color: Colors.grey[200],
                                      ),
                                      _ReportItem(
                                        title: 'Course Performance Report',
                                        description:
                                            'Comprehensive analysis of course completion rates',
                                        icon: Icons.school_outlined,
                                        color: Colors.green,
                                        onTap: () {},
                                      ),
                                      Divider(
                                        height: 1,
                                        color: Colors.grey[200],
                                      ),
                                      _ReportItem(
                                        title: 'Financial Report',
                                        description:
                                            'Revenue breakdown by course and subscription',
                                        icon: Icons.account_balance_wallet,
                                        color: Colors.purple,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final List<Color> gradientColors;
  final int index;
  final AnimationController animation;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.gradientColors,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.15;
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeIn),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        change,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final double height;
  final Widget child;

  const _ChartCard({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[50]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
