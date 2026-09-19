import 'package:flutter/material.dart';
import 'dart:math';

class ProcessStep {
  final String name;
  final String description;
  bool isCompleted;
  bool isActive;
  double progress;

  ProcessStep({
    required this.name, 
    required this.description,
    this.isCompleted = false,
    this.isActive = false,
    this.progress = 0.0,
  });
}

class Loading2 extends StatefulWidget {
  final bool isEncryption;
  final Function(int)? onStepComplete;
  final Function()? onAllStepsComplete; // Add this

  const Loading2({
    Key? key, 
    this.isEncryption = true,
    this.onStepComplete,
    this.onAllStepsComplete, // Add this
  }) : super(key: key);

  @override
  _Loading2State createState() => _Loading2State();
}

class _Loading2State extends State<Loading2> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  List<ProcessStep> steps = [];
  int currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _setupAnimations();
    _startProcessing();
  }

  void _initializeSteps() {
    steps = widget.isEncryption ? [
      ProcessStep(
        name: "Layer 1 - AES",
        description: "Mengenkripsi dengan Advanced Encryption Standard",
      ),
      ProcessStep(
        name: "Layer 2 - Serpent",
        description: "Menerapkan enkripsi Serpent",
      ),
      ProcessStep(
        name: "Layer 3 - Twofish",
        description: "Mengimplementasikan enkripsi Twofish",
      ),
      ProcessStep(
        name: "Layer 4 - Base64 + Caesar",
        description: "Finalisasi dengan Base64 dan Caesar Cipher",
      ),
    ] : [
      ProcessStep(
        name: "Layer 4 - Base64 + Caesar",
        description: "Mendekripsi Base64 dan Caesar Cipher",
      ),
      ProcessStep(
        name: "Layer 3 - Twofish",
        description: "Mendekripsi layer Twofish",
      ),
      ProcessStep(
        name: "Layer 2 - Serpent",
        description: "Mendekripsi layer Serpent",
      ),
      ProcessStep(
        name: "Layer 1 - AES",
        description: "Mendekripsi Advanced Encryption Standard",
      ),
    ];
    
    // Activate first step
    if (steps.isNotEmpty) {
      steps[0].isActive = true;
    }
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Rotation animation for the loading spinner
    _rotationAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    // Pulse animation for active step
    _pulseAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Wave animation for progress indicator
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _startProcessing() async {
    for (int i = 0; i < steps.length; i++) {
      if (!mounted) return;
      
      // Simulate processing time with progress updates
      for (int progress = 0; progress <= 100; progress += 2) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() {
          steps[i].progress = progress / 100;
        });
      }

      // Add longer delay between steps to make each step more visible
      await Future.delayed(const Duration(seconds: 2));

      // Mark current step as completed and activate next step
      setState(() {
        steps[i].isCompleted = true;
        steps[i].isActive = false;
        if (i < steps.length - 1) {
          steps[i + 1].isActive = true;
        }
        currentStepIndex = i + 1;
      });

      // Notify parent about step completion
      if (widget.onStepComplete != null) {
        await widget.onStepComplete!(i);
      }

      // If this was the last step, wait before completing
      if (i == steps.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
        widget.onAllStepsComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5), // Biru gelap seperti halaman utama
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              const Text(
                'File sedang di proses\nmohon tunggu sejenak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Ganti icon dengan background yang lebih gelap
              Container(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/cybersecurity-95.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              // Compact Process Steps List
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return CompactProcessStep(
                        step: step,
                        isLast: index == steps.length - 1,
                      );
                    },
                  ),
                ),
              ),
              if (currentStepIndex < steps.length) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8FDCFF)), // Biru muda
                    backgroundColor: Colors.white.withOpacity(0.2),
                    strokeWidth: 4,
                  ),
                ),
              ],
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedLoadingSpinner() {
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // Outer ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 4,
              ),
            ),
          ),
          // Animated dots
          ...List.generate(8, (index) {
            final angle = (index * pi / 4);
            final offset = 30.0;
            final delay = index * 0.1;
            
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final animationValue = (_controller.value + delay) % 1.0;
                final size = 12.0 * (1 - animationValue);
                
                return Positioned(
                  left: 40 + (offset * cos(angle)) - (size / 2),
                  top: 40 + (offset * sin(angle)) - (size / 2),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(1 - animationValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class CompactProcessStep extends StatelessWidget {
  final ProcessStep step;
  final bool isLast;

  const CompactProcessStep({
    Key? key,
    required this.step,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getStatusColor(),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _getStatusIcon(),
            ),
          ),
          const SizedBox(width: 12),
          // Step name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  step.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: step.isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (step.isActive)
                  LinearProgressIndicator(
                    value: step.progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8FDCFF)), // Biru muda
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (step.isCompleted) return Colors.green;
    if (step.isActive) return const Color(0xFF8FDCFF); // Biru muda
    return Colors.white.withOpacity(0.2);
  }

  Widget _getStatusIcon() {
    if (step.isCompleted) {
      return const Icon(Icons.check, color: Colors.white, size: 16);
    }
    if (step.isActive) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Icon(Icons.lock, color: Colors.white.withOpacity(0.7), size: 16);
  }
}

class AnimatedProcessStepCard extends StatelessWidget {
  final ProcessStep step;
  final bool isLast;
  final Animation<double> pulseAnimation;
  final Animation<double> waveAnimation;

  const AnimatedProcessStepCard({
    Key? key,
    required this.step,
    required this.isLast,
    required this.pulseAnimation,
    required this.waveAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: step.isActive
                  ? Colors.white.withOpacity(0.95)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: step.isActive
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                _buildAnimatedStatusIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: step.isActive ? Colors.blue : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (step.isActive) ...[
                        const SizedBox(height: 8),
                        _buildAnimatedProgressBar(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 2,
              height: 16,
              margin: const EdgeInsets.only(left: 24),
              color: step.isCompleted
                  ? Colors.green
                  : Colors.grey[300],
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatusIcon() {
    if (step.isCompleted) {
      return ScaleTransition(
        scale: pulseAnimation,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    if (step.isActive) {
      return RotationTransition(
        turns: waveAnimation,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock,
        color: Colors.grey[600],
        size: 20,
      ),
    );
  }

  Widget _buildAnimatedProgressBar() {
    return Stack(
      children: [
        // Background
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Animated progress
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 4,
          width: (step.progress * 100).clamp(0, 100) / 100 * 300,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}