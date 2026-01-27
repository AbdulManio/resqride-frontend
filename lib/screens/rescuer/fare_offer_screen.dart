import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FareOfferScreen extends StatefulWidget {
  const FareOfferScreen({super.key});

  @override
  State<FareOfferScreen> createState() => _FareOfferScreenState();
}

class _FareOfferScreenState extends State<FareOfferScreen> {
  final TextEditingController _fareController = TextEditingController(text: '600');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Offer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User offered: 500 PKR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Text('Your counter-offer (PKR)'),
            const SizedBox(height: 8),
            Row(
              children: [
                _OfferButton(label: '500', onTap: () => _fareController.text = '500'),
                const SizedBox(width: 8),
                _OfferButton(label: '600', onTap: () => _fareController.text = '600'),
                const SizedBox(width: 8),
                _OfferButton(label: '700', onTap: () => _fareController.text = '700'),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _fareController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'PKR ',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Offer sent! Waiting for customer...')),
                );
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) context.push('/navigation-map');
                });
              },
              child: const Text('Send Offer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OfferButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
