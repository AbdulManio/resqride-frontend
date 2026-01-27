import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isShopOwner = false;
  final Map<String, String> _uploadedFiles = {};
  final Set<String> _selectedServices = {};
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDocument(String key, String docType) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo =
                    await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() {
                    _uploadedFiles[key] = photo.path;
                  });
                  if (mounted) {
                    // Use BuildContext from mounted state
                    final contextRef = context;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(contextRef).showSnackBar(
                          SnackBar(
                              content: Text('$docType uploaded successfully')),
                        );
                      }
                    });
                  }
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
                  setState(() {
                    _uploadedFiles[key] = image.path;
                  });
                  if (mounted) {
                    // Use BuildContext from mounted state
                    final contextRef = context;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(contextRef).showSnackBar(
                          SnackBar(
                              content: Text('$docType uploaded successfully')),
                        );
                      }
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Do you own a shop?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _isShopOwner,
                    onChanged: (value) => setState(() => _isShopOwner = value),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _isShopOwner ? 'Shop Details' : 'Vehicle Details',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: _isShopOwner
                      ? 'Shop Name'
                      : 'Vehicle Type (e.g., Bike, Car)',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter ${_isShopOwner ? "shop name" : "vehicle type"}'
                    : null,
              ),
              const SizedBox(height: 16),
              if (!_isShopOwner)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText:
                        'Vehicle Make/Model (e.g., Honda City, Suzuki GSX)',
                    hintText: 'Enter vehicle brand and model',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter vehicle make/model'
                      : null,
                ),
              if (!_isShopOwner) const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText:
                      _isShopOwner ? 'Shop Address' : 'Vehicle Number Plate',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter ${_isShopOwner ? "address" : "number plate"}'
                    : null,
              ),
              const SizedBox(height: 32),
              const Text(
                'Services You Provide',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ServiceChip(
                    label: 'Puncture Repair',
                    icon: Icons.tire_repair,
                    isSelected: _selectedServices.contains('Puncture Repair'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add('Puncture Repair');
                        } else {
                          _selectedServices.remove('Puncture Repair');
                        }
                      });
                    },
                  ),
                  _ServiceChip(
                    label: 'Fuel Delivery',
                    icon: Icons.local_gas_station,
                    isSelected: _selectedServices.contains('Fuel Delivery'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add('Fuel Delivery');
                        } else {
                          _selectedServices.remove('Fuel Delivery');
                        }
                      });
                    },
                  ),
                  _ServiceChip(
                    label: 'Battery Jump',
                    icon: Icons.battery_charging_full,
                    isSelected: _selectedServices.contains('Battery Jump'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add('Battery Jump');
                        } else {
                          _selectedServices.remove('Battery Jump');
                        }
                      });
                    },
                  ),
                  _ServiceChip(
                    label: 'Minor Repair',
                    icon: Icons.build,
                    isSelected: _selectedServices.contains('Minor Repair'),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedServices.add('Minor Repair');
                        } else {
                          _selectedServices.remove('Minor Repair');
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Identity Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CNIC Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter CNIC';
                  }
                  if (value.length != 13) return 'CNIC must be 13 digits';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _DocumentUploadTile(
                title: 'Upload CNIC Front',
                icon: Icons.badge_outlined,
                isUploaded: _uploadedFiles.containsKey('cnic_front'),
                fileName: _uploadedFiles['cnic_front'],
                onTap: () => _pickDocument('cnic_front', 'CNIC Front'),
              ),
              const SizedBox(height: 12),
              _DocumentUploadTile(
                title: 'Upload CNIC Back',
                icon: Icons.badge_outlined,
                isUploaded: _uploadedFiles.containsKey('cnic_back'),
                fileName: _uploadedFiles['cnic_back'],
                onTap: () => _pickDocument('cnic_back', 'CNIC Back'),
              ),
              const SizedBox(height: 12),
              _DocumentUploadTile(
                title: _isShopOwner
                    ? 'Upload Shop License'
                    : 'Upload Vehicle Registration',
                icon: Icons.description_outlined,
                isUploaded: _uploadedFiles.containsKey('registration'),
                fileName: _uploadedFiles['registration'],
                onTap: () => _pickDocument(
                  'registration',
                  _isShopOwner ? 'Shop License' : 'Vehicle Registration',
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_uploadedFiles.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please upload CNIC (front & back) and registration'),
                        ),
                      );
                      return;
                    }
                    context.go('/account-status');
                  }
                },
                child: const Text('Submit for Approval'),
              ),
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
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
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
  final IconData icon;
  final bool isUploaded;
  final String? fileName;
  final VoidCallback onTap;

  const _DocumentUploadTile({
    required this.title,
    required this.icon,
    required this.isUploaded,
    this.fileName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String displayText = title;
    if (isUploaded && fileName != null) {
      final name = fileName!.split('/').last;
      displayText =
          '$title (${name.length > 20 ? '${name.substring(0, 20)}...' : name})';
    }

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
            Icon(
              icon,
              color: isUploaded ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: isUploaded ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isUploaded ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isUploaded ? Icons.check_circle : Icons.file_upload_outlined,
              color: isUploaded ? AppColors.primary : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
