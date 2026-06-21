import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/ai_api_service.dart';
import 'dart:async';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  String _locationText = 'Getting your location...';
  bool _isLoadingLocation = true;
  bool _isFollowingUser = true;
  StreamSubscription<Position>? _positionSubscription;
  Set<Marker> _markers = {};
  Set<Marker> _hotspotMarkers = {};
  Marker? _searchMarker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLiveLocation();
    _loadHotspots();
  }

  void _updateAllMarkers() {
    final Set<Marker> all = {};
    if (_currentPosition != null) {
      all.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
          flat: true,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    if (_searchMarker != null) {
      all.add(_searchMarker!);
    }
    all.addAll(_hotspotMarkers);
    if (mounted) {
      setState(() {
        _markers = all;
      });
    }
  }

  Future<void> _loadHotspots() async {
    final hotspots = await AiApiService.getHotspots();
    final Set<Marker> tempMarkers = {};
    for (var hotspot in hotspots) {
      final name = hotspot['name'] ?? 'Hotspot';
      final lat = (hotspot['latitude'] as num).toDouble();
      final lng = (hotspot['longitude'] as num).toDouble();
      final risk = hotspot['riskLevel'] ?? 'Low';
      
      double markerColor;
      if (risk == 'High') {
        markerColor = BitmapDescriptor.hueRed;
      } else if (risk == 'Medium') {
        markerColor = BitmapDescriptor.hueYellow;
      } else {
        markerColor = BitmapDescriptor.hueGreen;
      }

      tempMarkers.add(
        Marker(
          markerId: MarkerId('hotspot_$name'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: '$name Breakdown Zone',
            snippet: 'Risk Level: $risk',
          ),
        ),
      );
    }
    _hotspotMarkers = tempMarkers;
    _updateAllMarkers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopTracking();
    } else if (state == AppLifecycleState.resumed) {
      _initLiveLocation();
    }
  }

  void _stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Initialize live location tracking
  Future<void> _initLiveLocation() async {
    if (_positionSubscription != null) return; // Already tracking

    try {
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Please enable GPS';
          _isLoadingLocation = false;
        });
        return;
      }

      bool hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _locationText = 'Location permission required';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get initial position
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        _updateUIWithPosition(position);
      }

      // Start live updates (Every 3-5 seconds, High Accuracy)
      _positionSubscription = _locationService.getLocationStream().listen(
        (Position position) {
          if (mounted) {
            _updateUIWithPosition(position);
          }
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Location initialization error';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateUIWithPosition(Position position) async {
    _currentPosition = position;

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
      _updateAllMarkers();

      // Move camera smoothly if following user
      if (_isFollowingUser) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 17.0, // High zoom for ride-sharing feel
              tilt: 45.0, // Slight tilt for better perspective
            ),
          ),
        );
      }

      // Reverse geocode occasionally (don't do it on every tiny move to save API calls/battery)
      // For now we do it to keep UI updated
      _updateAddressText(position);
    }
  }

  Future<void> _updateAddressText(Position position) async {
    String address = await _locationService.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        _locationText = address;
      });
    }
  }

  /// Search location and show results
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
      _locationText = 'Searching...';
    });

    try {
      final location = await _locationService.getLocationFromAddress(query);

      if (location != null) {
        setState(() => _isFollowingUser = false);

        final searchMarker = Marker(
          markerId: const MarkerId('search_result'),
          position: LatLng(location.latitude, location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: query,
            snippet: 'Searched Location',
          ),
        );
        _searchMarker = searchMarker;

        if (mounted) {
          setState(() {
            _locationText = query;
            _isLoadingLocation = false;
          });
          _updateAllMarkers();

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 16.0,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _locationText = 'Location not found';
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _locationText = 'Search error';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 0) return; // Already on Home

    if (index == 1) {
      context.push('/customer-history');
    } else if (index == 2) {
      context.push('/customer-settings');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTracking();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Ride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/customer-notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/customer-profile'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map or Loading State
          _isLoadingLocation
              ? Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading map...'),
                      ],
                    ),
                  ),
                )
              : _currentPosition != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 15.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapType: MapType.normal,
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(_locationText),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() => _isLoadingLocation = true);
                                _initLiveLocation();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
          // Problem Selection Cards
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What is the problem?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ProblemTile(
                        icon: Icons.tire_repair,
                        label: 'Puncture',
                        onTap: () => _showPunctureOptions(),
                      ),
                      _ProblemTile(
                        icon: Icons.local_gas_station,
                        label: 'Fuel Delivery',
                        onTap: () => _showFuelDeliveryOptions(),
                      ),
                      _ProblemTile(
                        icon: Icons.battery_charging_full,
                        label: 'Battery Jump',
                        onTap: () => context
                            .push('/create-request?problem=Battery Jump'),
                      ),
                      _ProblemTile(
                        icon: Icons.build,
                        label: 'Minor Repair',
                        onTap: () => _showMinorRepairOptions(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context
                        .push('/create-request?problem=General Assistance'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Request Assistance'),
                  ),
                ],
              ),
            ),
          ),
          // My Location Button
          Positioned(
            right: 20,
            top: 90,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () {
                setState(() => _isFollowingUser = true);
                if (_currentPosition != null) {
                  _updateUIWithPosition(_currentPosition!);
                } else {
                  _initLiveLocation();
                }
              },
              child: Icon(
                _isFollowingUser ? Icons.my_location : Icons.location_searching,
                color: AppColors.primary,
              ),
            ),
          ),
          // Search/Location Bar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: InkWell(
              onTap: () {
                _showSearchDialog();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentPosition != null
                          ? Icons.location_on
                          : Icons.location_searching,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationText,
                        style: const TextStyle(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isLoadingLocation)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onBottomNavTap,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Search Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Enter area or city name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _searchLocation(value);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (searchController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _searchLocation(searchController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPunctureOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Puncture - Select Vehicle Type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _RepairOptionTile(
                    label: 'Car Puncture',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/create-request?problem=Puncture - Car');
                    },
                  ),
                  _RepairOptionTile(
                    label: 'Bike Puncture',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/create-request?problem=Puncture - Bike');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelDeliveryOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fuel Delivery - Select Quantity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _RepairOptionTile(
                    label: '0.5 Liter',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Fuel Delivery - 0.5 Liter');
                    },
                  ),
                  _RepairOptionTile(
                    label: '1 Liter',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Fuel Delivery - 1 Liter');
                    },
                  ),
                  _RepairOptionTile(
                    label: '2 Liters',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Fuel Delivery - 2 Liters');
                    },
                  ),
                  _RepairOptionTile(
                    label: '3 Liters',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Fuel Delivery - 3 Liters');
                    },
                  ),
                  _RepairOptionTile(
                    label: 'Custom Amount',
                    onTap: () {
                      Navigator.pop(context);
                      _showCustomAmountDialog();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomAmountDialog() {
    final TextEditingController customAmountController =
        TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Custom Amount'),
        content: TextField(
          controller: customAmountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter liters (e.g., 5.5)',
            suffixText: 'Liters',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (customAmountController.text.isNotEmpty) {
                Navigator.pop(context);
                context.push(
                    '/create-request?problem=Fuel Delivery - ${customAmountController.text} Liters');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showMinorRepairOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Minor Repair - Engine',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _RepairOptionTile(
                    label: 'Minor Coolant Leakage',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Minor Repair - Minor Coolant Leakage');
                    },
                  ),
                  _RepairOptionTile(
                    label: 'Minor Gasket Seepage',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Minor Repair - Minor Gasket Seepage');
                    },
                  ),
                  _RepairOptionTile(
                    label: 'Broken Timing Belt',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Minor Repair - Broken Timing Belt');
                    },
                  ),
                  _RepairOptionTile(
                    label: 'Engine Overheating',
                    onTap: () {
                      Navigator.pop(context);
                      context.push(
                          '/create-request?problem=Minor Repair - Engine Overheating');
                    },
                  ),
                  _RepairOptionTile(
                    label: 'Other',
                    onTap: () {
                      Navigator.pop(context);
                      context
                          .push('/create-request?problem=Minor Repair - Other');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProblemTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepairOptionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RepairOptionTile({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
