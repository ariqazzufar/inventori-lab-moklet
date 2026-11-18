import 'package:flutter/material.dart';

class ShimmerSkeleton extends StatefulWidget {
  final Widget child;
  const ShimmerSkeleton({super.key, required this.child});

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double slide = (_controller.value * 2) - 0.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + slide, -0.2),
              end: Alignment(0.5 + slide, 0.2),
              colors: const [
                Color(0xFFE1E8F2),
                Color(0xFFF5F8FC),
                Color(0xFFE1E8F2),
              ],
              stops: const [0.1, 0.5, 0.9],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE1E8F2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class HomeSectionSkeleton extends StatelessWidget {
  const HomeSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 150, height: 18, radius: 6),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: 155,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 155, height: 100, radius: 14),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 115, height: 14),
                            SizedBox(height: 6),
                            SkeletonBox(width: 80, height: 10),
                            SizedBox(height: 8),
                            SkeletonBox(width: 65, height: 18, radius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SkeletonBox(width: 160, height: 18, radius: 6),
            const SizedBox(height: 12),
            const Row(
              children: [
                SkeletonBox(width: 90, height: 38, radius: 12),
                SizedBox(width: 10),
                SkeletonBox(width: 105, height: 38, radius: 12),
                SizedBox(width: 10),
                SkeletonBox(width: 85, height: 38, radius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VerticalListSkeleton extends StatelessWidget {
  final int itemCount;
  const VerticalListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 58, height: 58, radius: 10),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 15),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SkeletonBox(width: 95, height: 12),
                        SizedBox(width: 8),
                        SkeletonBox(width: 60, height: 16, radius: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BorrowerInfoSkeleton extends StatelessWidget {
  const BorrowerInfoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 180, height: 16),
            SizedBox(height: 14),
            SkeletonBox(width: 210, height: 13),
            SizedBox(height: 8),
            SkeletonBox(width: 170, height: 13),
            SizedBox(height: 8),
            SkeletonBox(width: 190, height: 13),
            SizedBox(height: 10),
            SkeletonBox(width: 160, height: 24, radius: 8),
          ],
        ),
      ),
    );
  }
}