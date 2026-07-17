import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../services/request_service.dart';
import '../../services/ai_api_service.dart';
import '../../services/location_service.dart';

class CreateRequestScreen extends StatefulWidget {
  final String problemType;
  const CreateRequestScreen({super.key, required this.problemType});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  bool _isLoadingLocation = true;
  bool _isLoadingPrice = false;
  int? _predictedFare;

  // Location
  Position? _gpsPosition;
  LatLng? _selectedLocation;
  String _locationText = 'Getting your location...';
  bool _useSearchedLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _gpsPosition = position;
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
          _useSearchedLocation = false;
        });
        _updateAddress(position.latitude, position.longitude);
        _getPredictedPrice(position.latitude, position.longitude);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _updateAddress(double lat, double lng) async {
    final address = await _locationService.getAddressFromLatLng(lat, lng);
    if (mounted) setState(() => _locationText = address);
  }

  Future<void> _searchAndSetLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoadingLocation = true);

    try {
      final location = await _locationService.getLocationFromAddress(query);
      if (location != null && mounted) {
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
          _locationText = query;
          _useSearchedLocation = true;
          _isLoadingLocation = false;
        });
        _getPredictedPrice(location.latitude, location.longitude);
      } else {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found. Try again.')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getPredictedPrice(double lat, double lng) async {
    setState(() => _isLoadingPrice = true);
    try {
      final price = await AiApiService.predictPrice(
        serviceType: widget.problemType,
        vehicleType: 'Car',
        distance: 5.0,
        lat: lat,
        lng: lng,
      );
      if (price != null && mounted) {
        setState(() {
          _predictedFare = price;
          _fareController.text = price.toString();
          _isLoadingPrice = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingPrice = false);
    }
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Search Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter area, street or landmark...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context);
                  _searchAndSetLocation(value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _getCurrentLocation();
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use GPS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _searchAndSetLocation(_searchController.text);
                      },
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _findRescuers() async {
    final fare = int.tryParse(_fareController.text) ?? 0;

    if (fare < 500) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Price Too Low'),
          content: const Text(
              'Please offer at least 500 PKR to find nearby rescuers.'),
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

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please wait for location to load'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    print('🔍 DEBUG Creating request now...');
    final response = await RequestService.createRequest(
      problemType: widget.problemType,
      offeredFare: fare,
      lat: _selectedLocation!.latitude,
      lng: _selectedLocation!.longitude,
      description: _descriptionController.text,
      estimatedPrice: _predictedFare,
    );
    print('🔍 DEBUG Response: $response');

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
      context.push('/offers', extra: {
        'requestId': requestId,
        'offeredFare': fare,
        'problemType': widget.problemType,
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
            // ─── Problem Type ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.problemType,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Location Section ─────────────────────────────────────
            const Text('Your Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showLocationSearch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _useSearchedLocation
                          ? AppColors.primary
                          : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: _useSearchedLocation
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      _useSearchedLocation
                          ? Icons.location_searching
                          : Icons.my_location,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _isLoadingLocation
                          ? const Row(
                              children: [
                                SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Getting location...'),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _useSearchedLocation
                                      ? 'Searched Location'
                                      : 'Current Location (GPS)',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  _locationText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                    ),
                    const Icon(Icons.edit_location_alt,
                        color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            if (_useSearchedLocation)
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text('Use my GPS location instead'),
              ),

            const SizedBox(height: 20),

            // ─── Description ──────────────────────────────────────────
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

            const SizedBox(height: 20),

            // ─── AI Price Prediction ──────────────────────────────────
            if (_isLoadingPrice)
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('AI predicting fair price...'),
                  ],
                ),
              ),

            if (_predictedFare != null && !_isLoadingPrice)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Our Recommended Price: PKR $_predictedFare',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            const Text('Offered Fare (PKR)',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: _isLoading ? null : _findRescuers,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Find Rescuers',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
