import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int userId;
  final String? token;
  final AuthService? authService; // Add this parameter

  const AdminDashboardScreen({
    super.key,
    required this.userId,
    this.token,
    this.authService,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AuthService _authService;

  List<User> _users = [];
  List<Course> _courses = [];
  List<Payment> _payments = [];

  bool _isLoading = true;
  String _errorMessage = '';
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _authService =
        widget.authService ??
        AuthService(); // Use passed instance or create new one
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      // In a real implementation, you would fetch this data from the backend
      // For now, we'll use placeholder data

      setState(() {
        // Placeholder data
        _users = [
          User(
            id: "1",
            username: 'admin',
            email: 'admin@example.com',
            firstName: 'Admin',
            lastName: 'User',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          User(
            id: "2",
            username: 'instructor1',
            email: 'instructor1@example.com',
            firstName: 'John',
            lastName: 'Doe',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          User(
            id: "3",
            username: 'student1',
            email: 'student1@example.com',
            firstName: 'Jane',
            lastName: 'Smith',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        _courses = [
          Course(
            id: 1,
            title: 'Introduction to Flutter',
            description: 'Learn Flutter development from scratch',
            categoryId: 1,
            instructorId: 2,
            price: 99.99,
            isPublished: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Course(
            id: 2,
            title: 'Advanced Django',
            description: 'Master Django web development',
            categoryId: 1,
            instructorId: 2,
            price: 149.99,
            isPublished: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        _payments = [
          Payment(
            id: 1,
            userId: 3,
            amount: 99.99,
            currency: 'USD',
            status: 'COMPLETED',
            paymentMethod: 'CREDIT_CARD',
            transactionId: 'txn_12345',
            paymentDate: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load admin data: $e';
        _isLoading = false;
      });
    }
  }

  int _calculateTotalRevenue() {
    return _payments.fold(0, (sum, payment) => sum + payment.amount.toInt());
  }

  int _calculateTotalSubscribers() {
    return 42; // Placeholder value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'profile', child: Text('Profile')),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
            onSelected: (value) {
              if (value == 'logout') {
                // Handle logout
                _handleLogout();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Learning Management System',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _activeTab == 0,
              onTap: () {
                setState(() {
                  _activeTab = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              selected: _activeTab == 1,
              onTap: () {
                setState(() {
                  _activeTab = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Courses'),
              selected: _activeTab == 2,
              onTap: () {
                setState(() {
                  _activeTab = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payments'),
              selected: _activeTab == 3,
              onTap: () {
                setState(() {
                  _activeTab = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions),
              title: const Text('Subscriptions'),
              selected: _activeTab == 4,
              onTap: () {
                setState(() {
                  _activeTab = 4;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Navigate to settings
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                // Navigate to help
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
                      onPressed: _loadAdminData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadAdminData,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats cards
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _StatCard(
                              title: 'Total Users',
                              value: '${_users.length}',
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                            _StatCard(
                              title: 'Total Courses',
                              value: '${_courses.length}',
                              icon: Icons.school,
                              color: Colors.green,
                            ),
                            _StatCard(
                              title: 'Revenue',
                              value: '\$${_calculateTotalRevenue()}',
                              icon: Icons.attach_money,
                              color: Colors.orange,
                            ),
                            _StatCard(
                              title: 'Subscribers',
                              value: '${_calculateTotalSubscribers()}',
                              icon: Icons.subscriptions,
                              color: Colors.purple,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Recent activity
                        const Text(
                          'Recent Activity',
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
                                _ActivityItem(
                                  icon: Icons.person_add,
                                  title: 'New user registered',
                                  subtitle: 'Jane Smith joined the platform',
                                  time: '2 hours ago',
                                ),
                                const Divider(),
                                _ActivityItem(
                                  icon: Icons.school,
                                  title: 'New course published',
                                  subtitle: 'Advanced Django by John Doe',
                                  time: '5 hours ago',
                                ),
                                const Divider(),
                                _ActivityItem(
                                  icon: Icons.payment,
                                  title: 'Payment received',
                                  subtitle:
                                      'Student purchased Introduction to Flutter',
                                  time: '1 day ago',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Quick actions
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _ActionButton(
                              title: 'Add User',
                              icon: Icons.person_add,
                              onPressed: () {
                                // Add user functionality
                              },
                            ),
                            _ActionButton(
                              title: 'Create Course',
                              icon: Icons.school,
                              onPressed: () {
                                // Create course functionality
                              },
                            ),
                            _ActionButton(
                              title: 'View Payments',
                              icon: Icons.payment,
                              onPressed: () {
                                // View payments functionality
                              },
                            ),
                            _ActionButton(
                              title: 'Manage Subscriptions',
                              icon: Icons.subscriptions,
                              onPressed: () {
                                // Manage subscriptions functionality
                              },
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

  void _handleLogout() async {
    await _authService.logout();
    // Navigate back to auth screen
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
