import 'package:flutter/material.dart';
import '../models/user.dart';

class RoleManagementScreen extends StatefulWidget {
  final int userId;
  final String? token;

  const RoleManagementScreen({super.key, required this.userId, this.token});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  List<User> _users = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRolesAndUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRolesAndUsers() async {
    try {
      // In a real implementation, you would fetch this data from the backend
      // For now, we'll use placeholder data

      setState(() {
        // Placeholder roles
        _roles = [
          {
            'id': 1,
            'name': 'Administrator',
            'description': 'Full access to all system features',
            'permissions': ['manage_users', 'manage_courses', 'view_reports'],
          },
          {
            'id': 2,
            'name': 'Instructor',
            'description': 'Can create and manage courses',
            'permissions': [
              'create_courses',
              'manage_enrollments',
              'grade_assignments',
            ],
          },
          {
            'id': 3,
            'name': 'Student',
            'description': 'Can enroll in courses and take quizzes',
            'permissions': [
              'enroll_courses',
              'take_quizzes',
              'submit_assignments',
            ],
          },
          {
            'id': 4,
            'name': 'Teaching Assistant',
            'description': 'Can assist instructors with course management',
            'permissions': [
              'manage_enrollments',
              'grade_assignments',
              'moderate_discussions',
            ],
          },
        ];

        // Placeholder users
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
          User(
            id: "4",
            username: 'ta1',
            email: 'ta1@example.com',
            firstName: 'Robert',
            lastName: 'Johnson',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load roles and users: $e';
        _isLoading = false;
      });
    }
  }

  void _assignRole(int userId, int roleId) {
    // In a real implementation, you would make an API call to assign the role
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Role assigned successfully')));
  }

  void _removeRole(int userId, int roleId) {
    // In a real implementation, you would make an API call to remove the role
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Role removed successfully')));
  }

  List<User> _filterUsers(String query) {
    if (query.isEmpty) return _users;

    return _users.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      return fullName.contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase()) ||
          user.username.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filterUsers(_searchController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
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
                      onPressed: _loadRolesAndUsers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRolesAndUsers,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 20),

                        // Roles overview
                        const Text(
                          'Available Roles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _roles.length,
                          itemBuilder: (context, index) {
                            final role = _roles[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      role['description'],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          (role['permissions'] as List)
                                              .map<Widget>((permission) {
                                                return Chip(
                                                  label: Text(
                                                    permission.toString(),
                                                  ),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondaryContainer,
                                                );
                                              })
                                              .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Users with roles
                        const Text(
                          'Users and Their Roles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filteredUsers.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No users found'),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            child: Text(
                                              user.firstName.substring(0, 1),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${user.firstName} ${user.lastName}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  user.email,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  user.username,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Assigned Roles:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          _RoleChip(
                                            roleName: 'Administrator',
                                            onRemove:
                                                () => _removeRole(
                                                  user.id as int,
                                                  1,
                                                ),
                                          ),
                                          _RoleChip(
                                            roleName: 'Instructor',
                                            onRemove:
                                                () => _removeRole(
                                                  user.id as int,
                                                  2,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Text('Add Role:'),
                                          const SizedBox(width: 10),
                                          DropdownButton<String>(
                                            hint: const Text('Select role'),
                                            items:
                                                _roles.map<
                                                  DropdownMenuItem<String>
                                                >((role) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value:
                                                        role['name'] as String,
                                                    child: Text(
                                                      role['name'] as String,
                                                    ),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              if (value != null) {
                                                final roleId =
                                                    _roles.firstWhere(
                                                          (role) =>
                                                              role['name'] ==
                                                              value,
                                                        )['id']
                                                        as int;
                                                _assignRole(
                                                  user.id as int,
                                                  roleId,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String roleName;
  final VoidCallback onRemove;

  const _RoleChip({required this.roleName, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(roleName),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
    );
  }
}
