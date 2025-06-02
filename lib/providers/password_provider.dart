import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io' show Platform;

class PasswordProvider with ChangeNotifier {
  Database? _db;
  List<Password> _passwords = [];
  List<Category> _categories = [];
  String _searchQuery = '';
  final Map<int, String> _originalPasswords = {};
  
  // Encryption components
  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;
  late final FlutterSecureStorage _secureStorage;

  PasswordProvider() {
    _secureStorage = const FlutterSecureStorage();
  }

  List<Password> get passwords => _passwords;
  List<Category> get categories => _categories;
  String get searchQuery => _searchQuery;

  Future<void> _initializeEncryption() async {
    try {
      // Try to load existing key and IV
      final storedKey = await _secureStorage.read(key: 'encryption_key');
      final storedIV = await _secureStorage.read(key: 'encryption_iv');

      if (storedKey != null && storedIV != null) {
        // Use existing key and IV
        _key = encrypt.Key.fromBase64(storedKey);
        _iv = encrypt.IV.fromBase64(storedIV);
      } else {
        // Generate new key and IV
        _key = encrypt.Key.fromSecureRandom(32);
        _iv = encrypt.IV.fromSecureRandom(16);
        
        // Store them securely
        await _secureStorage.write(key: 'encryption_key', value: _key!.base64);
        await _secureStorage.write(key: 'encryption_iv', value: _iv!.base64);
      }

      // Initialize encrypter
      _encrypter = encrypt.Encrypter(encrypt.AES(_key!));
    } catch (e) {
      debugPrint('Error initializing encryption: $e');
      // If there's an error, try to delete the keys and reinitialize
      try {
        await _secureStorage.deleteAll();
        // Generate new key and IV
        _key = encrypt.Key.fromSecureRandom(32);
        _iv = encrypt.IV.fromSecureRandom(16);
        
        // Store them securely
        await _secureStorage.write(key: 'encryption_key', value: _key!.base64);
        await _secureStorage.write(key: 'encryption_iv', value: _iv!.base64);
        
        // Initialize encrypter
        _encrypter = encrypt.Encrypter(encrypt.AES(_key!));
      } catch (e) {
        debugPrint('Fatal error initializing encryption: $e');
        rethrow;
      }
    }
  }

