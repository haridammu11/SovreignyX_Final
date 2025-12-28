import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  final String reportType;
  final String? token;

  const ReportsScreen({super.key, required this.reportType, this.token});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _reportData = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      // In a real implementation, you would fetch this data from the backend
      // For now, we'll use sample data based on the report type

      setState(() {
        // Sample data based on report type
        if (widget.reportType == 'engagement') {
          _reportData = [
            {
              'metric': 'Daily Active Users',
              'value': '1,248',
              'change': '+12%',
              'trend': 'up',
            },
            {
              'metric': 'Session Duration',
              'value': '24.5 min',
              'change': '+3.2 min',
              'trend': 'up',
            },
            {
              'metric': 'Course Completion Rate',
              'value': '68%',
              'change': '+5%',
              'trend': 'up',
            },
            {
              'metric': 'Quiz Participation',
              'value': '82%',
              'change': '-2%',
              'trend': 'down',
            },
          ];
        } else if (widget.reportType == 'performance') {
          _reportData = [
            {
              'course': 'Introduction to Flutter',
              'students': '245',
              'completion': '78%',
              'avgScore': '85',
            },
            {
              'course': 'Advanced Django',
              'students': '189',
              'completion': '65%',
              'avgScore': '72',
            },
            {
              'course': 'React Fundamentals',
              'students': '312',
              'completion': '82%',
              'avgScore': '88',
            },
            {
              'course': 'Machine Learning Basics',
              'students': '156',
              'completion': '54%',
              'avgScore': '67',
            },
          ];
        } else if (widget.reportType == 'financial') {
          _reportData = [
            {
              'source': 'Course Sales',
              'amount': '\$8,450',
              'percentage': '68%',
            },
            {
              'source': 'Subscriptions',
              'amount': '\$3,240',
              'percentage': '26%',
            },
            {'source': 'Certifications', 'amount': '\$790', 'percentage': '6%'},
          ];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    switch (widget.reportType) {
      case 'engagement':
        title = 'User Engagement Report';
        break;
      case 'performance':
        title = 'Course Performance Report';
        break;
      case 'financial':
        title = 'Financial Report';
        break;
      default:
        title = 'Report';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReportData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadReportData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Report summary
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Report Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (widget.reportType == 'engagement')
                                  const Text(
                                    'This report provides insights into user engagement patterns, '
                                    'including active users, session duration, and course completion rates.',
                                  )
                                else if (widget.reportType == 'performance')
                                  const Text(
                                    'This report analyzes course performance metrics, '
                                    'including student enrollment, completion rates, and average scores.',
                                  )
                                else if (widget.reportType == 'financial')
                                  const Text(
                                    'This report details financial performance, '
                                    'including revenue sources and earnings breakdown.',
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Report data table
                        const Text(
                          'Detailed Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                if (widget.reportType == 'engagement')
                                  _EngagementTable(data: _reportData)
                                else if (widget.reportType == 'performance')
                                  _PerformanceTable(data: _reportData)
                                else if (widget.reportType == 'financial')
                                  _FinancialTable(data: _reportData),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Export options
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Export Report',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Download this report in your preferred format:',
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Export as PDF
                                      },
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('PDF'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Export as CSV
                                      },
                                      icon: const Icon(Icons.table_chart),
                                      label: const Text('CSV'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Export as Excel
                                      },
                                      icon: const Icon(Icons.grid_on),
                                      label: const Text('Excel'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class _EngagementTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _EngagementTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Metric',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Value',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Change',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        ...data.map((item) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['metric']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['value']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  item['change'],
                  style: TextStyle(
                    color: item['trend'] == 'up' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

class _PerformanceTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _PerformanceTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      border: TableBorder.all(),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Course',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Students',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Completion',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Avg Score',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        ...data.map((item) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['course']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['students']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['completion']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['avgScore']),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

class _FinancialTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _FinancialTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Colors.grey),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Source',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Percentage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        ...data.map((item) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['source']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['amount']),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['percentage']),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}
