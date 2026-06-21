import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/request_service.dart';

class RescuerEarningsScreen extends StatefulWidget {
  const RescuerEarningsScreen({super.key});

  @override
  State<RescuerEarningsScreen> createState() => _RescuerEarningsScreenState();
}

class _RescuerEarningsScreenState extends State<RescuerEarningsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _earningsData = {};
  List<dynamic> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);

    final response = await RescuerService.getEarnings();

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      setState(() {
        _earningsData = response;
        _jobs = response['jobs'] ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEarnings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Jobs',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _jobs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.work_off,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No completed jobs yet',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildJobsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalEarnings = _earningsData['totalEarnings'] ?? 0;
    final todayEarnings = _earningsData['todayEarnings'] ?? 0;
    final totalJobs = _earningsData['totalJobs'] ?? 0;
    final todayJobs = _earningsData['todayJobs'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'PKR ${totalEarnings.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Today: PKR $todayEarnings',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Jobs', totalJobs.toString()),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Today', todayJobs.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildJobsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        final fare = job['finalFare'] ?? job['offeredFare'] ?? 0;
        final date = job['completedAt'] != null
            ? DateTime.parse(job['completedAt']).toLocal()
            : null;
        final dateStr = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            title: Text(job['problemType'] ?? 'Service'),
            subtitle: Text(dateStr),
            trailing: Text(
              '+ PKR $fare',
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
