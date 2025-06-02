import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'session_provider.dart';

class AuthProvider with ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String _lastError = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthenticating => _isAuthenticating;
  String get lastError => _lastError;

  Future<bool> checkBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = await _localAuth.isDeviceSupported();
      debugPrint('Can check biometrics: $canCheckBiometrics');
      debugPrint('Device supports biometrics: $canAuthenticate');
      return canCheckBiometrics && canAuthenticate;
    } on PlatformException catch (e) {
      _lastError = 'Error checking biometrics: ${e.message}';
      debugPrint(_lastError);
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('Available biometrics: $availableBiometrics');
      if(availableBiometrics.isEmpty) {
        _lastError = 'No available biometrics';
      }
      return availableBiometrics;
    } on PlatformException catch (e) {
      _lastError = 'Error getting available biometrics: ${e.message}';
      debugPrint(_lastError);
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics(BuildContext context) async {
    if (_isAuthenticating) {
      return false;
    }

    try {
      setState(() {
        _isAuthenticating = true;
        _lastError = '';
      });

      // Check if device supports biometric authentication
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !canAuthenticate) {
        _lastError = 'Device does not support biometric authentication';
        return false;
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _lastError = 'No biometrics enrolled on this device';
        return false;
      }

      // Attempt authentication
      _isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to view the password',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (_isAuthenticated) {
        // Start session timer after successful primary authentication
        Provider.of<SessionProvider>(context, listen: false).startSession();
      } else {
        _lastError = 'Authentication failed';
      }

      return _isAuthenticated;
    } on PlatformException catch (e) {
      _lastError = 'Authentication error: ${e.message}';
      debugPrint(_lastError);
      return false;
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<bool> authenticateWithPIN(String pin, BuildContext context) async {
    try {
      setState(() {
        _isAuthenticating = true;
        _lastError = '';
      });

      final storedPin = await _secureStorage.read(key: 'pin');
      if (storedPin == null) {
        // First time setup
        await _secureStorage.write(key: 'pin', value: pin);
        _isAuthenticated = true;
        Provider.of<SessionProvider>(context, listen: false).startSession(); // Start session after setup
        notifyListeners();
        return true;
      }

      _isAuthenticated = storedPin == pin;
      if (_isAuthenticated) {
         Provider.of<SessionProvider>(context, listen: false).startSession(); // Start session after successful PIN auth
      } else {
        _lastError = 'Invalid PIN';
      }
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      _lastError = 'PIN authentication error: $e';
      return false;
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> setPIN(String pin) async {
    await _secureStorage.write(key: 'pin', value: pin);
  }

  void logout() {
    setState(() {
      _isAuthenticated = false;
      _isAuthenticating = false;
      _lastError = '';
    });
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
} 