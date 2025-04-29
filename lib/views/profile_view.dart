import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/profile_model.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view profile'));
    }

    final profile = Profile(
      uid: user['uid'] ?? '',
      displayName: user['displayName'] ?? 'Guest User',
      email: user['email'] ?? 'No email',
      lastActive: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Display Name'),
                    subtitle: Text(profile.displayName),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(profile.email),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Last Active'),
                    subtitle: Text(
                      profile.lastActive?.toString() ?? 'Not available',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // const SizedBox(height: 20),
          // ElevatedButton.icon(
          //   onPressed: () => authViewModel.signOut(),
          //   icon: const Icon(Icons.logout),
          //   label: const Text('Sign Out'),
          //   style: ElevatedButton.styleFrom(
          //     padding: const EdgeInsets.all(16),
          //   ),
          // ),
        ],
      ),
    );
  }
}
