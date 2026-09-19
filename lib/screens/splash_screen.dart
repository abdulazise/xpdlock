import 'package:flutter/material.dart';
import 'dart:async';
import 'halaman_utama.dart'; // Import halaman utama

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _setupAnimation();
    _startNavigation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159)
      .animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
      .animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
    
    _animationController.forward();
  }

  void _startNavigation() {
  Timer(
    const Duration(seconds: 3),
    () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false, // Menghapus semua halaman sebelumnya
        );
      }
    },
  );
}

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'XPD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const Text(
                    'L',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.25,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Icon(
                              Icons.lock,
                              size: 48,
                              color: const Color(0xFF8FDCFF)
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Text(
                    'CK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}