 import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

enum LocationStatus {
  withinPremises,
  outsidePremises,
}

class LocationBadge extends StatelessWidget {
  final LocationStatus locationStatus;
  final String locationName;

  const LocationBadge({
    super.key,
    required this.locationStatus,
    required this.locationName,
  });

  bool get _isWithin =>
      locationStatus == LocationStatus.withinPremises;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppStyle.responsiveWidth(context, 20),
        vertical: AppStyle.responsiveHeight(context, 10),
      ),

      decoration: BoxDecoration(
        color: AppStyle.whiteColor,

        borderRadius: BorderRadius.circular(35),

        border: Border.all(
          color: _isWithin
              ? const Color(0xFFDDDDDD)
              : const Color(0xFFFF6B00).withOpacity(0.4),
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            Icons.location_on,

            size: AppStyle.responsiveWidth(context, 18),

            color: _isWithin
                ? const Color(0xFF333B69)
                : const Color(0xFFFF6B00),
          ),

          const SizedBox(width: 6),

          Text(
            _isWithin
                ? locationName
                : 'You are not within the office premises',

            style: AppStyle.jakartaText(
              context: context,
              size: 13,

              color: _isWithin
                  ? const Color(0xFF333B69)
                  : const Color(0xFFFF6B00),

              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}