/// 🎯 INVITE USER WIDGET - Component for inviting users to project
///
/// Allows searching and inviting users by display name
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../backend/models/user.dart';
import '../../../providers/shared_project_providers.dart';
import '../../../providers/performance_initialization_providers.dart';

class InviteUserWidget extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;

  const InviteUserWidget({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  ConsumerState<InviteUserWidget> createState() => _InviteUserWidgetState();
}

class _InviteUserWidgetState extends ConsumerState<InviteUserWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter user display name', // ✅ CHANGED: English
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF3C3C3C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _isSearching
                ? Container(
                    padding: const EdgeInsets.all(12),
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _searchUsers,
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
          ),
          onSubmitted: (_) => _searchUsers,
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _searchResults.clear();
                _errorMessage = null;
              });
            }
          },
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],

        // Search results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: const Color(0xFF3C3C3C),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _inviteUser(user),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _generateAvatarColor(user.id),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(user.displayName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '@${user.username}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.add,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final userBox = ref.read(enhancedUserBoxProvider);
      final existingMembers = ref.read(assignableUsersInProjectProvider(widget.projectId));
      final existingMemberIds = existingMembers.map((u) => u.id).toSet();

      // Search for users by display name or username
      final results = userBox.values
          .where((user) =>
              (user.displayName.toLowerCase().contains(query.toLowerCase()) ||
               user.username.toLowerCase().contains(query.toLowerCase())) &&
              !existingMemberIds.contains(user.id))
          .take(5)
          .toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
        if (results.isEmpty) {
          _errorMessage = 'No users found'; // ✅ CHANGED: English
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed: $e'; // ✅ CHANGED: English
      });
    }
  }

  void _inviteUser(User user) async {
    try {
      await ref.read(sharedProjectProvider(widget.projectId).notifier).inviteUser(
            user.id,
            user.displayName,
            widget.projectName,
          );

      setState(() {
        _searchResults.clear();
        _searchController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${user.displayName}'), // ✅ CHANGED: English
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'), // ✅ CHANGED: English
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper methods for avatar generation
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1)).toUpperCase();
    }
  }

  Color _generateAvatarColor(String input) {
    int hash = input.hashCode;
    List<Color> colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
      Colors.pink[600]!,
      Colors.cyan[600]!,
    ];
    return colors[hash.abs() % colors.length];
  }
}
