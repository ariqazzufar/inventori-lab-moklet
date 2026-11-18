import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final ValueNotifier<double> _pageNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _isInteractingNotifier = ValueNotifier<bool>(false);

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  static const Color bcaNavy = Color(0xFF003D79);
  static const Color bcaBlue = Color(0xFF0060AF);
  static const Color bcaCyan = Color(0xFF00AEEF);

  // Ketiga halaman langsung dimuat di belakang layar sejak awal
  final List<Widget> _pages = const [
    HomeScreen(),
    InventoryScreen(),
    ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = const [
    {
      'icon': Icons.home_outlined,
      'activeIcon': Icons.home_rounded,
      'label': 'Beranda',
    },
    {
      'icon': Icons.inventory_2_outlined,
      'activeIcon': Icons.inventory_2_rounded,
      'label': 'Inventaris',
    },
    {
      'icon': Icons.person_outline_rounded,
      'activeIcon': Icons.person_rounded,
      'label': 'Profil',
    },
  ];

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _snapAnimation = const AlwaysStoppedAnimation<double>(0.0);
    _snapController.addListener(() {
      _pageNotifier.value = _snapAnimation.value;
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    _pageNotifier.dispose();
    _isInteractingNotifier.dispose();
    super.dispose();
  }

  void _animateToPage(int targetIndex, {Curve curve = Curves.easeOutCubic}) {
    final int clampedTarget = targetIndex.clamp(0, _pages.length - 1);
    if (_selectedIndex != clampedTarget) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = clampedTarget;
      });
    }

    _snapAnimation = Tween<double>(
      begin: _pageNotifier.value,
      end: clampedTarget.toDouble(),
    ).animate(CurvedAnimation(parent: _snapController, curve: curve));

    _snapController
      ..reset()
      ..forward();
  }

  // Geser layar utama (kiri/kanan) tanpa memblokir klik maupun scroll vertikal
  void _handleBodyHorizontalDragUpdate(
      DragUpdateDetails details, double screenWidth) {
    _snapController.stop();
    final double deltaPage = -details.delta.dx / screenWidth;
    final double nextValue = (_pageNotifier.value + deltaPage)
        .clamp(0.0, (_pages.length - 1).toDouble());
    _pageNotifier.value = nextValue;
  }

  void _handleBodyHorizontalDragEnd(DragEndDetails details) {
    _isInteractingNotifier.value = false;
    final double velocity = details.primaryVelocity ?? 0.0;
    int targetPage = _pageNotifier.value.round();

    if (velocity < -320) {
      targetPage = (_selectedIndex + 1).clamp(0, _pages.length - 1);
    } else if (velocity > 320) {
      targetPage = (_selectedIndex - 1).clamp(0, _pages.length - 1);
    }

    _animateToPage(targetPage, curve: Curves.easeOutCubic);
  }

  // Geser langsung pada kapsul Liquid Glass Navbar
  void _handleNavbarScrub(Offset localPosition, double totalWidth) {
    _snapController.stop();
    final double usableWidth = totalWidth - 10;
    final double tabWidth = usableWidth / _navItems.length;
    final double clampedX = (localPosition.dx - 5).clamp(0.0, usableWidth);

    final double targetPage = ((clampedX - (tabWidth / 2)) / tabWidth)
        .clamp(0.0, (_navItems.length - 1).toDouble());
    _pageNotifier.value = targetPage;
  }

  void _handleNavbarScrubEnd() {
    _isInteractingNotifier.value = false;
    final int nearestPage = _pageNotifier.value.round();
    _animateToPage(nearestPage, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBody: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          _isInteractingNotifier.value = true;
        },
        onHorizontalDragUpdate: (details) =>
            _handleBodyHorizontalDragUpdate(details, screenWidth),
        onHorizontalDragEnd: _handleBodyHorizontalDragEnd,
        onHorizontalDragCancel: () {
          _isInteractingNotifier.value = false;
          _animateToPage(_pageNotifier.value.round());
        },
        child: ValueListenableBuilder<double>(
          valueListenable: _pageNotifier,
          builder: (context, currentPage, _) {
            return Stack(
              children: List.generate(_pages.length, (index) {
                final double offset = index - currentPage;
                final bool isVisible = offset.abs() < 1.05;

                return FractionalTranslation(
                  translation: Offset(offset, 0.0),
                  child: IgnorePointer(
                    ignoring: offset.abs() > 0.05,
                    child: Visibility(
                      visible: isVisible,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: _pages[index],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, outerConstraints) {
                final double navbarWidth = outerConstraints.maxWidth;

                // Listener menangkap sentuhan pertama (onPointerDown) secara instan
                // tanpa menunda maupun berebut gestur dengan tap & horizontal drag
                return Listener(
                  onPointerDown: (_) {
                    if (!_isInteractingNotifier.value) {
                      HapticFeedback.lightImpact();
                      _isInteractingNotifier.value = true;
                    }
                  },
                  onPointerUp: (_) {
                    if (_isInteractingNotifier.value) {
                      _isInteractingNotifier.value = false;
                    }
                  },
                  onPointerCancel: (_) {
                    if (_isInteractingNotifier.value) {
                      _isInteractingNotifier.value = false;
                    }
                  },
                  child: GestureDetector(
                    onHorizontalDragStart: (details) {
                      _isInteractingNotifier.value = true;
                      _handleNavbarScrub(details.localPosition, navbarWidth);
                    },
                    onHorizontalDragUpdate: (details) {
                      _handleNavbarScrub(details.localPosition, navbarWidth);
                    },
                    onHorizontalDragEnd: (_) => _handleNavbarScrubEnd(),
                    onHorizontalDragCancel: () => _handleNavbarScrubEnd(),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isInteractingNotifier,
                      builder: (context, isInteracting, child) {
                        return AnimatedScale(
                          scale: isInteracting ? 0.94 : 1.0,
                          duration:
                              Duration(milliseconds: isInteracting ? 110 : 300),
                          curve: isInteracting
                              ? Curves.easeOutCubic
                              : Curves.easeOutBack,
                          child: child,
                        );
                      },
                      child: Container(
                        height: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(33),
                          boxShadow: [
                            BoxShadow(
                              color: bcaNavy.withOpacity(0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(33),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withOpacity(0.32),
                                    const Color(0xFFE3F2FD).withOpacity(0.18),
                                    Colors.white.withOpacity(0.26),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(33),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1.5,
                                ),
                              ),
                              child: AnimatedBuilder(
                                animation: Listenable.merge(
                                    [_pageNotifier, _isInteractingNotifier]),
                                builder: (context, _) {
                                  final double currentPage =
                                      _pageNotifier.value;
                                  final double rawFraction =
                                      (currentPage - currentPage.round())
                                              .abs() *
                                          2.0;
                                  final double smoothWave = math.sin(
                                      (rawFraction.clamp(0.0, 1.0)) *
                                          (math.pi / 2));

                                  final bool isInteracting =
                                      _isInteractingNotifier.value;

                                  return LayoutBuilder(
                                    builder: (context, innerConstraints) {
                                      final int count = _navItems.length;
                                      final double tabWidth =
                                          innerConstraints.maxWidth / count;

                                      final double baseWidth = isInteracting
                                          ? tabWidth * 0.90
                                          : tabWidth;
                                      final double stretchBonus =
                                          smoothWave * (tabWidth * 0.22);
                                      final double pillWidth =
                                          (baseWidth + stretchBonus).clamp(
                                              24.0, innerConstraints.maxWidth);

                                      final double pillCenterX =
                                          (currentPage + 0.5) * tabWidth;
                                      final double pillLeft =
                                          (pillCenterX - (pillWidth / 2))
                                              .clamp(
                                                  0.0,
                                                  innerConstraints.maxWidth -
                                                      pillWidth);

                                      final double vInset =
                                          (isInteracting ? 1.5 : 0.0) +
                                              (smoothWave * 1.5);

                                      return Stack(
                                        children: [
                                          Positioned(
                                            left: pillLeft,
                                            top: vInset,
                                            bottom: vInset,
                                            width: pillWidth,
                                            child: AnimatedContainer(
                                              duration: Duration(
                                                  milliseconds:
                                                      isInteracting ? 90 : 220),
                                              curve: Curves.easeOutCubic,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    bcaNavy.withOpacity(0.95),
                                                    bcaBlue.withOpacity(0.92),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                                border: Border.all(
                                                  color:
                                                      bcaCyan.withOpacity(0.75),
                                                  width: 1.2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: bcaBlue
                                                        .withOpacity(0.32),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children:
                                                List.generate(count, (index) {
                                              final item = _navItems[index];
                                              final double proximity = (1.0 -
                                                      (currentPage - index)
                                                          .abs())
                                                  .clamp(0.0, 1.0);
                                              final bool isActive =
                                                  proximity > 0.5;

                                              final Color itemColor =
                                                  Color.lerp(
                                                bcaNavy.withOpacity(0.85),
                                                Colors.white,
                                                proximity,
                                              )!;

                                              return Expanded(
                                                child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () => _animateToPage(
                                                      index,
                                                      curve:
                                                          Curves.easeOutBack),
                                                  child: Transform.scale(
                                                    scale: 0.93 +
                                                        (proximity * 0.09),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          isActive
                                                              ? item[
                                                                  'activeIcon']
                                                              : item['icon'],
                                                          size: 22,
                                                          color: itemColor,
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          item['label'],
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: isActive
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .w600,
                                                            color: itemColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}