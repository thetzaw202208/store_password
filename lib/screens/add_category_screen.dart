import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/custom_text.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'all.png';

  final List<String> _availableIcons = [
    'all.png',
    'google.png',
    'facebook.png',
    'important.png',
    'very_imp.png',
    'personal.png',
    'work.png',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<PasswordProvider>(context, listen: false);
      provider.addCategory(_nameController.text, _selectedIcon);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SessionProvider>(context, listen: false).updateActivity();

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
            text:'Add Category',
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<SessionProvider>(context, listen: false).updateActivity();
                _saveCategory();
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<SessionProvider>(context, listen: false).updateActivity();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  return GestureDetector(
                    onTap: () {
                      Provider.of<SessionProvider>(context, listen: false).updateActivity();
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedIcon == icon ? Colors.blue : Colors.grey,
                          width: _selectedIcon == icon ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/icons/$icon',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 