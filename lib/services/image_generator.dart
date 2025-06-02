import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/password_provider.dart';

class ImageGenerator {
  static Future<File?> createPasswordTable(List<Password> passwords, PasswordProvider provider) async {
    try {
      final categories = provider.categories;
      final categoryMap = {for (var c in categories) c.id.toString(): c.name};
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw white background
      final paint = Paint()..color = Colors.white;
      final size = _calculateTableSize(passwords.length);
      canvas.drawRect(Offset.zero & size, paint);
      
      // Draw table
      final cellHeight = 40.0;
      final headerHeight = 60.0;
      final cellPadding = 8.0;
      final headerStyle = ui.TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );
      final cellStyle = ui.TextStyle(
        color: Colors.black,
        fontSize: 14,
      );
      
      // Draw header background
      paint.color = const Color(0xFFE0E0E0);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, headerHeight), paint);
      
      // Draw grid lines
      paint.color = Colors.black;
      paint.strokeWidth = 1.0;
      paint.style = PaintingStyle.stroke;
      
      // Vertical lines
      final columnWidth = size.width / 3;
      for (var i = 0; i <= 3; i++) {
        canvas.drawLine(
          Offset(i * columnWidth, 0),
          Offset(i * columnWidth, size.height),
          paint
        );
      }
      
      // Horizontal lines
      var y = 0.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += headerHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      
      for (var i = 0; i < passwords.length; i++) {
        y += cellHeight;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      
      // Draw header text
      final headers = ['Category', 'UserName', 'Password'];
      for (var i = 0; i < headers.length; i++) {
        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ))..pushStyle(headerStyle)
          ..addText(headers[i]);
        
        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: columnWidth - (cellPadding * 2)));
        
        canvas.drawParagraph(
          paragraph,
          Offset(i * columnWidth + cellPadding, cellPadding)
        );
      }
      
      // Draw data
      y = headerHeight;
      for (var password in passwords) {
        final decryptedPassword = provider.getOriginalPassword(password.id!);
        final categoryName = categoryMap[password.categoryId.toString()] ?? 'Unknown';
        final rowData = [categoryName, password.username, decryptedPassword];
        
        for (var i = 0; i < rowData.length; i++) {
          final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
            fontSize: 14,
          ))..pushStyle(cellStyle)
            ..addText(rowData[i]);
          
          final paragraph = paragraphBuilder.build()
            ..layout(ui.ParagraphConstraints(width: columnWidth - (cellPadding * 2)));
          
          canvas.drawParagraph(
            paragraph,
            Offset(i * columnWidth + cellPadding, y + cellPadding)
          );
        }
        
        y += cellHeight;
      }
      
      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      
      final bytes = byteData.buffer.asUint8List();
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/backup_table_$timestamp.png');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Error creating table image: $e');
      return null;
    }
  }

  static Size _calculateTableSize(int rowCount) {
    // Base size for header
    const baseHeight = 60.0;
    // Height per row
    const rowHeight = 40.0;
    // Fixed width
    const width = 600.0;
    
    // Calculate total height based on number of rows plus padding
    final height = baseHeight + (rowCount * rowHeight) + 32.0; // 32 for padding
    
    return Size(width, height);
  }
} 