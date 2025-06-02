import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:store_password/screens/privacy_policy_screen.dart';
import 'package:store_password/widgets/custom_text.dart';
import '../providers/password_provider.dart';
import '../services/backup_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Directory, Platform;
import '../providers/session_provider.dart';
import '../widgets/custom_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            text:'Settings',
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           Padding(
             padding:  EdgeInsets.all(8.w),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const CustomText(text: 'General',color: Colors.white,),
                 GestureDetector(
                   onTap: () {
                     Get.to(() => const PrivacyPolicyScreen());
                   },
                   child: Padding(
                     padding:  EdgeInsets.symmetric(horizontal:7.w,vertical: 3.h),
                     child: CustomCard(

                       color: Colors.grey[900],
                       widget: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Row(
                             children: [
                               Icon(Icons.privacy_tip_outlined,
                                   size: 18.sp, color: Colors.white),
                               SizedBox(
                                 width: 10.w,
                               ),
                               CustomText(text: 'Privacy Policy'.tr, color: Colors.white)
                             ],
                           ),
                           Icon(Icons.arrow_forward_ios,
                               size: 18.sp, color: Colors.white),
                         ],
                       ),
                     ),
                   ),
                 ),

                 GestureDetector(
                   onTap: () {

                   },
                   child: Padding(
                     padding:  EdgeInsets.all(7.w),
                     child: CustomCard(

                       color: Colors.grey[900],
                       widget: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Row(
                             children: [
                               Icon(Icons.info_outline,
                                   size: 18.sp, color: Colors.white),
                               SizedBox(
                                 width: 10.w,
                               ),
                               CustomText(text: 'App Version'.tr, color: Colors.white)
                             ],
                           ),
                           CustomText(text: '1.0.0',color: Colors.white,)
                         ],
                       ),
                     ),
                   ),
                 ),
                 SizedBox(height: 10.h,),
                 const CustomText(text: 'Others',color: Colors.white,),
                 FutureBuilder<String>(
                   future: _getBackupPath(),
                   builder: (context, snapshot) {
                     String subtitle = 'Backup passwords to Storage';
                     if (snapshot.hasData) {
                       subtitle += '\nPath: ${snapshot.data}';
                     }

                     // Restored original UI for Backup
                     return InkWell(
                       onTap: () {
                         Provider.of<SessionProvider>(context, listen: false).updateActivity(); // Track activity
                         _backupPasswords(context);
                       },
                       child: Container(
                         decoration: BoxDecoration(
                           color: Colors.grey[900],
                           borderRadius: BorderRadius.circular(10),
                         ),
                         margin:  EdgeInsets.all(10.w),
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.center,
                           children: [
                             Container(
                               margin: const EdgeInsets.only(right: 16),
                               child: const Icon(
                                 Icons.backup,
                                 size: 28,
                                 color: Colors.grey,
                               ),
                             ),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   const Text(
                                     'Backup Passwords',
                                     style: TextStyle(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                   const SizedBox(height: 4),
                                   Text(
                                     subtitle,
                                     style: const TextStyle(
                                       fontSize: 14,
                                       color: Colors.grey,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ),
                     );
                   },
                 ),
               ],
             ),
           ),
            Padding(
              padding:  EdgeInsets.only(left:8.w,right: 8.w,top: 8.h,bottom: 8.h+MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
              CustomText(text: 'Follow and Subscribe at',textAlign: TextAlign.center,color: Colors.white,),
                 SizedBox(height: 10.h,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialIcon('assets/icons/youtube.png', () {
                         _launchUrl('https://www.youtube.com/@CodeVanceStudios');
                      },40.w,40.h),
                      _buildSocialIcon('assets/icons/facebook.png', () {
                         _launchUrl('https://www.facebook.com/profile.php?id=61557923971876');
                      },32.w,32.h),
                      _buildSocialIcon('assets/icons/whatsapp.png', () {
                         _launchUrl('https://wa.me/+959965398009');
                      },35.w,35.h),
                      _buildSocialIcon('assets/icons/telegram.png', () {
                         _launchUrl('https://t.me/tzlOfficial');
                      },32.w,32.h),
                    ],
                  ),
                ],
              ),
            )


          ],
        ),
      ),
    );

  }
  Widget _buildSocialIcon(String icon, VoidCallback onTap,double width,double height) {
    return InkWell(
      onTap: onTap,
      child: Image.asset(
        icon,
        width: width,
        height: height,
      ),
    );
  }
  Future<String> _getBackupPath() async {
    Directory? directory;
    if (Platform.isAndroid) {
      // Attempt to get the Downloads directory first, like in BackupService
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to getExternalStorageDirectory() if Downloads is not accessible
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        debugPrint('Error accessing download directory for display: $e');
        // Fallback to getExternalStorageDirectory() on error
        try {
          directory = await getExternalStorageDirectory();
        } catch (e) {
          debugPrint('Error accessing external storage for display: $e');
          return 'N/A'; // Return N/A if both fail
        }
      }
    } else if (Platform.isIOS) {
      // For iOS, use the Documents directory
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('Error accessing documents directory for display: $e');
        return 'N/A'; // Return N/A on error
      }
    }

    return directory?.path ?? 'N/A';
  }

  Future<void> _backupPasswords(BuildContext context) async {
    // Show loading indicator
    // Capture the dialog context from the builder
    BuildContext dialogContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context; // Assign the dialog context
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Backing up...'),
            ],
          ),
        );
      }
    );

    try {
      final passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
      // Call the existing backup method in BackupService
      final result = await BackupService.backupToTelegramAndStorage(passwordProvider.passwords, passwordProvider);

      // Hide loading indicator using the dialog context
      if (dialogContext.mounted) {
         Navigator.of(dialogContext).pop();
      }

      // Show result
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      // Hide loading indicator if visible using the dialog context
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // Show error
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw 'Could not launch $urlString';
    }
  }

  // Commented out as corresponding methods are not available in BackupService
  // Future<void> _restorePasswords(BuildContext context) async {
  //   // Implementation for restoring passwords
  // }

  // Future<void> _exportPasswords(BuildContext context) async {
  //   // Implementation for exporting passwords
  // }
} 