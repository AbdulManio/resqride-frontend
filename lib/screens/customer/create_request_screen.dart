import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Problem: Puncture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Description (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe your issue briefly...',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Offered Fare (PKR)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fareController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '500',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rescuers nearby usually accept 500 - 800 PKR',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                final fare = int.tryParse(_fareController.text) ?? 0;
                if (fare < 500) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Price Too Low'),
                      content: const Text(
                        'No rescuer found for this price range. Please offer at least 500 PKR to find nearby rescuers.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Adjust Price'),
                        ),
                      ],
                    ),
                  );
                } else {
                  context.push('/offers');
                }
              },
              child: const Text('Find Rescuers'),
            ),
          ],
        ),
      ),
    );
  }
}
