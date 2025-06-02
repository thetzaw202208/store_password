import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/password_provider.dart';
import '../providers/session_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'password_list_screen.dart';
import 'password_detail_screen.dart';
import 'settings_screen.dart';
import 'add_password_screen.dart';
import 'add_category_screen.dart';
import 'edit_password_screen.dart';
import '../widgets/session_wrapper.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If not initially authenticated, show the AuthScreen
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // If initially authenticated, show the SessionWrapper which wraps the Navigator
        // for the rest of the app screens.
        return const SessionWrapper(
          child: _AuthenticatedNavigator(), // Use a dedicated widget for the nested Navigator
        );
      },
    );
  }
}

// Define a separate widget for the Navigator containing authenticated screens
class _AuthenticatedNavigator extends StatelessWidget {
  const _AuthenticatedNavigator();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable hardware back button
      child: Navigator(
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/passwordList':
              final args = settings.arguments as Map<String, dynamic>;
              final category = args['category'] as Category;
              return MaterialPageRoute(builder: (_) => PasswordListScreen(category: category));
            case '/passwordDetail':
              final args = settings.arguments as Map<String, dynamic>;
              final password = args['password'] as Password;
              return MaterialPageRoute(builder: (_) => PasswordDetailScreen(password: password));
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/addPassword':
              return MaterialPageRoute(builder: (_) => const AddPasswordScreen());
            case '/addCategory':
              return MaterialPageRoute(builder: (_) => const AddCategoryScreen());
            case '/editPassword':
               final args = settings.arguments as Map<String, dynamic>;
              final password = args['password'] as Password;
              return MaterialPageRoute(builder: (_) => EditPasswordScreen(password: password));
            default:
              return MaterialPageRoute(builder: (_) => const HomeScreen()); // Fallback
          }
        },
      ),
    );
  }
}