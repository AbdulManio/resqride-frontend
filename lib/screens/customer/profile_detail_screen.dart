import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class CustomerProfileDetailScreen extends StatefulWidget {
  const CustomerProfileDetailScreen({super.key});

  @override
  State<CustomerProfileDetailScreen> createState() =>
      _CustomerProfileDetailScreenState();
}

class _CustomerProfileDetailScreenState
    extends State<CustomerProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _vehicleController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: authProvider.name ?? 'Manav');
    _emailController =
        TextEditingController(text: authProvider.email ?? 'manav@example.com');
    _addressController =
        TextEditingController(text: authProvider.address ?? 'G-11, Islamabad');
    _vehicleController = TextEditingController(
        text: authProvider.vehicleInfo ?? 'Toyota Corolla (ABC-123)');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Profile Details')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.name ?? 'Manav',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  authProvider.email ?? 'manav@example.com',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _buildInfoTile(Icons.phone, 'Phone',
                    authProvider.phoneNumber ?? '+92 300 1234567'),
                _buildInfoTile(Icons.location_on, 'Home Address',
                    authProvider.address ?? 'G-11, Islamabad'),
                _buildInfoTile(Icons.directions_car, 'Vehicle',
                    authProvider.vehicleInfo ?? 'Toyota Corolla (ABC-123)'),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () =>
                      _showEditProfileDialog(context, authProvider),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(labelText: 'Vehicle Info'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                authProvider.updateProfile(
                  name: _nameController.text,
                  email: _emailController.text,
                  address: _addressController.text,
                  vehicleInfo: _vehicleController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
