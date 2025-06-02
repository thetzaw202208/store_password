import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';
// import 'password_detail_screen.dart'; // Will use named routes
// import 'edit_password_screen.dart'; // Will use named routes
import '../providers/session_provider.dart';
import '../widgets/custom_text.dart'; // Import SessionProvider

class PasswordListScreen extends StatelessWidget {
  final Category category;

  const PasswordListScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    // Track user activity on this screen
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
            text:category.name,
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Consumer<PasswordProvider>(
          builder: (context, provider, _) {
            final passwords = provider.getPasswordsByCategory(category.id);

            if (passwords.isEmpty) {
              return const Center(
                child: Text('No passwords in this category'),
              );
            }

            if (category.id != 1) {
              // Original Regular list view for specific categories
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: passwords.length,
                itemBuilder: (context, index) {
                  final password = passwords[index];
                  return _buildPasswordCard(context, password, provider);
                },
              );
            }

            // Original Grouped list view for All category
            final categoryMap = {for (var c in provider.categories) c.id: c.name};
            final groupedPasswords = <String, List<Password>>{};

            // Group passwords by category
            for (var password in passwords) {
              String categoryName;
              if (password.categoryId == 1) {
                categoryName = 'Uncategorized'; // Special handling for category_id = 1
              } else {
                categoryName = categoryMap[password.categoryId] ?? 'Unknown';
              }

              if (!groupedPasswords.containsKey(categoryName)) {
                groupedPasswords[categoryName] = [];
              }
              groupedPasswords[categoryName]!.add(password);
            }

            // Create list items with headers
            final listItems = <Widget>[];

            // Sort categories alphabetically, but put Uncategorized at the end
            final sortedCategories = groupedPasswords.keys.toList()
              ..sort((a, b) {
                if (a == 'Uncategorized') return 1;
                if (b == 'Uncategorized') return -1;
                return a.compareTo(b);
              });

            for (var categoryName in sortedCategories) {
              final categoryPasswords = groupedPasswords[categoryName]!;

              // Add category header
              listItems.add(
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              );

              // Add passwords for this category
              listItems.addAll(
                categoryPasswords.map((password) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPasswordCard(context, password, provider),
                )),
              );
            }

            return ListView(
              children: listItems,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context, Password password, PasswordProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          password.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '•' * 8, // Show fixed-length dots for password
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        onTap: () {
          Provider.of<SessionProvider>(context, listen: false).updateActivity(); // Track activity
          // Use the nested Navigator for navigation with arguments
          Navigator.of(context).pushNamed(
            '/passwordDetail',
            arguments: {'password': password},
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button (re-added from original)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Provider.of<SessionProvider>(context, listen: false).updateActivity(); // Track activity
                // Use the nested Navigator for navigation with arguments
                Navigator.of(context).pushNamed(
                  '/editPassword',
                  arguments: {'password': password},
                );
              },
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                 Provider.of<SessionProvider>(context, listen: false).updateActivity(); // Track activity
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Password'),
                    content: Text('Are you sure you want to delete "${password.username}"?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                           Provider.of<SessionProvider>(context, listen: false).updateActivity(); // Track activity
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                           Provider.of<SessionProvider>(context, listen: false).updateActivity(); // Track activity
                          provider.deletePassword(password.id!);
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 