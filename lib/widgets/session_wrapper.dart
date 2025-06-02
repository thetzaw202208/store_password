import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:store_password/utils/color_const.dart';
import '../providers/session_provider.dart';
import '../providers/auth_provider.dart';
// import '../providers/auth_provider.dart'; // No longer need AuthProvider here

class SessionWrapper extends StatefulWidget {
  final Widget child;

  const SessionWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the app is resumed and AuthProvider is already authenticated,
      // the SessionWrapper will be built (or rebuilt) and the Consumer2
      // will check the SessionProvider state.
      // If SessionProvider is not authenticated (due to background timeout),
      // the expired screen will be shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SessionProvider>(
      builder: (context, authProvider, sessionProvider, child) {
        // If AuthProvider indicates successful primary authentication,
        // and SessionProvider indicates the session has expired (is not authenticated).
        if (authProvider.isAuthenticated && !sessionProvider.isAuthenticated) {
          // This is the session expired state, show the re-authentication screen.
          return Scaffold(
            // Use a dark background that fits the app theme
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  children: [
                    // Add a lock icon, using default color
                    // const Icon(
                    //   Icons.lock_outline,
                    //   size: 80,
                    //   // Removed color styling
                    // ),
                    Image.asset('assets/icons/logo.png',width: 220.w,height: 220.h,),
                     SizedBox(height: 24.h),
                    // Updated text for session expired
                     Text(
                      'Your session has expired due to inactivity. Please re-authenticate to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600, // Slightly less bold
                        color: Colors.white70, // Softer white
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Reverted to default ElevatedButton style
                    MaterialButton(
                      padding: EdgeInsets.symmetric(vertical:10.w,horizontal: 20.h),
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(
                          color: mainColor
                        )
                      ),
                      onPressed: () async {
                        // Attempt to re-authenticate the session.
                        await sessionProvider.authenticateSession(context);
                      },
                      child: Text('Re-authenticate',style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600, // Slightly less bold
                        color: Colors.white, // Softer white
                      ),),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // In all other cases (AuthProvider not authenticated - handled by AuthWrapper, 
        // or both authenticated - normal active session), show the child and track activity.
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => sessionProvider.updateActivity(),
          onPanUpdate: (_) => sessionProvider.updateActivity(),
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
} 