import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/request_service.dart';

class FareOfferScreen extends StatefulWidget {
  final String requestId;
  final int offeredFare;
  final String problemType;

  const FareOfferScreen({
    super.key,
    required this.requestId,
    required this.offeredFare,
    required this.problemType,
  });

  @override
  State<FareOfferScreen> createState() => _FareOfferScreenState();
}

class _FareOfferScreenState extends State<FareOfferScreen> {
  late TextEditingController _fareController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fareController =
        TextEditingController(text: widget.offeredFare.toString());
  }

  Future<void> _sendOffer() async {
    final fare = int.tryParse(_fareController.text) ?? 0;

    if (fare < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid fare amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await RescuerService.sendOffer(
      requestId: widget.requestId,
      counterFare: fare,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Offer sent! Waiting for customer...'),
          backgroundColor: Colors.green,
        ),
      );

      // Listen for offer accepted via socket
      // Go back to dashboard and wait
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to send offer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Offer')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Request Info ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problem: ${widget.problemType}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer offered: PKR ${widget.offeredFare}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Your counter-offer (PKR)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // ─── Quick Amount Buttons ─────────────────────────────────
            Row(
              children: [
                _OfferButton(
                    label: '${widget.offeredFare}',
                    onTap: () => _fareController.text =
                        widget.offeredFare.toString()),
                const SizedBox(width: 8),
                _OfferButton(
                    label: '${widget.offeredFare + 100}',
                    onTap: () => _fareController.text =
                        (widget.offeredFare + 100).toString()),
                const SizedBox(width: 8),
                _OfferButton(
                    label: '${widget.offeredFare + 200}',
                    onTap: () => _fareController.text =
                        (widget.offeredFare + 200).toString()),
              ],
            ),

            const SizedBox(height: 24),

            // ─── Custom Amount Input ──────────────────────────────────
            TextField(
              controller: _fareController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'PKR ',
                hintText: '600',
              ),
            ),

            const Spacer(),

            // ─── Send Button ──────────────────────────────────────────
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOffer,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Offer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
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
