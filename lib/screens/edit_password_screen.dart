import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/password_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/custom_text.dart';

class EditPasswordScreen extends StatefulWidget {
  final Password password;

  const EditPasswordScreen({
    super.key,
    required this.password,
  });

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  final TextEditingController _pinController = TextEditingController();
  late int _selectedCategoryId;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.password.username);
    final provider = Provider.of<PasswordProvider>(context, listen: false);
    final originalPassword = provider.getOriginalPassword(widget.password.id!);
    _passwordController = TextEditingController(text: originalPassword);
    _selectedCategoryId = widget.password.categoryId;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _togglePasswordVisibility() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<SessionProvider>(context, listen: false).updateActivity();

    if (_isPasswordVisible) {
      // If password is visible, just hide it
      setState(() {
        _isPasswordVisible = false;
      });
      return;
    }

    // Check if biometrics are available
    final availableBiometrics = await authProvider.getAvailableBiometrics();

    if (!mounted) return;

    if (availableBiometrics.isNotEmpty) {
      // Use the local biometric authentication method
      final authenticated = await authProvider.authenticateWithBiometrics(context);

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _isPasswordVisible = true;
        });
      } else if (authProvider.lastError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.lastError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // If biometrics are not available, show PIN dialog
      await _showPinDialog();
    }
  }
  Future<void> _showPinDialog() async {
    return showDialog(
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
              Navigator.of(context).pop();

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              // Use the local PIN authentication method
              final authenticated = await authProvider.authenticateWithPIN(pin,context);

              if (!mounted) return;

              if (authenticated) {
                setState(() {
                  _isPasswordVisible = true;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid PIN'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _savePassword() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PasswordProvider>(context, listen: false);
      provider.updatePassword(
        widget.password.copyWith(
          username: _usernameController.text,
          password: _passwordController.text,
          categoryId: _selectedCategoryId,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SessionProvider>(context, listen: false).updateActivity();

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
        title: CustomText(
          text: 'Edit Password',
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<SessionProvider>(context, listen: false).updateActivity();
                _savePassword();
              },
              child: const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Consumer<PasswordProvider>(
                builder: (context, provider, _) {
                  Provider.of<SessionProvider>(context, listen: false).updateActivity();
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: provider.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      Provider.of<SessionProvider>(context, listen: false).updateActivity();
                      setState(() {
                        _selectedCategoryId = value!;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<SessionProvider>(context, listen: false).updateActivity();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      _togglePasswordVisibility();
                      // setState(() {
                      //   _isPasswordVisible = !_isPasswordVisible;
                      // });
                    },
                  ),
                ),
                onChanged: (value) {
                  Provider.of<SessionProvider>(context, listen: false).updateActivity();
                },
                obscureText: !_isPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      
    );
  }
} 