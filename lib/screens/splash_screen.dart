//lib/screens/splash_screen.dart
import 'package:brainiacz/screens/role_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/colors.dart';
import '../utils/styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        color: const Color(0xFF0A0A0F),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with glow + border radius
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C3FD8).withOpacity(0.5),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/brainiacz_icon.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 32),

              // App name
              const Text(
                'Brainiacz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .slideY(
                    begin: 0.4,
                    end: 0,
                    delay: 400.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 10),

              // Subtitle
              const Text(
                'Smart Tutoring Platform',
                style: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              )
                  .animate()
                  .slideY(
                    begin: 0.4,
                    end: 0,
                    delay: 600.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(delay: 600.ms, duration: 600.ms),

              const SizedBox(height: 64),

              // Pulsing loading dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C3FD8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .scaleXY(
                        begin: 0.6,
                        end: 1.4,
                        delay: Duration(milliseconds: 800 + i * 150),
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scaleXY(
                        begin: 1.4,
                        end: 0.6,
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      );
                }),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}