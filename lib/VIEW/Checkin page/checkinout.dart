import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Profile%20Page/profile_provider.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/attendance_stats_row.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/check_in_button.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/header.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/live_clock_widget.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/location_badge.dart';
import 'package:offixo/VIEW/Verification%20page/verification_screen.dart';
import 'package:provider/provider.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  CheckStatus _checkStatus = CheckStatus.checkedOut;

  LocationStatus _locationStatus = LocationStatus.withinPremises;

  DateTime? _checkInTime;
  DateTime? _checkOutTime;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  // ───────────────── TIME HELPERS ─────────────────

  String get _checkInDisplay {
    if (_checkInTime == null) return '--:--';
    return _formatHHMM(_checkInTime!);
  }

  String get _checkOutDisplay {
    if (_checkOutTime == null) return '--:--';
    return _formatHHMM(_checkOutTime!);
  }

  String get _totalHoursDisplay {
    if (_checkInTime == null) return '00:00';

    final end = _checkOutTime ?? DateTime.now();
    final diff = end.difference(_checkInTime!);

    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');

    return '$h:$m';
  }

  String _formatHHMM(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    await context.read<ProfileProvider>().fetchProfile();
    setState(() {});
  }

  // ───────────────── BUTTON ACTION ─────────────────

  void _handleButtonTap() {
    /// FAILED CHECK-IN (OUTSIDE AREA)
    if (_checkStatus == CheckStatus.checkedOut &&
        _locationStatus == LocationStatus.outsidePremises) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.75),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) => const VerificationScreen(
            isSuccess: false,
            title: 'Check-in Failed ❌',
            message: 'You are outside the authorized area',
            successMessage: '', // not used
          ),
        ),
      );
      return;
    }

    /// CHECK IN
    if (_checkStatus == CheckStatus.checkedOut) {
      setState(() {
        _checkInTime = DateTime.now();
        _checkOutTime = null;
        _checkStatus = CheckStatus.checkedIn;
      });

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.75),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) => const VerificationScreen(
            isSuccess: true,
            title: 'Success 🎉',
            message: 'Verifying check-in...',
            successMessage: "You're checked in successfully.",
          ),
        ),
      );
    }

    /// CHECK OUT
    else {
      setState(() {
        _checkOutTime = DateTime.now();
        _checkStatus = CheckStatus.checkedOut;
      });

      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.75),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) => const VerificationScreen(
            isSuccess: true,
            title: 'Success 🎉',
            message: 'Verifying check-out...',
            successMessage: "You're checked out successfully.",
          ),
        ),
      );
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppStyle.responsiveWidth(context, 20),
                vertical: AppStyle.responsiveHeight(context, 35),
              ),

              child: Column(
                children: [
                  /// HEADER
                  Consumer<ProfileProvider>(
                    builder: (context, provider, child) {
                      final profile = provider.profile;

                      return Header(
                        userName: profile?.fullName ?? "Loading...",
                        avatarUrl: profile?.faceImage,
                      );
                    },
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 40)),

                  const LiveClockWidget(),

                  SizedBox(height: AppStyle.responsiveHeight(context, 40)),

                  CheckInButton(
                    status: _checkStatus,
                    onTap: _handleButtonTap,
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 30)),

                  LocationBadge(
                    locationStatus: _locationStatus,
                    locationName: 'Techfifo Innovations, Palakkad',
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: AppStyle.responsiveHeight(context, 40),
                    ),
                    child: AttendanceStatsRow(
                      checkInTime: _checkInDisplay,
                      totalHours: _totalHoursDisplay,
                      checkOutTime: _checkOutDisplay,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}