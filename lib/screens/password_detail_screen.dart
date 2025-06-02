import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/custom_text.dart';

class PasswordDetailScreen extends StatefulWidget {
  final Password password;

  const PasswordDetailScreen({
    super.key,
    required this.password,
  });

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _isPasswordVisible = false;
  String? _originalPassword;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOriginalPassword();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _isPasswordVisible = false;
    super.dispose();
  }

  void _loadOriginalPassword() {
    final provider = Provider.of<PasswordProvider>(context, listen: false);
    setState(() {
      _originalPassword = provider.getOriginalPassword(widget.password.id!);
    });
  }

  Future<bool> _authenticateBeforeAction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<SessionProvider>(context, listen: false).updateActivity();

    // Check if biometrics are available
    final availableBiometrics = await authProvider.getAvailableBiometrics();

    if (!mounted) return false;

    if (availableBiometrics.isNotEmpty) {
      // If biometrics are available, use them
      final authenticated = await authProvider.authenticateWithBiometrics(context);
      if (!mounted) return false;
      return authenticated;
    } else {
      // If biometrics are not available, show PIN dialog and wait for result
      bool authenticatedByPin = false;
      await showDialog( // Use await here to wait for the dialog to close
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter PIN'),
          content: TextField(
            controller: _pinController,
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
                _pinController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final pin = _pinController.text;
                _pinController.clear();
                // Do not pop here yet, authenticate first

                final authenticated = await authProvider.authenticateWithPIN(pin, context);

                if (!mounted) return; // Check mounted after async operation

                if (authenticated) {
                  authenticatedByPin = true;
                  if(mounted) {
                  Navigator.of(context).pop(); // Pop only on success
                  }
                } else {
                   if (!mounted) return;
                   if(mounted) {
                     Navigator.of(context).pop();
                     ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid PIN'),
                      backgroundColor: Colors.red,
                    ),
                  );
                   }
                   // Keep dialog open on failure, user has to press Cancel
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return authenticatedByPin; // Return the result of PIN auth
    }
  }

  Future<void> _togglePasswordVisibility() async {
    // If password is already visible, just hide it without authentication
    if (_isPasswordVisible) {
      setState(() {
        _isPasswordVisible = false;
      });
      // Update session activity when user interacts with the toggle, even to hide
      Provider.of<SessionProvider>(context, listen: false).updateActivity();
      return; // Exit the function
    }

    // If password is not visible, proceed with authentication
    final authenticated = await _authenticateBeforeAction();

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _isPasswordVisible = true; // Set to visible on successful authentication
      });
    } else {
       // Authentication failed, _authenticateBeforeAction might show a message
       // No need for extra message here unless desired
    }
  }

  Future<void> _copyPassword() async {
    final authenticated = await _authenticateBeforeAction(); // Authenticate before copying

    if (!mounted) return;

    if (authenticated && _originalPassword != null) {
      await Clipboard.setData(ClipboardData(text: _originalPassword!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (!authenticated) {
       // Authentication failed, _authenticateBeforeAction would have shown an error if needed
       // Or you could show a generic failure message here if desired
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title:CustomText(
            text:'Password Details',
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Provider.of<SessionProvider>(context, listen: false).updateActivity();
                // Use the nested Navigator for navigation with arguments
                Navigator.of(context).pushNamed(
                  '/editPassword',
                  arguments: {'password': widget.password},
                ).then((_) {
                  // Reload password after editing
                  _loadOriginalPassword();
                });
              },
            ),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Username',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.password.username,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Provider.of<SessionProvider>(context, listen: false).updateActivity();
                                  Clipboard.setData(
                                    ClipboardData(text: widget.password.username),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Username copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isPasswordVisible
                                      ? _originalPassword!
                                      : '•' * _originalPassword!.length,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (authProvider.isAuthenticating)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: _copyPassword,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 