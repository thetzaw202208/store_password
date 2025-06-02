import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:store_password/utils/color_const.dart';
import '../providers/password_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PasswordProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Provider.of<SessionProvider>(context, listen: false).updateActivity();
    }
  }

  // Method to show the exit confirmation dialog
  Future<bool> _onWillPop(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Exit'),
          content: const Text('Do you really want to exit the app?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Exit'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      exit(0);
    }
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    double bottomHeight = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: () => Provider.of<SessionProvider>(context, listen: false).updateActivity(),
      onPanUpdate: (_) => Provider.of<SessionProvider>(context, listen: false).updateActivity(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Passwords'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Provider.of<SessionProvider>(context, listen: false).updateActivity();
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer<PasswordProvider>(
                    builder: (context, provider, _) => TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Categories',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      onChanged: (value) {
                        provider.setSearchQuery(value);
                        Provider.of<SessionProvider>(context, listen: false).updateActivity();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer<PasswordProvider>(
                    builder: (context, provider, _) {
                      final filteredCategories = provider.getFilteredCategories();
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          final passwordCount = provider.getPasswordsByCategory(category.id).length;
                          return GestureDetector(
                            onTap: () {
                              Provider.of<SessionProvider>(context, listen: false).updateActivity();
                              Navigator.of(context).pushNamed(
                                '/passwordList',
                                arguments: {'category': category},
                              );
                            },
                            onLongPress: () {
                              Provider.of<SessionProvider>(context, listen: false).updateActivity();
                              _showDeleteCategoryDialog(context, category);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icons/${category.icon}',
                                    width: 50,
                                    height: 50,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$passwordCount passwords',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.all(15.w),
                child: Container(
                  padding: EdgeInsets.only(left: 16.w, bottom: 8.h , right: 16.w, top: 10.h),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Provider.of<SessionProvider>(context, listen: false).updateActivity();
                            Navigator.of(context).pushNamed('/addCategory');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.category),
                              SizedBox(width: 8),
                              Text(
                                'Add Category',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Provider.of<SessionProvider>(context, listen: false).updateActivity();
                            Navigator.of(context).pushNamed('/addPassword');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.password),
                              SizedBox(width: 8),
                              Text(
                                'Add Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show the delete confirmation dialog
  void _showDeleteCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Category?'),
          content: Text('Are you sure you want to delete the category \'${category.name}\'? All associated passwords will also be deleted.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                // Call the delete function in PasswordProvider
                Provider.of<PasswordProvider>(context, listen: false).deleteCategory(category.id);
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
          ],
        );
      },
    );
  }
}