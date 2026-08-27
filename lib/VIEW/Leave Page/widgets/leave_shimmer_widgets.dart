import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

/// Shared shimmer wrapper so both placeholders animate in sync
/// and use the same base/highlight colors.
class _LeaveShimmerWrapper extends StatelessWidget {
  final Widget child;
  const _LeaveShimmerWrapper({required this.child});

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

/// Placeholder for a single leave balance chip.
/// Sized to match `_LeaveBalanceChip` exactly (width 110, same internal
/// paddings/heights) so the real content swaps in with no layout shift.
class _LeaveBalanceChipShimmer extends StatelessWidget {
  const _LeaveBalanceChipShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyle.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 36, height: 14, radius: 4),
          SizedBox(height: 8),
          _ShimmerBox(width: 50, height: 20, radius: 4),
          SizedBox(height: 6),
          _ShimmerBox(width: double.infinity, height: 4, radius: 4),
          SizedBox(height: 6),
          _ShimmerBox(width: 70, height: 10, radius: 4),
        ],
      ),
    );
  }
}

/// Shimmer for the whole "Leave Balance" row while balances are loading.
/// Mirrors `_LeaveBalanceRow`'s label + horizontal row of chips.
class LeaveBalanceRowShimmer extends StatelessWidget {
  final int chipCount;
  const LeaveBalanceRowShimmer({super.key, this.chipCount = 3});

  @override
  Widget build(BuildContext context) {
    return _LeaveShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBox(width: 100, height: 13, radius: 4),
          const SizedBox(height: 10),
          Row(
            children: List.generate(chipCount, (i) {
              return Padding(
                padding: EdgeInsets.only(right: i < chipCount - 1 ? 10 : 0),
                child: const _LeaveBalanceChipShimmer(),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for the "Leave Type" dropdown field while leave types load.
/// Matches the real dropdown container's padding/border/radius and
/// default DropdownButton height (48) so nothing shifts on load.
class LeaveTypeDropdownShimmer extends StatelessWidget {
  const LeaveTypeDropdownShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _LeaveShimmerWrapper(
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppStyle.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyle.borderColor),
        ),
        alignment: Alignment.centerLeft,
        child: const _ShimmerBox(width: 140, height: 14, radius: 4),
      ),
    );
  }
}

/// Placeholder for a single leave request card.
/// Mirrors `_LeaveCard`'s structure (header + status pill, divider,
/// date row, session row, reason lines, applied-at line) so the layout
/// doesn't jump when real data swaps in.
///
/// Width is calculated the same way `_LeaveList`'s `ListView.builder`
/// computes its horizontal padding (`AppStyle.responsiveWidth(context, 20)`
/// on each side), so the shimmer card's width is an exact pixel match to
/// the real `_LeaveCard`'s rendered width rather than relying on
/// `double.infinity` filling whatever space it happens to be given.
class LeaveCardShimmer extends StatelessWidget {
  const LeaveCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width -
        (AppStyle.responsiveWidth(context, 20) * 2);

    return _LeaveShimmerWrapper(
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppStyle.whiteColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyle.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _ShimmerBox(width: 120, height: 14, radius: 4),
                Container(
                  width: 70,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white),
            const SizedBox(height: 12),
            Row(
              children: [
                const _ShimmerBox(width: 150, height: 12, radius: 4),
                const Spacer(),
                Container(
                  width: 44,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _ShimmerBox(width: 110, height: 12, radius: 4),
            const SizedBox(height: 10),
            const _ShimmerBox(width: double.infinity, height: 12, radius: 4),
            const SizedBox(height: 6),
            const _ShimmerBox(width: 180, height: 12, radius: 4),
            const SizedBox(height: 12),
            const _ShimmerBox(width: 130, height: 10, radius: 4),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for the whole leave-history list while the initial fetch is
/// in flight. Reuses the same outer padding as `_LeaveList`'s
/// `ListView.builder` so scroll content lines up once real data loads.
class LeaveListShimmer extends StatelessWidget {
  final int itemCount;
  const LeaveListShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppStyle.responsiveWidth(context, 20),
        right: AppStyle.responsiveWidth(context, 20),
        top: AppStyle.responsiveHeight(context, 20),
        bottom: AppStyle.responsiveHeight(context, 20),
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LeaveCardShimmer(),
        );
      },
    );
  }
}

/// Shimmer for the medical-certificate section while it's being fetched.
/// Matches the 50px height used by both the "Upload Certificate" button
/// and the certificate tile so there's no jump either way.
class MedicalCertificateShimmer extends StatelessWidget {
  const MedicalCertificateShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _LeaveShimmerWrapper(
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}