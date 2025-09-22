import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/view_models/auth_view_model.dart';
import 'package:receipt_application/views/auth_view.dart';

// ignore: use_key_in_widget_constructors
class AccountView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final accountDetails = authViewModel.getAccountDetails();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 177, 199, 176),
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 177, 199, 176),
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Account Details Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email,
                          color: Color.fromARGB(255, 18, 196, 33)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Email: ${accountDetails['email'] ?? 'Not available'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person,
                          color: Color.fromARGB(255, 18, 196, 33)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Username: ${accountDetails['username'] ?? 'Not available'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Logout"),
                        content:
                            const Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (shouldLogout) {
                  if (context.mounted) {
                    await authViewModel.logout(context);
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AuthView(isLoggedIn: false)),
                        (route) => false,
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
