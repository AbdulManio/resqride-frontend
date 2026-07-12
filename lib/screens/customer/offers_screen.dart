import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/request_service.dart';
import '../../services/socket_service.dart';

class OffersScreen extends StatefulWidget {
  final String requestId;
  final int offeredFare;
  final String problemType;
  final int? estimatedPrice;

  const OffersScreen({
    super.key,
    required this.requestId,
    required this.offeredFare,
    required this.problemType,
    this.estimatedPrice,
  });

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _listenForOffers();
    _fetchOffers(); // Fetch offers immediately
    _pollOffers(); // Poll every 5 seconds
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.off('new:offer');
    super.dispose();
  }

  // Fetch offers immediately from backend
  Future<void> _fetchOffers() async {
    final response = await RequestService.getOffers(widget.requestId);
    if (response['success'] == true && mounted) {
      final serverOffers = List<Map<String, dynamic>>.from(response['offers'] ?? []);
      setState(() {
        _offers = serverOffers;
      });
    }
  }

  // Listen for real-time offers via socket
  void _listenForOffers() {
    SocketService.onNewOffer((data) {
      if (mounted) {
        setState(() {
          // Filter out demo offers when real offers arrive
          _offers.removeWhere((o) => o['_id'].toString().startsWith('demo_'));

          final offerId = data['_id'] ?? data['offerId'] ?? data['id'] ?? '';
          final exists = _offers.any((o) => (o['_id'] ?? o['id'] ?? '') == offerId);
          if (!exists && offerId.toString().isNotEmpty) {
            _offers.add({
              '_id': offerId,
              'rescuer': data['rescuer'],
              'counterFare': data['counterFare'],
              'distanceKm': data['distanceKm'],
              'etaMinutes': data['etaMinutes'],
            });
          }
        });
      }
    });
  }

  // Poll offers from backend every 5 seconds
  void _pollOffers() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final response = await RequestService.getOffers(widget.requestId);
      if (response['success'] == true && mounted) {
        final serverOffers = List<Map<String, dynamic>>.from(response['offers'] ?? []);
        setState(() {
          _offers = serverOffers;
        });
      }
    });
  }

  Future<void> _acceptOffer(String offerId, int finalFare) async {
    setState(() => _isLoading = true);

    bool isSuccess = false;
    String? message;

    if (offerId.startsWith('demo_')) {
      // Simulate network delay for a real experience
      await Future.delayed(const Duration(milliseconds: 600));
      isSuccess = true;
    } else {
      final response = await RequestService.acceptOffer(offerId);
      isSuccess = response['success'] == true;
      message = response['message'];
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (isSuccess) {
      _pollTimer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer accepted! Rescuer is on the way 🚗'),
          backgroundColor: Colors.green,
        ),
      );

      // Join request room for real-time tracking
      SocketService.joinRequest(widget.requestId);

      // Go to tracking screen
      context.push('/tracking', extra: {
        'requestId': widget.requestId,
        'finalFare': finalFare,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Failed to accept offer'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RequestService.cancelRequest(widget.requestId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Offers'),
        actions: [
          TextButton(
            onPressed: _cancelRequest,
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Offer: ${widget.offeredFare} PKR',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (widget.estimatedPrice != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Estimated Price: ${widget.estimatedPrice} PKR',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _offers.isEmpty
                            ? 'Searching for nearby rescuers...'
                            : '${_offers.length} offer(s) received',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_offers.isEmpty)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // ─── Offers List ─────────────────────────────────────────────
          Expanded(
            child: _offers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for rescuers to respond...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This usually takes 1-2 minutes',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      final rescuer = offer['rescuer'] ?? {};
                      
                      // Format distance dynamically to prevent decimal overflow (e.g. 2.4000000000000004 km)
                      String distanceStr = 'N/A';
                      if (offer['distanceKm'] != null) {
                        final dist = double.tryParse(offer['distanceKm'].toString());
                        distanceStr = dist != null ? '${dist.toStringAsFixed(1)} km' : '${offer['distanceKm']} km';
                      }

                      final profileUrl = rescuer['profilePicture'] ??
                          rescuer['avatar'] ??
                          rescuer['profileImage'] ??
                          rescuer['profilePic'] ??
                          rescuer['profilePhoto'] ??
                          rescuer['profile'] ??
                          '';

                      return _OfferCard(
                        name: rescuer['name'] ?? 'Rescuer',
                        distance: distanceStr,
                        rating: (rescuer['rating'] ?? 0).toDouble(),
                        fare: offer['counterFare'] ?? 0,
                        profileUrl: profileUrl.toString(),
                        isLoading: _isLoading,
                        onAccept: () => _acceptOffer(
                          offer['_id'],
                          offer['counterFare'] ?? 0,
                        ),
                        onReject: () {
                          setState(() => _offers.removeAt(index));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String name;
  final String distance;
  final double rating;
  final int fare;
  final String? profileUrl;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferCard({
    required this.name,
    required this.distance,
    required this.rating,
    required this.fare,
    this.profileUrl,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary,
                  backgroundImage: (profileUrl != null && profileUrl!.isNotEmpty)
                      ? NetworkImage(profileUrl!)
                      : null,
                  child: (profileUrl == null || profileUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' $rating • $distance away'),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'PKR $fare',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAccept,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
