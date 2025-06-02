import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
   Future.delayed(const Duration(seconds: 2),(){
     if(mounted) {
       Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const AuthWrapper()),(Route<dynamic> route) => false );
     }
   });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(

        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/icons/logo.png'),
          // const Icon(
          //   Icons.lock_outline,
          //   size: 64,
          //   color: Colors.blue,
          // ),
          // const SizedBox(height: 20),
          //  Text(
          //   'Password Manager',
          //   style: TextStyle(
          //     fontSize: 20.sp,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          const SizedBox(height: 28),
          const Center(child: CircularProgressIndicator(color: Colors.white,))
        ],

      ),
    );
  }
}
