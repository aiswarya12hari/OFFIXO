import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Same wrapper pattern as `_ProfileShimmerWrapper` in
/// profile_shimmer_widgets.dart, so both shimmer states animate with the
/// same base/highlight colors across the app.
class _WorkingHoursShimmerWrapper extends StatelessWidget {
  final Widget child;
  const _WorkingHoursShimmerWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _WorkingHoursRowShimmer extends StatelessWidget {
  const _WorkingHoursRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBox(width: 24, height: 24, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ShimmerBox(width: 110, height: 13, radius: 4),
                SizedBox(height: 6),
                _ShimmerBox(width: 150, height: 13, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full shimmer for the Total Working Hours page while the selected
/// date's attendance is loading. Mirrors the real content layout (date
/// selector bar + info card) so the swap to real data causes no shift.
class TotalWorkingHoursShimmer extends StatelessWidget {
  const TotalWorkingHoursShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        child: _WorkingHoursShimmerWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const _ShimmerBox(width: 22, height: 22, radius: 11),
                    const SizedBox(width: 12),
                    const _ShimmerBox(width: 140, height: 16, radius: 4),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info card placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(4, (index) {
                    final isLast = index == 3;
                    return Column(
                      children: [
                        const _WorkingHoursRowShimmer(),
                        if (!isLast) const Divider(),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}