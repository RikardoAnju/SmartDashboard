// lib/Dashboard/profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  final Map<String, dynamic>? userData;

  const ProfilePage({
    Key? key,
    required this.userEmail,
    this.userData,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _getUserName() {
    if (widget.userData != null && widget.userData!['name'] != null) {
      return widget.userData!['name'];
    }
    return widget.userEmail.split('@')[0];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF3B82F6),
            child: Text(
              _getUserName().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User Name
          Text(
            _getUserName(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          // User Email
          Text(
            widget.userEmail,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          // Profile Options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProfileOption(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () {
                    // Handle edit profile
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: 'Change password and security settings',
                  onTap: () {
                    // Handle security settings
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    // Handle notifications settings
                  },
                ),
                const Divider(height: 1),
                _buildProfileOption(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    // Handle help
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF6B7280),
      ),
      onTap: onTap,
    );
  }
}