import 'package:flutter/material.dart';

enum UserRole { customer, rescuer, none }

class AuthProvider extends ChangeNotifier {
  UserRole _role = UserRole.none;
  bool _isLoggedIn = false;
  String? _name;
  String? _email;
  String? _phoneNumber;
  String? _address;
  String? _vehicleInfo;

  UserRole get role => _role;
  bool get isLoggedIn => _isLoggedIn;
  String? get name => _name;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  String? get address => _address;
  String? get vehicleInfo => _vehicleInfo;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void login({
    required String name,
    required String email,
    required String phoneNumber,
  }) {
    _name = name;
    _email = email;
    _phoneNumber = phoneNumber;
    _isLoggedIn = true;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? vehicleInfo,
  }) {
    if (name != null) _name = name;
    if (email != null) _email = email;
    if (phoneNumber != null) _phoneNumber = phoneNumber;
    if (address != null) _address = address;
    if (vehicleInfo != null) _vehicleInfo = vehicleInfo;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _role = UserRole.none;
    _name = null;
    _email = null;
    _phoneNumber = null;
    _address = null;
    _vehicleInfo = null;
    notifyListeners();
  }
}
