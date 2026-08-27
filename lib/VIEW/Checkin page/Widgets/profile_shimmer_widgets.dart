import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer wrapper so all profile placeholders animate in sync
/// and use the same base/highlight colors as the rest of the app
/// (matches `_LeaveShimmerWrapper` in leave_shimmer_widgets.dart).
class _ProfileShimmerWrapper extends StatelessWidget {
  final Widget child;
  const _ProfileShimmerWrapper({required this.child});

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

/// Placeholder for a single `_profileRow` entry (icon + label + value).
/// The icon circle here is a static grey placeholder, not shimmered
/// individually — only the label/value text bars shimmer, matching how
/// the leave cards shimmer their text while keeping structural chrome
/// (borders, pill shapes) as part of the same wrapped white content.
class _ProfileRowShimmer extends StatelessWidget {
  const _ProfileRowShimmer();

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
                _ShimmerBox(width: 90, height: 13, radius: 4),
                SizedBox(height: 6),
                _ShimmerBox(width: 160, height: 13, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-page shimmer for the Profile screen while `ProfileProvider` is
/// fetching data. Mirrors `ProfileScreen`'s real layout exactly (same
/// outer padding, avatar position, spacing, card padding/radius, and
/// row count) so the swap to real content causes no layout shift.
///
/// The avatar circle is intentionally left as a static placeholder
/// (NOT wrapped in the shimmer) per the profile icon/avatar exclusion
/// requirement — only the text and info-card content shimmer.
class ProfileScreenShimmer extends StatelessWidget {
  const ProfileScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Static (non-shimmering) avatar placeholder — matches the
            // real CircleAvatar's radius exactly.
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 15),

            _ProfileShimmerWrapper(
              child: Column(
                children: [
                  const _ShimmerBox(width: 160, height: 20, radius: 4),
                  const SizedBox(height: 8),
                  const _ShimmerBox(width: 110, height: 13, radius: 4),

                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: List.generate(14, (index) {
                        final isLast = index == 13;
                        return Column(
                          children: [
                            const _ProfileRowShimmer(),
                            if (!isLast) const Divider(),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}