  Future<void> initialize() async {
    await _initializeEncryption();
    
    _db = await openDatabase(
      join(await getDatabasesPath(), 'passwords.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            icon TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE passwords(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            password TEXT,
            category_id INTEGER,
            iv TEXT,
            FOREIGN KEY (category_id) REFERENCES categories (id)
          )
        ''');
        
        // Insert default categories
        await db.insert('categories', {
          'name': 'All',
          'icon': 'all.png',
        });
        await db.insert('categories', {
          'name': 'Google',
          'icon': 'google.png',
        });
        await db.insert('categories', {
          'name': 'Facebook',
          'icon': 'facebook.png',
        });
        await db.insert('categories', {
          'name': 'Wi-Fi',
          'icon': 'wifi.png',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE passwords ADD COLUMN iv TEXT');
        }
      },
      version: 2,
    );

    await _loadCategories();
    await _loadPasswords();
  }

  Future<void> _loadCategories() async {
    final List<Map<String, dynamic>> maps = await _db!.query('categories');
    _categories = maps.map((map) => Category.fromMap(map)).toList();
    notifyListeners();
  }

  Future<void> _loadPasswords() async {
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }

    final List<Map<String, dynamic>> maps = await _db!.query('passwords');
    _passwords = maps.map((map) {
      final password = Password.fromMap(map);
      // Store the original decrypted password
      if (map['iv'] != null) {
        try {
          final iv = encrypt.IV.fromBase64(map['iv']);
          final decrypted = _decryptPassword(password.password, iv);
          _originalPasswords[password.id!] = decrypted;
        } catch (e) {
          debugPrint('Error decrypting password ${password.id}: $e');
          _originalPasswords[password.id!] = password.password;
        }
      } else {
        // Handle legacy passwords
        _originalPasswords[password.id!] = password.password;
      }
      return password;
    }).toList();
    notifyListeners();
  }

  String _encryptPassword(String password) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }
    final encrypted = _encrypter!.encrypt(password, iv: _iv!);
    return encrypted.base64;
  }

  String _decryptPassword(String encryptedPassword, encrypt.IV iv) {
    if (_encrypter == null) {
      throw Exception('Encryption not initialized');
    }
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedPassword);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Error decrypting password: $e');
      return encryptedPassword;
    }
  }

  String getOriginalPassword(int id) {
    return _originalPasswords[id] ?? '';
  }

  Future<void> addPassword(Password password) async {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption not initialized');
    }

    try {
      // Encrypt the password
      final encryptedPassword = _encryptPassword(password.password);
      
      // Store encrypted password in database
      final id = await _db!.insert('passwords', {
        'username': password.username,
        'password': encryptedPassword,
        'category_id': password.categoryId,
        'iv': _iv!.base64,
      });

      // Store original password in memory
      _originalPasswords[id] = password.password;
      
      final newPassword = password.copyWith(
        id: id,
        password: encryptedPassword,
      );
      _passwords.add(newPassword);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding password: $e');
      rethrow;
    }
  }

  Future<void> updatePassword(Password password) async {
    // Encrypt the new password
    final encryptedPassword = _encryptPassword(password.password);
    
    await _db!.update(
      'passwords',
      {
        'username': password.username,
        'password': encryptedPassword,
        'category_id': password.categoryId,
        'iv': _iv!.base64,
      },
      where: 'id = ?',
      whereArgs: [password.id],
    );

    // Update original password in memory
    _originalPasswords[password.id!] = password.password;
    
    final index = _passwords.indexWhere((p) => p.id == password.id);
    _passwords[index] = password.copyWith(
      password: encryptedPassword,
    );
    notifyListeners();
  }

  Future<void> deletePassword(int id) async {
    await _db!.delete(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
    _passwords.removeWhere((password) => password.id == id);
    _originalPasswords.remove(id);
    notifyListeners();
  }

  List<Category> getFilteredCategories() {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories.where((category) {
      final query = _searchQuery.toLowerCase();
      return category.name.toLowerCase().contains(query);
    }).toList();
  }

  List<Password> getPasswordsByCategory(int categoryId) {
    if (categoryId == 1) { // All category
      // Create a map of category names for sorting
      final categoryMap = {for (var c in _categories) c.id: c.name};
      
      // Return sorted list
      final sortedPasswords = List<Password>.from(_passwords);
      sortedPasswords.sort((a, b) {
        final categoryA = categoryMap[a.categoryId] ?? '';
        final categoryB = categoryMap[b.categoryId] ?? '';
        final categoryCompare = categoryA.compareTo(categoryB);
        
        // If categories are the same, sort by username
        if (categoryCompare == 0) {
          return a.username.compareTo(b.username);
        }
        return categoryCompare;
      });
      
      return sortedPasswords;
    }
    
    // For specific categories, return filtered and sorted by username
    return _passwords
        .where((p) => p.categoryId == categoryId)
        .toList()
      ..sort((a, b) => a.username.compareTo(b.username));
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addCategory(String name, String icon) async {
    final id = await _db!.insert('categories', {
      'name': name,
      'icon': icon,
    });

    _categories.add(Category(
      id: id,
      name: name,
      icon: icon,
    ));
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    // Don't allow deleting the "All" category (id = 1)
    if (id == 1) return;

    // First, delete all passwords in this category
    await _db!.delete(
      'passwords',
      where: 'category_id = ?',
      whereArgs: [id],
    );

    // Then delete the category
    await _db!.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    _passwords.removeWhere((password) => password.categoryId == id);
    _categories.removeWhere((category) => category.id == id);
    notifyListeners();
  }
}

class Password {
  int? id;
  final String username;
  final String password;
  final int categoryId;

  Password({
    this.id,
    required this.username,
    required this.password,
    required this.categoryId,
  });

  factory Password.fromMap(Map<String, dynamic> map) {
    // When loading from database, we need to use the encrypted password as is
    return Password(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      categoryId: map['category_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'category_id': categoryId,
    };
  }

  Password copyWith({
    int? id,
    String? username,
    String? password,
    int? categoryId,
  }) {
    return Password(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
    );
  }
} 