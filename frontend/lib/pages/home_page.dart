import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Chat'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<Session>().clear();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user.displayName ?? user.username ?? user.walletAddress}'),
            const SizedBox(height: 8),
            Text('Wallet: ${user.walletAddress}'),
            const SizedBox(height: 8),
            Text('UserId: ${user.id}'),
            const SizedBox(height: 16),
            const Text('You are logged in. Build chat UI here.'),
          ],
        ),
      ),
    );
  }
}