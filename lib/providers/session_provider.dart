import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class SessionProvider with ChangeNotifier {
  Timer? _inactivityTimer;
  bool _isAuthenticated = false;
  final Duration _timeoutDuration = const Duration(minutes: 1);

  bool get isAuthenticated => _isAuthenticated;

  SessionProvider() {
    // Timer is started explicitly after successful initial auth
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () {
      _isAuthenticated = false;
      notifyListeners();
    });
  }

  // This method is called after primary authentication is successful
  void startSession() {
    if (_isAuthenticated) return; // Prevent starting if already authenticated

    _isAuthenticated = true;
    _resetTimer(); // Start the timer now
    notifyListeners(); // Notify listeners that session is now authenticated
  }

  // Method to explicitly end the session (e.g., on manual logout)
  void endSession() {
    _inactivityTimer?.cancel();
    _isAuthenticated = false;
    notifyListeners();
  }

  void updateActivity() {
    if (!_isAuthenticated) return;
    _resetTimer();
  }

  // This method is for re-authenticating an expired session
  Future<bool> authenticateSession(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final availableBiometrics = await authProvider.getAvailableBiometrics();
    
    bool authenticated = false;

    if (availableBiometrics.isNotEmpty) {
      authenticated = await authProvider.authenticateWithBiometrics(context);
    }

    // If biometric failed or not available, try PIN (if PIN exists and is set up)
    if (!authenticated) {
       authenticated = await _showPinDialog(context);
    }
    
    if (authenticated) {
      _isAuthenticated = true;
      _resetTimer(); // Restart timer after re-authentication
      notifyListeners(); // Notify listeners that session is re-authenticated
    }
    return authenticated;
  }

  Future<bool> _showPinDialog(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();
    bool? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: pinController,
          decoration: const InputDecoration(
            hintText: 'Enter your PIN',
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () {
              pinController.clear();
              Navigator.of(context).pop();
              result = false;
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final pin = pinController.text;
              pinController.clear();
              Navigator.of(context).pop();
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              result = await authProvider.authenticateWithPIN(pin, context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
} 