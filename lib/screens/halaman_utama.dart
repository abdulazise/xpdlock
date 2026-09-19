import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'loading.dart';
import 'package:xpdlock/screens/download.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:pointycastle/export.dart' as pointy;
import 'package:crypto/crypto.dart';
import 'package:open_file/open_file.dart';
import 'package:logging/logging.dart'; // Import logging

void initLogger() {
  // Clear existing listeners
  Logger.root.clearListeners();
  
  // Set log level
  Logger.root.level = Level.ALL;
  
  // Add single listener
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

final _logger = Logger('XPDLock'); // Logger instance

const platform = MethodChannel('com.example.xpdlock/crypto');

class HalamanUtama extends StatefulWidget {
  final Map<String, dynamic>? downloadData;

  const HalamanUtama({Key? key, this.downloadData}) : super(key: key);

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

Future<List<int>> _serpentEncrypt(List<int> data, Uint8List key) async {
  try {
    // Generate IV for Serpent
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // Call native method
    final result = await platform.invokeMethod('serpentEncrypt', {
      'data': Uint8List.fromList(data),
      'key': key,
      'iv': iv.bytes,
      'mode': 'CBC'
    });
    
    // Return IV + encrypted data
    return [...iv.bytes, ...result];
  } catch (e) {
    _logger.info('Serpent encryption failed: $e');
    return data; // Return original data if encryption fails
  }
}

Future<List<int>> _serpentDecrypt(List<int> data, Uint8List key) async {
  try {
    // Extract IV (first 16 bytes) and encrypted data
    final iv = data.sublist(0, 16);
    final encryptedData = data.sublist(16);
    
    // Call native method
    final result = await platform.invokeMethod('serpentDecrypt', {
      'data': Uint8List.fromList(encryptedData),
      'key': key,
      'iv': iv,
      'mode': 'CBC'
    });
    
    return result;
  } catch (e) {
    _logger.info('Serpent decryption failed: $e');
    return data; // Return original data if decryption fails
  }
}

// Sisipkan implementasi _twofishEncrypt dan _twofishDecrypt
Future<List<int>> _twofishEncrypt(List<int> data, Uint8List key) async {
  try {
    // Generate IV for Twofish
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // Call native method
    final result = await platform.invokeMethod('twofishEncrypt', {
      'data': Uint8List.fromList(data),
      'key': key,
      'iv': iv.bytes,
      'mode': 'CBC'
    });
    
    // Return IV + encrypted data
    return [...iv.bytes, ...result];
  } catch (e) {
    _logger.info('Twofish encryption failed: $e');
    return data; // Return original data if encryption fails
  }
}

Future<List<int>> _twofishDecrypt(List<int> data, Uint8List key) async {
  try {
    // Extract IV (first 16 bytes) and encrypted data
    final iv = data.sublist(0, 16);
    final encryptedData = data.sublist(16);
    
    // Call native method
    final result = await platform.invokeMethod('twofishDecrypt', {
      'data': Uint8List.fromList(encryptedData),
      'key': key,
      'iv': iv,
      'mode': 'CBC'
    });
    
    return result;
  } catch (e) {
    _logger.info('Twofish decryption failed: $e');
    return data; // Return original data if decryption fails
  }
}
class _HalamanUtamaState extends State<HalamanUtama> with WidgetsBindingObserver {
  String? filePath;
  String? fileName;
  String? keyInput;
  bool _showError = false;
  final FocusNode _keyInputFocusNode = FocusNode();
  final TextEditingController _keyController = TextEditingController();
  final ValueNotifier<bool> _isKeyInputFocused = ValueNotifier<bool>(false);
  bool showSuccessPopup = false;
  String? downloadedFilePath;
  String? downloadedFileName;

  @override
  void initState() {
    super.initState();
    initLogger();
    WidgetsBinding.instance.addObserver(this);
    _keyInputFocusNode.addListener(_handleFocusChange);
    _keyInputFocusNode.addListener(() {
      _isKeyInputFocused.value = _keyInputFocusNode.hasFocus;
    });

    // Check if we have download success data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.downloadData != null) {
        final data = widget.downloadData!;
        if (data['showSuccessPopup'] == true) {
          setState(() {
            showSuccessPopup = true;
            downloadedFilePath = data['downloadedFilePath'];
            downloadedFileName = data['fileName'];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _keyInputFocusNode.dispose();
    _keyController.dispose();
    _isKeyInputFocused.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    _isKeyInputFocused.value = _keyInputFocusNode.hasFocus;
  }

  void _dismissPopup() {
    setState(() {
      showSuccessPopup = false;
    });
  }

  Future<void> _openFile() async {
    if (downloadedFilePath == null) return;

    final result = await OpenFile.open(downloadedFilePath!);
    if (result.type != ResultType.done) {
      if (mounted) {
        showAlertDialog(context, 'Error', 'Gagal membuka file: ${result.message}');
      }
    }
  }

  void clearKey() {
    setState(() {
      keyInput = '';
      _showError = false;
      _keyController.clear();
    });
  }

  void clearFile() {
    setState(() {
      filePath = null;
      fileName = null;
    });
  }
void showAlertDialog(BuildContext context, String title, String message, {VoidCallback? onOk}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 0),
        title: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1976D2),
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 24),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onOk != null) onOk();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
  Future<void> pickFile() async {
  try {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

   if (statuses[Permission.storage]!.isPermanentlyDenied ||
    statuses[Permission.manageExternalStorage]!.isPermanentlyDenied) {
  showAlertDialog(
    context,
    'Akses Ditolak',
    'Izin penyimpanan ditolak permanen. Silakan aktifkan izin secara manual di pengaturan aplikasi.',
    onOk: () => openAppSettings(),
  );
  return;
}

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final extension = file.path.split('.').last.toLowerCase();

      // Check file size (5MB = 5 * 1024 * 1024 bytes)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        showAlertDialog(
          context,
          'Ukuran File Terlalu Besar',
          'Maksimal ukuran file yang diperbolehkan adalah 5MB.\nUkuran file Anda: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB',
        );
        return;
      }

      if (!['pdf', 'xlsx', 'enc'].contains(extension)) {
        showAlertDialog(
          context,
          'Format Tidak Didukung',
          'Mohon pilih file PDF, XLSX, atau ENC',
        );
        return;
      }

      setState(() {
        filePath = file.path;
        fileName = result.files.single.name;
      });
    }
  } catch (e) {
    showAlertDialog(
      context,
      'Kesalahan',
      'Gagal memilih file: ${e.toString()}',
    );
  }
}

  List<int> deriveKey(String password, List<int> salt, {int keyLength = 32}) {
    final pbkdf2 = pointy.PBKDF2KeyDerivator(pointy.HMac(pointy.SHA256Digest(), 64))
      ..init(pointy.Pbkdf2Parameters(Uint8List.fromList(salt), 1000, keyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }


  int _generateCaesarShift(String key) {
    final keyBytes = utf8.encode(key);
    final digest = sha256.convert(keyBytes);
    final shift = digest.bytes[0] % 26;
    return shift;
  }

  // Base64 + Caesar 
  List<int> _base64CaesarEncrypt(List<int> data, int shift) {
    String base64Str = base64.encode(data);
    List<int> result = [];
    for (int i = 0; i < base64Str.length; i++) {
      int charCode = base64Str.codeUnitAt(i);
      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        int base = (charCode >= 65 && charCode <= 90) ? 65 : 97;
        int shifted = (charCode - base + shift) % 26 + base;
        result.add(shifted);
      } else {
        result.add(charCode);
      }
    }
    return result;
  }

  List<int> _base64CaesarDecrypt(List<int> data, int shift) {
    List<int> caesarDecrypted = [];
    for (int i = 0; i < data.length; i++) {
      int charCode = data[i];
      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        int base = (charCode >= 65 && charCode <= 90) ? 65 : 97;
        int shifted = (charCode - base - shift + 26) % 26 + base;
        caesarDecrypted.add(shifted);
      } else {
        caesarDecrypted.add(charCode);
      }
    }
    String decryptedBase64 = String.fromCharCodes(caesarDecrypted);
    try {
      return base64.decode(decryptedBase64);
    } catch (e) {
      _logger.info('Base64 decoding failed: $e');
      return data; 
    }
  }

  // Add these helper functions at the top of the class
  void _logEncryptionStep(String step, List<int> data) {
    final hash = sha256.convert(data).toString();
    final size = data.length;
    _logger.info('Encryption Step: $step');
    _logger.info('Data Size: $size bytes');
    _logger.info('Data Hash: $hash');
    _logger.info('-------------------');
  }

  void _logDecryptionStep(String step, List<int> data) {
    final hash = sha256.convert(data).toString();
    final size = data.length;
    _logger.info('Decryption Step: $step');
    _logger.info('Data Size: $size bytes');
    _logger.info('Data Hash: $hash');
    _logger.info('-------------------');
  }

  void _logDetailedEncryption(String step, List<int> data, {List<int>? key, List<int>? iv}) {
  final hash = sha256.convert(data).toString();
  final size = data.length;
  
  _logger.info('\n════════════════ $step ════════════════');
  _logger.info('Timestamp: ${DateTime.now()}');
  _logger.info('Data Size: $size bytes');
  _logger.info('SHA-256 Hash: $hash');
  
  if (key != null) {
    _logger.info('\nKey (HEX): ${_bytesToHex(key)}');
    _logger.info('Key (Base64): ${base64.encode(key)}');
  }
  
  // Tambahkan detail IV yang lebih lengkap
  if (iv != null) {
    _logger.info('\nInitialization Vector:');
    _logger.info('IV (HEX): ${_bytesToHex(iv)}');
    _logger.info('IV (Base64): ${base64.encode(iv)}');
    _logger.info('IV Length: ${iv.length} bytes');
  }

  _logger.info('\nData Preview:');
  final previewSize = data.length > 100 ? 100 : data.length;
  
  // Show in HEX
  _logger.info('First 100 bytes (HEX):');
  for (int i = 0; i < previewSize; i += 16) {
    final chunk = data.skip(i).take(16).toList();
    final hex = _bytesToHex(chunk);
    final offset = i.toRadixString(16).padLeft(8, '0');
    _logger.info('$offset: $hex');
  }


  _logger.info('\nData (Base64): ${base64.encode(data.take(previewSize).toList())}');
  _logger.info('════════════════ End $step ════════════════\n');
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
// enkripsi
  Future<void> encryptFile() async {
    if (!validateBeforeAction()) {
      return;
    }
    _logger.info('Starting encryption process...');
    _logger.info('File: ${filePath!}');
    _logger.info('===================');
     final extension = path.extension(filePath!).toLowerCase();
  if (!['.pdf', '.xlsx'].contains(extension)) {
    showAlertDialog(
      context,
      'Format File Salah',
      'Untuk enkripsi, mohon pilih file PDF atau Excel',
    );
    return;
  }

    try {
      final file = File(filePath!);
      final contents = await file.readAsBytes();
      _logEncryptionStep('Original File', contents);

      final salt = List<int>.generate(16, (i) => i + 1);
      String outputPath = '${filePath!}.enc';

      List<int> encryptedData = contents;
      late encrypt.IV iv;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Loading2(
            isEncryption: true,
            onStepComplete: (stepIndex) async {
              switch (stepIndex) {
                case 0:
                _logger.info('\n🔒 Starting AES-128 Encryption');
                final aesKeyBytes = deriveKey(keyInput!, salt, keyLength: 32);
                final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes.sublist(0, 32)));
                iv = encrypt.IV.fromSecureRandom(16);
                
                _logger.info('AES IV Generated:');
                _logger.info('IV (HEX): ${_bytesToHex(iv.bytes)}');
                _logger.info('IV (Base64): ${base64.encode(iv.bytes)}');
                
                _logDetailedEncryption('Original Data', encryptedData);
                
                final aesEncrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
                encryptedData = aesEncrypter.encryptBytes(encryptedData, iv: iv).bytes;
                
                _logDetailedEncryption('After AES Layer', encryptedData, key: aesKeyBytes, iv: iv.bytes);
                break;

                case 1:
                _logger.info('\n🔒 Starting Serpent Encryption');
                final serpentKeyBytes = deriveKey(keyInput!, salt.map((e) => e * 2).toList(), keyLength: 32);
                final serpentResult = await _serpentEncrypt(encryptedData, Uint8List.fromList(serpentKeyBytes));
                final serpentIV = serpentResult.sublist(0, 16);
                
                _logger.info('Serpent IV:');
                _logger.info('IV (HEX): ${_bytesToHex(serpentIV)}');
                _logger.info('IV (Base64): ${base64.encode(serpentIV)}');
                
                encryptedData = serpentResult;
                _logDetailedEncryption('After Serpent Layer', encryptedData, key: serpentKeyBytes, iv: serpentIV);
                break;

                case 2:
                _logger.info('\n🔒 Starting Twofish Encryption');
                final twofishKeyBytes = deriveKey(keyInput!, salt.reversed.toList(), keyLength: 32);
                final twofishResult = await _twofishEncrypt(encryptedData, Uint8List.fromList(twofishKeyBytes));
                final twofishIV = twofishResult.sublist(0, 16);
                
                _logger.info('Twofish IV:');
                _logger.info('IV (HEX): ${_bytesToHex(twofishIV)}');
                _logger.info('IV (Base64): ${base64.encode(twofishIV)}');
                
                encryptedData = twofishResult;
                _logDetailedEncryption('After Twofish Layer', encryptedData, key: twofishKeyBytes, iv: twofishIV);
                break;

                case 3:
                  // Base64+Caesar Encryption
                  _logger.info('\n🔒 Starting Base64+Caesar Encryption');
                  final caesarShift = _generateCaesarShift(keyInput!);
                  _logDetailedEncryption('Before Base64+Caesar', encryptedData);
                  encryptedData = _base64CaesarEncrypt(encryptedData, caesarShift);
                  _logDetailedEncryption('After Base64+Caesar Layer', encryptedData);
                  _logger.info('Caesar Shift Used: $caesarShift');
                  await File(outputPath).writeAsBytes([...salt, ...iv.bytes, ...encryptedData]);
                  _logger.info('\nFinal Results:');
                  _logger.info('Final file size: ${encryptedData.length} bytes');
                  _logger.info('Salt used: ${_bytesToHex(salt)}');
                  _logger.info('Final IV: ${_bytesToHex(iv.bytes)}');
                  _logger.info('Encryption complete!\n');
                  _logger.info('═══════════════════════════════════════\n');
                  await Future.delayed(const Duration(seconds: 2));
                  break;
              }
            },
            onAllStepsComplete: () {
              // Navigate to download page after all steps complete
              Navigator.pushReplacementNamed(
                context,
                '/download',
                arguments: {
                  'encryptedFilePath': outputPath.replaceAll('\\\\', '/'),
                  'fileName': path.basename(outputPath)
                },
              );
            },
          ),
        ),
      );

    } catch (e) {
      _logger.severe('Encryption failed: $e');
      if (!mounted) return;
      showAlertDialog(
        context,
        'Enkripsi Gagal',
        'Gagal mengenkripsi file: ${e.toString()}',
      );
    }
  }

  // Dekripsi 
 Future<void> decryptFile() async {
  if (!validateBeforeAction()) {
    return;
  }

  if (!filePath!.toLowerCase().endsWith('.enc')) {
    showAlertDialog(
      context,
      'Format File Salah',
      'Mohon pilih file dengan ekstensi .enc untuk dekripsi'
    );
    return;
  }

  try {
    final file = File(filePath!);
    final encryptedData = await file.readAsBytes();
    
    // Extract initial data
    final salt = encryptedData.sublist(0, 16); 
    final iv = encryptedData.sublist(16, 32);

    _logger.info('Starting decryption process...');
    _logger.info('File: ${filePath!}');
    _logger.info('===================');

    String outputPath = filePath!.substring(0, filePath!.length - 4);
    if (!outputPath.toLowerCase().endsWith('.pdf') &&
        !outputPath.toLowerCase().endsWith('.xlsx')) {
      outputPath += '.decrypted';
    }

    List<int> decryptedData = encryptedData.sublist(32);
    final aesKeyBytes = deriveKey(keyInput!, salt, keyLength: 32);
    final aesKey = encrypt.Key(Uint8List.fromList(aesKeyBytes.sublist(0, 32)));

    // Show loading screen and attempt decryption
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Loading2(
          isEncryption: false,
          onStepComplete: (stepIndex) async {
            try {
              switch (stepIndex) {
                case 0:
                  _logger.info('\n🔓 Starting Base64+Caesar Decryption');
                  final caesarShift = _generateCaesarShift(keyInput!);
                  _logDetailedEncryption('Before Base64+Caesar Decryption', decryptedData);
                  decryptedData = _base64CaesarDecrypt(decryptedData, caesarShift);
                  _logDetailedEncryption('After Base64+Caesar Decryption', decryptedData);
                  _logger.info('Caesar Shift Used: $caesarShift');
                  await Future.delayed(const Duration(seconds: 2));
                  break;

                case 1:
                  _logger.info('\n🔓 Starting Twofish Decryption');
                  final twofishKeyBytes = deriveKey(keyInput!, salt.reversed.toList(), keyLength: 32);
                  final twofishIV = decryptedData.sublist(0, 16);
                  _logDetailedEncryption('Before Twofish Decryption', decryptedData);
                  decryptedData = await _twofishDecrypt(decryptedData, Uint8List.fromList(twofishKeyBytes));
                  _logDetailedEncryption('After Twofish Decryption', decryptedData, key: twofishKeyBytes, iv: twofishIV);
                  await Future.delayed(const Duration(seconds: 2));
                  break;

                case 2:
                  _logger.info('\n🔓 Starting Serpent Decryption');
                  final serpentKeyBytes = deriveKey(keyInput!, salt.map((e) => e * 2).toList(), keyLength: 32);
                  final serpentIV = decryptedData.sublist(0, 16);
                  _logDetailedEncryption('Before Serpent Decryption', decryptedData);
                  decryptedData = await _serpentDecrypt(decryptedData, Uint8List.fromList(serpentKeyBytes));
                  _logDetailedEncryption('After Serpent Decryption', decryptedData, key: serpentKeyBytes, iv: serpentIV);
                  await Future.delayed(const Duration(seconds: 2));
                  break;

                case 3:
                  _logger.info('\n🔓 Starting AES-128 Decryption');
                  final aesIV = encrypt.IV(Uint8List.fromList(iv));
                  final aesEncrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
                  _logDetailedEncryption('Before AES Decryption', decryptedData);
                  try {
                    decryptedData = aesEncrypter.decryptBytes(
                      encrypt.Encrypted(Uint8List.fromList(decryptedData)),
                      iv: aesIV,
                    );
                    _logDetailedEncryption('After AES Decryption', decryptedData, key: aesKeyBytes, iv: aesIV.bytes);
                    await File(outputPath).writeAsBytes(decryptedData);
                    _logger.info('\nDecryption complete!\n');
                  } catch (e) {
                    throw 'Kunci yang dimasukkan tidak sesuai dengan file ini';
                  }
                  await Future.delayed(const Duration(seconds: 2));
                  break;
              }
            } catch (e) {
              Navigator.pop(context); // Close loading screen
              showAlertDialog(
                context,
                'Dekripsi Gagal',
                e.toString()
              );
              throw e; // Re-throw to prevent completion
            }
          },
          onAllStepsComplete: () {
            Navigator.pushReplacementNamed(
              context,
              '/download',
              arguments: {
                'encryptedFilePath': outputPath.replaceAll('\\\\', '/'),
                'fileName': path.basename(outputPath)
              },
            );
          },
        ),
      ),
    );

  } catch (e) {
    _logger.severe('Decryption failed: $e');
    if (!mounted) return;
    if (e.toString().contains('Kunci yang dimasukkan tidak sesuai')) return; 
    showAlertDialog(
      context,
      'Dekripsi Gagal',
      'Gagal mendekripsi file: ${e.toString()}'
    );
  }
}


  bool validateBeforeAction() {
  if (filePath == null) {
    showAlertDialog(
      context,
      'File Diperlukan',
      'Silakan pilih file PDF, Excel, atau ENC terlebih dahulu',
    );
    return false;
  }

  if (keyInput == null || keyInput!.isEmpty) {
    showAlertDialog(
      context,
      'Kunci Diperlukan',
      'Silakan masukkan kunci untuk melanjutkan',
    );
    return false;
  }

  if (keyInput!.length < 8) {
    showAlertDialog(
      context,
      'Kunci Tidak Valid',
      'Kunci harus minimal 8 karakter panjangnya',
    );
    return false;
  }
  return true;
}

  void validateKey(String value) {
    setState(() {
      keyInput = value;
      _showError = value.isNotEmpty && value.length < 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_keyInputFocusNode.hasFocus) {
          _keyInputFocusNode.unfocus();
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: PopScope(
          canPop: !_keyInputFocusNode.hasFocus,
          onPopInvoked: (bool didPop) async {
            if (_keyInputFocusNode.hasFocus) {
              _keyInputFocusNode.unfocus();
            }
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              // Ubah warna background menjadi biru yang lebih gelap
              color: const Color(0xFF1E88E5), // Biru lebih gelap
              child: Stack(
                fit: StackFit.expand, 
                children: [
                  // Top app bar dengan judul
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      height: 93,
                      decoration: const ShapeDecoration(
                        // Ubah warna app bar jadi lebih gelap sedikit dari background
                        color: Color(0x991976D2), // Opacity dan warna baru
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'XPD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Poppins',
                                  height: 1.0,
                                  letterSpacing: 0.25,
                                ),
                              ),
                              TextSpan(
                                text: 'LOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Poppins',
                                  height: 1.0,
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Gambar cybersecurity
                  ValueListenableBuilder<bool>(
                    valueListenable: _isKeyInputFocused,
                    builder: (context, isFocused, child) {
                      return Visibility(
                        visible: !isFocused,
                        child: Positioned(
                          left: 0,
                          right: 0,
                          top: MediaQuery.of(context).size.height * 0.25,
                          child: Container(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/cybersecurity-98.png',
                              width: 250,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Bottom content area
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      decoration: const ShapeDecoration(
                        // Ubah warna bottom area
                        color: Color(0x991976D2), // Opacity dan warna baru
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50),
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Amankan File PDF dan Excel Anda',
                                style: TextStyle(
                                  color: Color(0xFFFFFDFD),
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.50,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // File selection button
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                width: double.infinity,
                                height: 58.76,
                                decoration: ShapeDecoration(
                                  color: const Color(0x6638BDF8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: pickFile,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 24.0,
                                          top: 17.0,
                                          child: Image.asset(
                                            'assets/images/file.png',
                                            width: 24,
                                            height: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Positioned(
                                          left: 60.0,
                                          right: 50.0,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: Text(
                                              fileName != null
                                                  ? fileName!.length > 20
                                                      ? '${fileName!.substring(0, 20)}...'
                                                      : fileName!
                                                  : 'Masukan file',
                                              style: const TextStyle(
                                                color: Color(0xFFFFFDFD),
                                                fontSize: 15,
                                                fontFamily: 'Poppins',
                                                letterSpacing: 0.50,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        if (filePath != null)
                                          Positioned(
                                            right: 16.0,
                                            top: 17.0,
                                            child: GestureDetector(
                                              onTap: clearFile,
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                             const SizedBox(height: 20),
                            // Password input field
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              width: double.infinity,
                              height: 58.76,
                              decoration: ShapeDecoration(
                                color: const Color(0x6638BDF8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 24.0,
                                      top: 17.0,
                                      child: Image.asset(
                                        'assets/images/key.png',
                                        width: 24,
                                        height: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Positioned(
                                      left: 60.0,
                                      right: 50.0,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: TextField(
                                      controller: _keyController,
                                      focusNode: _keyInputFocusNode,
                                      onChanged: validateKey,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFFFDFD),
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        letterSpacing: 0.50,
                                      ),
                                      keyboardType: TextInputType.text,
                                      autofocus: false,
                                      enableInteractiveSelection: true,
                                      onTap: () {
                                        if (!_keyInputFocusNode.hasFocus) {
                                          _keyInputFocusNode.requestFocus();
                                        }
                                      },
                                     onSubmitted: (value) {
                                      _keyInputFocusNode.unfocus(); 
                                    },
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: _keyInputFocusNode.hasFocus ? '' : 'Masukan kunci', // Modify this line
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFFFFDFD),
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          letterSpacing: 0.50,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        errorText: null,
                                      ),
                                    ),
                                    ),
                                    ),
                                    if (_keyController.text.isNotEmpty)
                                      Positioned(
                                        right: 16.0,
                                        top: 17.0,
                                        child: GestureDetector(
                                          onTap: () {
                                            clearKey();
                                            _keyInputFocusNode.requestFocus();
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Error message (below the input field)
                            if (_showError)
                              Container(
                                margin: const EdgeInsets.only(top: 8.0, left: 24, right: 24),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Kunci minimal 8 karakter',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                               // Ubah Row yang berisi tombol Dekripsi dan Enkripsi menjadi:

                              // Ubah Row yang berisi tombol menjadi:
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Tombol Dekripsi
                                  GestureDetector(
                                    onTap: decryptFile,
                                    child: Container(
                                      width: 150, // Lebar tombol lebih besar karena hanya 2 tombol
                                      height: 42.82,
                                      decoration: ShapeDecoration(
                                        color: const Color(0x6638BDF8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/ogem.png',
                                                width: 24,
                                                height: 24,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Dekripsi',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: 'Poppins',
                                                  letterSpacing: 0.50,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Tombol Enkripsi
                                  GestureDetector(
                                    onTap: encryptFile,
                                    child: Container(
                                      width: 150, // Lebar tombol lebih besar karena hanya 2 tombol
                                      height: 42.82,
                                      decoration: ShapeDecoration(
                                        color: const Color(0x6638BDF8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/lgem.png',
                                                width: 24,
                                                height: 24,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Enkripsi',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontFamily: 'Poppins',
                                                  letterSpacing: 0.50,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Success popup
                  if (showSuccessPopup)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Berhasil!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'File telah berhasil diunduh ke folder Download',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  downloadedFileName ?? "",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _dismissPopup();
                                        _openFile();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8FDCFF),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      child: const Text(
                                        'Buka File',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton(
                                      onPressed: _dismissPopup,
                                      child: const Text(
                                        'Kembali',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}