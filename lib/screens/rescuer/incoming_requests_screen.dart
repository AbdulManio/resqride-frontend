import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class IncomingRequestsScreen extends StatelessWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Requests'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.build, color: AppColors.secondary),
              ),
              title: Text('Request #${1000 + index}'),
              subtitle: Text('Problem: ${index % 2 == 0 ? "Puncture" : "Battery Jump"}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/fare-offer'),
            ),
          );
        },
      ),
    );
  }
}
