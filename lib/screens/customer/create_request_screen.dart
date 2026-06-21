import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../services/request_service.dart';
import '../../services/ai_api_service.dart';

class CreateRequestScreen extends StatefulWidget {
  final String problemType;
  const CreateRequestScreen({super.key, required this.problemType});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  int? _predictedFare;
  bool _isPredictingPrice = false;

  @override
  void initState() {
    super.initState();
    _estimatePrice();
  }

  Future<void> _estimatePrice() async {
    if (!mounted) return;
    setState(() {
      _isPredictingPrice = true;
    });

    final position = await _getCurrentLocation();
    if (position != null) {
      // Determine vehicle type based on problem type
      String vehicleType = 'Car';
      if (widget.problemType.toLowerCase().contains('bike')) {
        vehicleType = 'Bike';
      } else if (widget.problemType.toLowerCase().contains('suv')) {
        vehicleType = 'SUV';
      }

      // Randomize distance between 3.0 and 8.0 km to ensure price variation
      final randomDistance = 3.0 + Random().nextDouble() * 5.0;

      final price = await AiApiService.predictPrice(
        serviceType: widget.problemType,
        vehicleType: vehicleType,
        distance: randomDistance,
        lat: position.latitude,
        lng: position.longitude,
      );

      if (price != null && mounted) {
        setState(() {
          _predictedFare = price;
          _fareController.text = price.toString();
        });
      }
    }

    if (mounted) {
      setState(() {
        _isPredictingPrice = false;
      });
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('❌ Location error: $e');
      return null;
    }
  }

  Future<void> _findRescuers() async {
    final fare = int.tryParse(_fareController.text) ?? 0;

    if (fare < 500) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Price Too Low'),
          content: const Text(
            'Please offer at least 500 PKR to find nearby rescuers.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Adjust Price'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Get current location
    final position = await _getCurrentLocation();

    if (position == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get your location. Please enable GPS.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Create request on backend
    final response = await RequestService.createRequest(
      problemType: widget.problemType,
      offeredFare: fare,
      lat: position.latitude,
      lng: position.longitude,
      description: _descriptionController.text,
      estimatedPrice: _predictedFare,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      final requestId = response['request']['_id'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request created! Searching for rescuers...'),
          backgroundColor: Colors.green,
        ),
      );

      // Go to offers screen with requestId
      context.push('/offers', extra: {
        'requestId': requestId,
        'offeredFare': fare,
        'problemType': widget.problemType,
        'estimatedPrice': _predictedFare,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to create request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Problem: ${widget.problemType}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe your issue briefly...',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Offered Fare (PKR)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isPredictingPrice)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Predicting estimated price...',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            else if (_predictedFare != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Estimated Cost: PKR $_predictedFare',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
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
            Text(
              _predictedFare != null
                  ? 'Rescuers nearby usually accept $_predictedFare - ${_predictedFare! + 300} PKR'
                  : 'Rescuers nearby usually accept 500 - 800 PKR',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _findRescuers,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Find Rescuers',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
