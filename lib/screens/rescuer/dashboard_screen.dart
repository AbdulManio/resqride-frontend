import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RescuerDashboardScreen extends StatefulWidget {
  const RescuerDashboardScreen({super.key});

  @override
  State<RescuerDashboardScreen> createState() => _RescuerDashboardScreenState();
}

class _RescuerDashboardScreenState extends State<RescuerDashboardScreen> {
  bool _isOnline = false;

  void _onBottomNavTap(int index) {
    if (index == 0) return; // Already on Home

    if (index == 1) {
      context.push('/rescuer-earnings');
    } else if (index == 2) {
      context.push('/rescuer-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Dashboard'),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isOnline,
                onChanged: (value) => setState(() => _isOnline = value),
                activeThumbColor: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
      body: _isOnline ? const _RequestsListView() : const _OfflineView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onBottomNavTap,
        selectedItemColor: AppColors.secondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'You are currently offline',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text('Go online to start receiving rescue requests'),
        ],
      ),
    );
  }
}

class _RequestsListView extends StatefulWidget {
  const _RequestsListView();

  @override
  State<_RequestsListView> createState() => _RequestsListViewState();
}

class _RequestsListViewState extends State<_RequestsListView> {
  // Use local state to track removed items for UI-level behavior
  final Set<int> _removedIndices = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        if (_removedIndices.contains(index)) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Chip(
                      label: Text('Puncture'),
                      backgroundColor: AppColors.primary,
                    ),
                    Text(
                      'PKR ${500 + (index * 100)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text('Location: ${(index + 1) * 1.2} km away'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _removedIndices.add(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request declined'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        },
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/fare-offer'),
                        child: const Text('Send Offer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
