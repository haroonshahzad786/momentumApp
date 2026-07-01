import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/demo_page.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAnonymous = user?.isAnonymous ?? true;
    final email = user?.email;
    final primary = Theme.of(context).colorScheme.primary;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                isAnonymous ? Icons.person_outline : Icons.person,
                size: 36,
                color: primary,
              ),
            ),
            accountName: Text(isAnonymous ? 'Guest' : 'Registered'),
            accountEmail: Text(
              isAnonymous ? 'Anonymous account' : (email ?? ''),
            ),
          ),
          if (isAnonymous)
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text('Register Account'),
              subtitle: const Text('Save your progress with email + password'),
              onTap: () => _onRegister(context),
            ),
          const Spacer(),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _onLogout(context),
          ),
        ],
      ),
    );
  }

  void _onRegister(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account linking — coming in Step 5'),
      ),
    );
  }

  Future<void> _onLogout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DemoPage()),
      (route) => false,
    );
  }
}
