import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();

    super.dispose();
  }

  String get _formattedTime {
    final hour = _now.hour > 12
        ? _now.hour - 12
        : (_now.hour == 0 ? 12 : _now.hour);

    final minute = _now.minute.toString().padLeft(2, '0');

    final period = _now.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String get _formattedDate {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final weekday = weekdays[_now.weekday - 1];
    final month = months[_now.month - 1];
    return '$weekday, $month ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final parts = _formattedTime.split(' ');
    final timePart = parts[0];
    final periodPart = parts[1];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,

          children: [
            Text(
              timePart,

              style: AppStyle.jakartaText(
                context: context,
                size: 44,
                weight: FontWeight.w600,
                color: const Color(0xFF232323),
                height: 1,
              ),
            ),

            SizedBox(width: AppStyle.responsiveWidth(context, 6)),

            Text(
              periodPart,
              style: AppStyle.jakartaText(
                context: context,
                size: 24,
                weight: FontWeight.w600,
                color: const Color(0xFF232323),
              ),
            ),
          ],
        ),

        SizedBox(height: AppStyle.responsiveHeight(context, 4)),

        Text(
          _formattedDate,
          style: AppStyle.jakartaText(
            context: context,
            size: 13,
            color: const Color(0xFF333B69),
            weight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}
