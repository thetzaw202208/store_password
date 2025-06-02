import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/password_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import './image_generator.dart';

class BackupService {
  // Your configured bot token
  //static const String _botToken = '7875039984:AAF6spkYYyZKxf3isAVRYs1IrZIf0jDrwXc';
  
  // Your configured chat ID
  //static const String _chatId = '1819178005';

  // Timeout duration
  static const _timeout = Duration(seconds: 30);
  
  static Future<({bool success, String message})> backupToTelegramAndStorage(List<Password> passwords, PasswordProvider provider) async {
    File? tempFile;
    File? imageFile;
    //bool telegramSuccess = false;
    bool storageSuccess = false;

    try {
      // Create backup content with decrypted passwords
      final backupContent = await _createBackupContent(passwords, provider);

      // Try Telegram backup first with image
      // try {
      //   imageFile = await ImageGenerator.createPasswordTable(passwords, provider);
      //   if (imageFile != null) {
      //     telegramSuccess = await _sendImageToTelegram(imageFile).timeout(_timeout);
      //   }
      // } catch (e) {
      //   debugPrint('Image backup to Storage failed: $e');
      // }

      // Try local storage backup with JSON
      try {
        final downloadDir = await _getDownloadDirectory();
        if (downloadDir != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final backupFile = File(path.join(downloadDir.path, 'password_backup_$timestamp.json'));
          await backupFile.writeAsString(backupContent);
          storageSuccess = true;
        }
      } catch (e) {
        debugPrint('Local storage backup failed: $e');
      }

      // Return combined result
      // if (telegramSuccess && storageSuccess) {
      //   return (success: true, message: 'Backup successful to  Storage');
      // } else if (telegramSuccess) {
      //   return (success: true, message: 'Backup successful to Storage');
      // } else
        if (storageSuccess) {
        return (success: true, message: 'Backup successful to Storage ');
      } else {
        return (success: false, message: 'Backup failed for  Storage');
      }

    } catch (e) {
      debugPrint('Backup error: $e');
      return (success: false, message: 'Error during backup: ${e.toString()}');
    } finally {
      // Clean up temporary files
      await _cleanupTempFile(tempFile);
      //await _cleanupTempFile(imageFile);
    }
  }

  static Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      Directory? directory;
      
      // Try to get the Downloads directory
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        debugPrint('Error accessing download directory: $e');
        try {
          directory = await getExternalStorageDirectory();
        } catch (e) {
          debugPrint('Error accessing external storage: $e');
          return null;
        }
      }
      
      return directory;
    } else if (Platform.isIOS) {
      // For iOS, we'll use the Documents directory
      try {
        return await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('Error accessing documents directory: $e');
        return null;
      }
    }
    
    return null;
  }
  
  static Future<String> _createBackupContent(List<Password> passwords, PasswordProvider provider) async {
    // Get all categories and create a map of their IDs to names
    final categories = provider.categories;
    final Map<String, String> categoryMap = {
      for (var c in categories) 
      c.id.toString(): c.name
    };
    
    // Create simple list of password data
    final List<Map<String, String>> passwordList = passwords.map((password) {
      final decryptedPassword = provider.getOriginalPassword(password.id!);
      final categoryName = categoryMap[password.categoryId.toString()] ?? 'Unknown';
      
      return {
        'userName': password.username,
        'password': decryptedPassword,
        'category': categoryName,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }).toList();
    
    // Convert to JSON with pretty printing
    return const JsonEncoder.withIndent('  ').convert(passwordList);
  }

  // static Future<bool> _sendImageToTelegram(File imageFile) async {
  //   final client = http.Client();
  //   try {
  //     final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendPhoto');
  //
  //     final request = http.MultipartRequest('POST', url)
  //       ..fields['chat_id'] = _chatId
  //       ..files.add(
  //         await http.MultipartFile.fromPath(
  //           'photo',
  //           imageFile.path,
  //         ),
  //       );
  //
  //     final streamedResponse = await request.send().timeout(_timeout);
  //     final response = await http.Response.fromStream(streamedResponse);
  //
  //     if (response.statusCode != 200) {
  //       debugPrint('Telegram API error: ${response.body}');
  //       return false;
  //     }
  //
  //     return true;
  //   } catch (e) {
  //     debugPrint('Error sending image to Telegram: $e');
  //     return false;
  //   } finally {
  //     client.close();
  //   }
  // }

  static Future<void> _cleanupTempFile(File? file) async {
    if (file != null) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    }
  }
} 