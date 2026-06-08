
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
  const CheckinScreen({
    super.key,
  });

  @override
  State<CheckinScreen>
      createState() =>
          _CheckinScreenState();
}

class _CheckinScreenState
    extends State<
      CheckinScreen
    > {
  CheckStatus _checkStatus =
      CheckStatus.checkedOut;

  LocationStatus
  _locationStatus =
      LocationStatus
          .withinPremises;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<
            ProfileProvider
          >()
          .fetchProfile();
    });
  }

  Future<void>
  _onRefresh() async {
    await Future.delayed(
      const Duration(
        seconds: 1,
      ),
    );

    await context
        .read<
          ProfileProvider
        >()
        .fetchProfile();

    setState(() {});
  }

  Future<void>
  _handleButtonTap() async {
    /// CHECK IN
    if (_checkStatus ==
        CheckStatus
            .checkedOut) {
      final result =
          await Navigator.of(
            context,
          ).push<bool>(
            PageRouteBuilder(
              opaque: false,
              barrierColor:
                  Colors.black
                      .withOpacity(
                        0.75,
                      ),

              barrierDismissible:
                  true,

              pageBuilder:
                  (
                    _,
                    __,
                    ___,
                  ) =>
                      const VerificationScreen(),
            ),
          );

      /// SUCCESS CHECKIN
      if (result == true &&
          mounted) {
        setState(() {
          _checkStatus =
              CheckStatus
                  .checkedIn;
        });
      }
    }

    /// CHECK OUT
    else {
      final result =
          await Navigator.of(
            context,
          ).push<bool>(
            PageRouteBuilder(
              opaque: false,
              barrierColor:
                  Colors.black
                      .withOpacity(
                        0.75,
                      ),

              barrierDismissible:
                  true,

              pageBuilder:
                  (
                    _,
                    __,
                    ___,
                  ) =>
                      const VerificationScreen(
                        isCheckout:
                            true,
                      ),
            ),
          );

      /// SUCCESS CHECKOUT
      if (result == true &&
          mounted) {
        setState(() {
          _checkStatus =
              CheckStatus
                  .checkedOut;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Check-out successful',
            ),
            duration: Duration(
              seconds: 2,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppStyle
              .backgroundColor,

      body: SafeArea(
        child:
            RefreshIndicator(
              onRefresh:
                  _onRefresh,

              child:
                  SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(
                            horizontal:
                                AppStyle.responsiveWidth(
                                  context,
                                  20,
                                ),
                            vertical:
                                AppStyle.responsiveHeight(
                                  context,
                                  35,
                                ),
                          ),

                      child:
                          Column(
                            children: [
                              /// HEADER
                              Consumer<
                                ProfileProvider
                              >(
                                builder:
                                    (
                                      context,
                                      provider,
                                      child,
                                    ) {
                                  final profile =
                                      provider.profile;

                                  return Header(
                                    userName:
                                        profile?.fullName ??
                                        "Loading...",

                                    avatarUrl:
                                        profile?.faceImage,
                                  );
                                },
                              ),

                              SizedBox(
                                height:
                                    AppStyle.responsiveHeight(
                                      context,
                                      40,
                                    ),
                              ),

                              const LiveClockWidget(),

                              SizedBox(
                                height:
                                    AppStyle.responsiveHeight(
                                      context,
                                      40,
                                    ),
                              ),

                              CheckInButton(
                                status:
                                    _checkStatus,

                                onTap:
                                    _handleButtonTap,
                              ),

                              SizedBox(
                                height:
                                    AppStyle.responsiveHeight(
                                      context,
                                      30,
                                    ),
                              ),

                              LocationBadge(
                                locationStatus:
                                    _locationStatus,

                                locationName:
                                    'Techfifo Innovations, Palakkad',
                              ),

                              Container(
                                padding:
                                    EdgeInsets.symmetric(
                                      vertical:
                                          AppStyle.responsiveHeight(
                                            context,
                                            40,
                                          ),
                                    ),

                                child:
                                    const AttendanceStatsRow(
                                      checkInTime:
                                          '--:--',

                                      totalHours:
                                          '00:00',

                                      checkOutTime:
                                          '--:--',
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