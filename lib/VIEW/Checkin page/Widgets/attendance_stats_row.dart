import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class AttendanceStatsRow extends StatelessWidget {
  final String checkInTime;
  final String totalHours;
  final String? checkOutTime;

  const AttendanceStatsRow({
    super.key,
    required this.checkInTime,
    required this.totalHours,
    this.checkOutTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppStyle.responsiveWidth(context, 12),
        vertical: AppStyle.responsiveHeight(context, 6),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,

        children: [
          Expanded(
            child: _StatItem(
              context: context,
              svgPath: 'assets/svg/clock-arrow-up.svg',
              value: checkInTime,
              label: 'Check in',
            ),
          ),

          Expanded(
            child: _StatItem(
              context: context,
              svgPath: 'assets/svg/clock-arrow-down.svg',
              value: totalHours,
              label: 'Total Hours',
            ),
          ),

          Expanded(
            child: _StatItem(
              context: context,
              svgPath: 'assets/svg/clock-check.svg',
              value: checkOutTime ?? '--:--',
              label: 'Check out',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final BuildContext context;
  final String svgPath;
  final String value;
  final String label;

  const _StatItem({
    required this.context,
    required this.svgPath,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext _) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        /// SVG ICON
        SvgPicture.asset(
          svgPath,

          width: AppStyle.responsiveWidth(context, 28.33),

          height: AppStyle.responsiveWidth(context, 28.33),

          colorFilter: const ColorFilter.mode(
            AppStyle.primaryColor,
            BlendMode.srcIn,
          ),
        ),

        SizedBox(height: AppStyle.responsiveHeight(context, 8)),

        /// VALUE
        Text(
          value,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: AppStyle.jakartaText(
            context: context,

            size: 18,

            weight: FontWeight.w700,

            color: const Color(0xFF232323),
          ),
        ),

        SizedBox(height: AppStyle.responsiveHeight(context, 4)),

        /// LABEL
        Text(
          label,

          textAlign: TextAlign.center,

          style: AppStyle.jakartaText(
            context: context,

            size: 12,

            color: const Color(0xFF333B69),

            weight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
