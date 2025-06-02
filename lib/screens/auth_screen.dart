import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:local_auth/local_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPINMode = false;

  @override
  void initState() {
    super.initState();
    _authenticateWithBiometrics();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final canCheckBiometrics = await authProvider.checkBiometrics();
    final availableBiometrics = await authProvider.getAvailableBiometrics();

    if (!canCheckBiometrics || availableBiometrics.isEmpty) {
      setState(() {
        _errorMessage = authProvider.lastError;
        _isPINMode = true;
        _isLoading = false;
      });
      return;
    }

    final success = await authProvider.authenticateWithBiometrics(context);
    if (!success && mounted) {
      setState(() {
        _errorMessage = authProvider.lastError;
        _isPINMode = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithPIN() async {
    if (_pinController.text.length != 6) {
      setState(() {
        _errorMessage = 'PIN must be 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final success = await Provider.of<AuthProvider>(context, listen: false)
        .authenticateWithPIN(_pinController.text, context);

    if (!success && mounted) {
      setState(() {
        _errorMessage = 'Invalid PIN';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:  EdgeInsets.only(left:30.w,right: 20.w,),
          child: Column(
           // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icons/logo.png',width: 220.w,height: 220.h,),
              // const Icon(
              //   Icons.lock_outline,
              //   size: 64,
              //   color: Colors.blue,
              // ),
               SizedBox(height: 20.h),
              const Text(
                'Password Manager',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
               SizedBox(height: 8.h),
              Text(
                _isPINMode
                    ? 'Enter your 6-digit PIN'
                    : 'Use biometric authentication to access your passwords',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
               SizedBox(height: 32.h),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_isPINMode) ...[
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '******',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                ),
                 SizedBox(height: 20.h),
                FutureBuilder<bool>(
                  future: Provider.of<AuthProvider>(context, listen: false).checkBiometrics(),
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        if (snapshot.hasData && snapshot.data == true)
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _authenticateWithBiometrics,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Use Biometrics'),
                            ),
                          ),
                        if (snapshot.hasData && snapshot.data == true)
                          const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _authenticateWithPIN,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Unlock with PIN'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_errorMessage.isNotEmpty) ...[
                   SizedBox(height: 20.h),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
} 