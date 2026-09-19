import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class HalamanDownload extends StatefulWidget {
  final String encryptedFilePath;
  
  const HalamanDownload({
    Key? key,
    required this.encryptedFilePath,
  }) : super(key: key);

  @override
  State<HalamanDownload> createState() => _HalamanDownloadState();
}

class _HalamanDownloadState extends State<HalamanDownload> {
  bool isLoading = false;
  String fileName = "";

  @override
  void initState() {
    super.initState();
    fileName = path.basename(widget.encryptedFilePath);
  }

Future<void> _handleDownload() async {
  if (isLoading) return;

  setState(() {
    isLoading = true;
  });

try {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();

  if (!statuses[Permission.storage]!.isGranted ||
      !statuses[Permission.manageExternalStorage]!.isGranted) {
    throw Exception('Izin penyimpanan dibutuhkan');
  }

  final sourceFile = File(widget.encryptedFilePath);
  if (!await sourceFile.exists()) {
    throw Exception('File tidak ditemukan: ${widget.encryptedFilePath}');
  }

  const downloadPath = '/storage/emulated/0/Download';
  final downloadDir = Directory(downloadPath);
  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }

  final fileName = widget.encryptedFilePath.split('/').last;
  final destinationPath = '$downloadPath/$fileName';

  await sourceFile.copy(destinationPath);

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/home',
    (route) => false,
    arguments: {
      'showSuccessPopup': true,
      'downloadedFilePath': destinationPath,
      'fileName': fileName,
    },
  );
} catch (e) {
  print('Download error: $e');

  setState(() {
    isLoading = false;
  });

  if (mounted) {
    _showErrorDialog('Gagal mengunduh file: ${e.toString()}');
  }
}
}
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1976D2), // Warna dialog yang sama
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x6638BDF8), // Warna button yang sama
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ubah background menjadi biru gelap yang sama
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            children: [
              // Top title text
              const Positioned(
                left: 0,
                right: 0,
                top: 46,
                child: Center(
                  child: Text(
                    'File anda siap untuk diunduh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.50,
                    ),
                  ),
                ),
              ),
              
              // Image container dengan background semi-transparan
              Positioned(
                left: 0,
                right: 0,
                top: 100,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  
                  child: Center(
                    child: Image.asset(
                      'assets/images/cybersecurity-1-98.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // File name container
              Positioned(
                left: 20,
                right: 20,
                top: 320,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x6638BDF8), // Warna biru semi-transparan yang sama
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    fileName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Download button
              Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: Center(
                  child: isLoading 
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8FDCFF)),
                        backgroundColor: Colors.white24,
                      )
                    : ElevatedButton(
                        onPressed: _handleDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0x6638BDF8), // Warna button yang sama
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Download',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}