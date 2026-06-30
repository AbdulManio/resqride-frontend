import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/request_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _numberPlateController = TextEditingController();

  bool _isShopOwner = false;
  bool _isLoading = false;
  String? _selectedVehicleType;
  final Map<String, String> _uploadedFiles = {};
  final Set<String> _selectedServices = {};
  final ImagePicker _picker = ImagePicker();

  final List<String> _vehicleTypes = [
    'Bike',
    'Rickshaw',
    'Car',
    'SUV',
    'Van',
    'Truck',
    'Other',
  ];

  Future<void> _pickDocument(String key, String docType) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Upload $docType',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() => _uploadedFiles[key] = photo.path);
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() => _uploadedFiles[key] = image.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _uploadDocuments() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiService.baseUrl}/users/upload-documents');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (_uploadedFiles.containsKey('cnic_front')) {
        request.files.add(await http.MultipartFile.fromPath(
          'cnicPhoto',
          _uploadedFiles['cnic_front']!,
        ));
      }

      if (_uploadedFiles.containsKey('registration')) {
        request.files.add(await http.MultipartFile.fromPath(
          'licensePhoto',
          _uploadedFiles['registration']!,
        ));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Upload error: $e');
      return false;
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one service'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // CNIC always required
    if (!_uploadedFiles.containsKey('cnic_front')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload your CNIC photo'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Registration only required for non-shop owners
    if (!_isShopOwner && !_uploadedFiles.containsKey('registration')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload your Vehicle Registration'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading documents...')),
    );

    final uploadSuccess = await _uploadDocuments();

    if (!uploadSuccess) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload documents. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Build vehicle info string
    String vehicleInfo = '';
    if (_isShopOwner) {
      vehicleInfo = _shopNameController.text;
    } else {
      vehicleInfo =
          '${_selectedVehicleType ?? ''} ${_vehicleModelController.text} - ${_numberPlateController.text}';
    }

    final response = await RescuerService.setupProfile(
      services: _selectedServices.toList(),
      isShopOwner: _isShopOwner,
      vehicleInfo: vehicleInfo,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile submitted for approval! ✅'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/account-status');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Submission failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescuer Profile Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Shop Owner Toggle ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Do you own a shop?',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Toggle if you operate from a fixed location',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Switch(
                      value: _isShopOwner,
                      onChanged: (value) =>
                          setState(() => _isShopOwner = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                _isShopOwner ? 'Shop Details' : 'Vehicle Details',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ─── Shop Details ──────────────────────────────────────────
              if (_isShopOwner) ...[
                TextFormField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter shop name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shopAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Shop Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter shop address'
                      : null,
                ),
              ],

              // ─── Vehicle Details ──────────────────────────────────────
              if (!_isShopOwner) ...[
                // Vehicle Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: _vehicleTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedVehicleType = value),
                  validator: (value) =>
                      value == null ? 'Please select vehicle type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Make/Model (e.g., Honda CD70)',
                    prefixIcon: Icon(Icons.car_repair),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter vehicle model'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numberPlateController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number Plate (e.g., ABC-123)',
                    prefixIcon: Icon(Icons.pin),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter number plate'
                      : null,
                ),
              ],

              // ─── Services ─────────────────────────────────────────────
              const SizedBox(height: 32),
              const Text('Services You Provide',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Select all that apply',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ServiceChip(
                    label: 'Puncture Repair',
                    icon: Icons.tire_repair,
                    isSelected: _selectedServices.contains('Puncture Repair'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('Puncture Repair')
                        : _selectedServices.remove('Puncture Repair')),
                  ),
                  _ServiceChip(
                    label: 'Fuel Delivery',
                    icon: Icons.local_gas_station,
                    isSelected: _selectedServices.contains('Fuel Delivery'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('Fuel Delivery')
                        : _selectedServices.remove('Fuel Delivery')),
                  ),
                  _ServiceChip(
                    label: 'Battery Jump',
                    icon: Icons.battery_charging_full,
                    isSelected: _selectedServices.contains('Battery Jump'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('Battery Jump')
                        : _selectedServices.remove('Battery Jump')),
                  ),
                  _ServiceChip(
                    label: 'Minor Repair',
                    icon: Icons.build,
                    isSelected: _selectedServices.contains('Minor Repair'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('Minor Repair')
                        : _selectedServices.remove('Minor Repair')),
                  ),
                  _ServiceChip(
                    label: 'Towing',
                    icon: Icons.car_repair,
                    isSelected: _selectedServices.contains('Towing'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('Towing')
                        : _selectedServices.remove('Towing')),
                  ),
                  _ServiceChip(
                    label: 'Engine Repair',
                    icon: Icons.engineering,
                    isSelected: _selectedServices.contains('Engine Repair'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('Engine Repair')
                        : _selectedServices.remove('Engine Repair')),
                  ),
                  _ServiceChip(
                    label: 'AC Repair',
                    icon: Icons.air,
                    isSelected: _selectedServices.contains('AC Repair'),
                    onSelected: (s) => setState(() => s
                        ? _selectedServices.add('AC Repair')
                        : _selectedServices.remove('AC Repair')),
                  ),
                ],
              ),

              // ─── Documents ────────────────────────────────────────────
              const SizedBox(height: 32),
              const Text('Identity Verification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // CNIC always required
              _DocumentUploadTile(
                title: 'Upload CNIC Photo *',
                subtitle: 'Required for all rescuers',
                icon: Icons.badge_outlined,
                isUploaded: _uploadedFiles.containsKey('cnic_front'),
                fileName: _uploadedFiles['cnic_front'],
                onTap: () => _pickDocument('cnic_front', 'CNIC'),
              ),
              const SizedBox(height: 12),

              // Registration only for non-shop owners
              if (!_isShopOwner) ...[
                _DocumentUploadTile(
                  title: 'Upload Vehicle Registration *',
                  subtitle: 'Required for vehicle-based rescuers',
                  icon: Icons.description_outlined,
                  isUploaded: _uploadedFiles.containsKey('registration'),
                  fileName: _uploadedFiles['registration'],
                  onTap: () =>
                      _pickDocument('registration', 'Vehicle Registration'),
                ),
              ] else ...[
                _DocumentUploadTile(
                  title: 'Upload Shop License (Optional)',
                  subtitle: 'Business registration or license',
                  icon: Icons.store_outlined,
                  isUploaded: _uploadedFiles.containsKey('registration'),
                  fileName: _uploadedFiles['registration'],
                  onTap: () => _pickDocument('registration', 'Shop License'),
                ),
              ],

              // ─── Submit Button ────────────────────────────────────────
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit for Approval',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Function(bool) onSelected;

  const _ServiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(icon,
          size: 18, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      backgroundColor: AppColors.primary.withAlpha(26),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.primary.withAlpha(77),
        width: 1,
      ),
    );
  }
}

class _DocumentUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isUploaded;
  final String? fileName;
  final VoidCallback onTap;

  const _DocumentUploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isUploaded,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isUploaded ? AppColors.primary : Colors.grey[300]!,
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isUploaded ? AppColors.primary.withAlpha(13) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isUploaded ? AppColors.primary : AppColors.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUploaded ? '✅ $title' : title,
                    style: TextStyle(
                      color: isUploaded
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isUploaded ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isUploaded ? 'Uploaded successfully' : subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUploaded ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isUploaded ? Icons.check_circle : Icons.file_upload_outlined,
              color: isUploaded ? Colors.green : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
