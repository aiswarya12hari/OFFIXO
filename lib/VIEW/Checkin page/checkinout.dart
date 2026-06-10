import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Profile%20Page/profile_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/attendance_stats_row.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/check_in_button.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/header.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/live_clock_widget.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/location_badge.dart';
import 'package:offixo/VIEW/Verification%20page/verification_screen.dart';
import 'package:provider/provider.dart';
import 'package:offixo/PROVIDER/Checkin Page/attendance_status_provider.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  CheckStatus _checkStatus = CheckStatus.checkedOut;
  LocationStatus _locationStatus = LocationStatus.withinPremises;

  @override
  void initState() {
    super.initState();

    // Listen to provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkInProvider = context.read<CheckInProvider>();
      final checkOutProvider = context.read<CheckOutProvider>();

      // Add listeners to update button state
      checkInProvider.addListener(_onCheckInProviderChanged);
      checkOutProvider.addListener(_onCheckOutProviderChanged);
    });

    Future.microtask(() async {
      await context.read<ProfileProvider>().fetchProfile();

      await context.read<AttendanceStatusProvider>().fetchStatus();
    });
  }

  @override
  void dispose() {
    // Remove listeners
    context.read<CheckInProvider>().removeListener(_onCheckInProviderChanged);
    context.read<CheckOutProvider>().removeListener(_onCheckOutProviderChanged);
    super.dispose();
  }

  void _onCheckInProviderChanged() {
    final checkInProvider = context.read<CheckInProvider>();
    // Update button state on successful check-in
    if (checkInProvider.isSuccess && mounted) {
      setState(() {
        _checkStatus = CheckStatus.checkedIn;
      });
    }
  }

  void _onCheckOutProviderChanged() {
    final checkOutProvider = context.read<CheckOutProvider>();
    // Update button state on successful check-out
    if (checkOutProvider.isSuccess && mounted) {
      setState(() {
        _checkStatus = CheckStatus.checkedOut;
      });

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-out successful'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    await context.read<ProfileProvider>().fetchProfile();

    await context.read<AttendanceStatusProvider>().fetchStatus();
  }

  Future<void> _handleButtonTap() async {
    /// CHECK IN
    if (_checkStatus == CheckStatus.checkedOut) {
      final result = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.75),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) => const VerificationScreen(),
        ),
      );

      /// SUCCESS CHECKIN
      if (result == true && mounted) {
        // Reset checkout provider when checking in
        context.read<CheckOutProvider>().reset();
        setState(() {
          _checkStatus = CheckStatus.checkedIn;
        });
        await context.read<AttendanceStatusProvider>().fetchStatus();
      }
    }
    /// CHECK OUT
    else {
      final result = await Navigator.of(context).push<bool>(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.75),
          barrierDismissible: true,
          pageBuilder: (_, __, ___) =>
              const VerificationScreen(isCheckout: true),
        ),
      );

      /// SUCCESS CHECKOUT
      if (result == true && mounted) {
        // Reset check-in provider when checking out
        context.read<CheckInProvider>().reset();
        await context.read<AttendanceStatusProvider>().fetchStatus();
        // Button state will be updated by the listener
      }
    }
  }

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

                  CheckInButton(status: _checkStatus, onTap: _handleButtonTap),

                  SizedBox(height: AppStyle.responsiveHeight(context, 30)),

                  // ✅ Use Consumer to get organization name from ProfileProvider
                  Consumer<ProfileProvider>(
                    builder: (context, provider, child) {
                      final organizationName =
                          provider.profile?.organizationName ?? 'Loading...';

                      return LocationBadge(
                        locationStatus: _locationStatus,
                        locationName:
                            organizationName, // Pass dynamic organization name
                      );
                    },
                  ),

                  Consumer<AttendanceStatusProvider>(
                    builder: (context, attendanceProvider, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          vertical: AppStyle.responsiveHeight(context, 40),
                        ),
                        child: AttendanceStatsRow(
                          checkInTime: attendanceProvider.checkInTime,
                          totalHours: attendanceProvider.totalHours,
                          checkOutTime: attendanceProvider.checkOutTime,
                        ),
                      );
                    },
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
