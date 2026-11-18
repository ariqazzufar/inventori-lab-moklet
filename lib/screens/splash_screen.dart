import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _spinController;
  late AnimationController _verifyController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _verifyCurve;

  static const Color bcaNavy = Color(0xFF003D79);
  static const Color bcaBlue = Color(0xFF0060AF);
  static const Color bcaCyan = Color(0xFF00AEEF);

  @override
  void initState() {
    super.initState();

    // 1. Animasi masuk emblem & teks
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entryController.forward();

    // 2. Animasi putaran ring yang berkelanjutan (tidak berhenti mendadak)
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();

    // 3. Animasi transisi ke status terverifikasi (menutup lingkaran + menggambar centang)
    _verifyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _verifyCurve = CurvedAnimation(
      parent: _verifyController,
      curve: Curves.easeInOutCubic,
    );

    // Mulai transisi verifikasi di detik ke-1.85
    Timer(const Duration(milliseconds: 1850), () {
      if (!mounted) return;
      _verifyController.forward();
      HapticFeedback.lightImpact();
    });

    // Navigasi mulus ke halaman berikutnya di detik ke-3.0
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (_, __, ___) =>
              user != null ? const MainNavScreen() : const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.04, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _spinController.dispose();
    _verifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF002147), bcaNavy, bcaBlue],
          ),
        ),
        child: Stack(
          children: [
            // Ornamen Latar Belakang
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: bcaCyan.withOpacity(0.14),
                    width: 32,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Logo Utama + Smooth Face ID Ring Painter
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_spinController, _verifyCurve]),
                        builder: (context, _) {
                          final double verifyProgress = _verifyCurve.value;
                          final Color activeGlowColor = Color.lerp(
                            bcaCyan,
                            const Color(0xFF00E676),
                            verifyProgress,
                          )!;

                          // Efek denyut ringan saat centang selesai tergambar
                          final double pulseScale = 1.0 +
                              (math.sin(verifyProgress * math.pi) * 0.045);

                          return Transform.scale(
                            scale: pulseScale,
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // CustomPainter untuk Ring Mulus 360 derajat
                                  CustomPaint(
                                    size: const Size(142, 142),
                                    painter: _FaceIdRingPainter(
                                      spinProgress: _spinController.value,
                                      verifyProgress: verifyProgress,
                                      scanColor: bcaCyan,
                                      verifiedColor: const Color(0xFF00E676),
                                    ),
                                  ),

                                  // Lingkaran Emblem Putih di Tengah
                                  Container(
                                    width: 112,
                                    height: 112,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: activeGlowColor
                                              .withOpacity(0.35),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Ikon Lab mengecil & memudar mulus
                                        Opacity(
                                          opacity: (1.0 - (verifyProgress * 1.6))
                                              .clamp(0.0, 1.0),
                                          child: Transform.scale(
                                            scale: 1.0 - (verifyProgress * 0.3),
                                            child: const Icon(
                                              Icons.biotech_rounded,
                                              size: 56,
                                              color: bcaNavy,
                                            ),
                                          ),
                                        ),

                                        // Ikon Centang tergambar mulus dari kiri ke kanan
                                        if (verifyProgress > 0.15)
                                          CustomPaint(
                                            size: const Size(54, 54),
                                            painter: _AnimatedCheckPainter(
                                              progress:
                                                  ((verifyProgress - 0.15) /
                                                          0.85)
                                                      .clamp(0.0, 1.0),
                                              color: const Color(0xFF00A86B),
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
                      const SizedBox(height: 24),
                      const Text(
                        'Inventaris Lab RPL',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: bcaCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: bcaCyan.withOpacity(0.55)),
                        ),
                        child: const Text(
                          'SMK Telkom Malang',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Bawah dengan Transisi Teks Halus
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: AnimatedBuilder(
                  animation: _verifyCurve,
                  builder: (context, _) {
                    final isDone = _verifyCurve.value > 0.6;
                    return Column(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isDone
                                ? 'Sistem Siap Digunakan'
                                : 'Memuat Layanan Inventaris...',
                            key: ValueKey(isDone),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sistem Manajemen Peminjaman Laboratorium',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter untuk Ring yang berputar mulus lalu menyatu 360 derajat
class _FaceIdRingPainter extends CustomPainter {
  final double spinProgress;
  final double verifyProgress;
  final Color scanColor;
  final Color verifiedColor;

  _FaceIdRingPainter({
    required this.spinProgress,
    required this.verifyProgress,
    required this.scanColor,
    required this.verifiedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // 1. Track lingkaran latar belakang tipis
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Busur aktif yang memanjang dari 220 derajat menjadi 360 derajat penuh
    final currentColor = Color.lerp(scanColor, verifiedColor, verifyProgress)!;
    final activePaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final double startAngle =
        (spinProgress * 2 * math.pi) - (math.pi / 2);
    final double baseSweep = math.pi * 1.25; // ~225 derajat saat memindai
    final double sweepAngle =
        baseSweep + ((2 * math.pi - baseSweep) * verifyProgress);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceIdRingPainter oldDelegate) {
    return oldDelegate.spinProgress != spinProgress ||
        oldDelegate.verifyProgress != verifyProgress;
  }
}

// Painter untuk menggambar garis centang secara progresif (stroke path)
class _AnimatedCheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedCheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Offset(size.width * 0.22, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.72);
    final p3 = Offset(size.width * 0.78, size.height * 0.30);

    final path = Path()..moveTo(p1.dx, p1.dy);

    if (progress <= 0.45) {
      final t = progress / 0.45;
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - 0.45) / 0.55;
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedCheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}