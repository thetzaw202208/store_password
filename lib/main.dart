import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:store_password/screens/splash_screen.dart';
import 'providers/password_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/session_provider.dart';
import 'widgets/session_wrapper.dart';
// import 'screens/auth_screen.dart';
// import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => PasswordProvider()),
            ChangeNotifierProvider(create: (_) => SessionProvider()),
          ],
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Password Manager',
            theme: ThemeData.dark(useMaterial3: true),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}


