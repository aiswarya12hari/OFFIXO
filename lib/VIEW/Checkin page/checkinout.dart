import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Checkin%20Page/break_provider.dart';
import 'package:offixo/PROVIDER/Profile%20Page/profile_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkin_provider.dart';
import 'package:offixo/PROVIDER/Verification%20Page/checkout_provider.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/attendance_stats_row.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/break_button.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/check_in_button.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/header.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/live_clock_widget.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/location_badge.dart';
import 'package:offixo/VIEW/Verification%20page/verification_screen.dart';
import 'package:provider/provider.dart';
import 'package:offixo/PROVIDER/Checkin Page/attendance_status_provider.dart';
import 'package:offixo/PROVIDER/Checkin Page/attendance_type_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:offixo/SERVICES/battery_saver_service.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/battery_saver_dialog.dart';

/// Local state describing whether we currently have a fresh, usable
/// location fix for the LOCATION_BASED flow. Drives whether the check-in /
/// check-out button is enabled.
enum _LocationFixStatus { idle, loading, ready, failed }

class CheckinScreen extends StatefulWidget {
  final bool showNetworkError;

  const CheckinScreen({super.key, this.showNetworkError = false});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  CheckStatus _checkStatus = CheckStatus.checkedOut;
  LocationStatus _locationStatus = LocationStatus.withinPremises;
  bool _initialStatusLoading = true;

  /// LOCATION_BASED flow state
  Position? _currentPosition;
  _LocationFixStatus _fixStatus = _LocationFixStatus.idle;
  String _locationErrorMessage = '';

  /// Guards against a second check-in/check-out submission firing while
  /// the first one is still in flight (e.g. a double tap before
  /// _checkStatus has had a chance to update from the first request's
  /// response). Without this, a fast second tap can reach the backend
  /// while the button still shows the pre-submission state, and the
  /// backend correctly rejects it as a duplicate active session.
  bool _isSubmitting = false;

  /// Cached provider references, captured while the widget is still
  /// mounted, so dispose() doesn't need to call context.read() after the
  /// element has already been unlinked from the tree (which triggers
  /// "Looking up a deactivated widget's ancestor is unsafe").
  CheckInProvider? _checkInProviderRef;
  CheckOutProvider? _checkOutProviderRef;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkInProvider = context.read<CheckInProvider>();
      final checkOutProvider = context.read<CheckOutProvider>();

      _checkInProviderRef = checkInProvider;
      _checkOutProviderRef = checkOutProvider;

      checkInProvider.addListener(_onCheckInProviderChanged);
      checkOutProvider.addListener(_onCheckOutProviderChanged);

      /// Show network error banner if splash screen detected no internet
      /// while re-validating a saved session.
      if (widget.showNetworkError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No internet connection. Some information may be outdated.',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    Future.microtask(() async {
      await context.read<ProfileProvider>().fetchProfile();

      await context.read<AttendanceTypeProvider>().fetchAttendanceType();

      await context.read<AttendanceStatusProvider>().fetchStatus();

      // Restore the persisted break state (see BreakProvider.hydrate) so
      // "Resume Work" survives an app restart while a break is still
      // active. This was previously never called, which is why the break
      // state was lost on app relaunch even though it was already being
      // saved to SharedPreferences correctly.
      await context.read<BreakProvider>().hydrate();

      if (!mounted) return;

      final isCheckedIn = context.read<AttendanceStatusProvider>().isCheckedIn;

      setState(() {
        _checkStatus = isCheckedIn
            ? CheckStatus.checkedIn
            : CheckStatus.checkedOut;
        _initialStatusLoading = false;
      });

      /// For LOCATION_BASED orgs, the Home screen asks for the user's
      /// location up front so the button can be gated on it, instead of
      /// waiting for a button tap (that's the FACE_BASED flow's job).
      if (context.read<AttendanceTypeProvider>().isLocationBased) {
        await _fetchFreshLocation();
      }
    });
  }

  @override
  void dispose() {
    _checkInProviderRef?.removeListener(_onCheckInProviderChanged);
    _checkOutProviderRef?.removeListener(_onCheckOutProviderChanged);
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

    await context.read<AttendanceTypeProvider>().fetchAttendanceType();

    await context.read<AttendanceStatusProvider>().fetchStatus();

    if (!mounted) return;

    final isCheckedIn = context.read<AttendanceStatusProvider>().isCheckedIn;

    setState(() {
      _checkStatus = isCheckedIn
          ? CheckStatus.checkedIn
          : CheckStatus.checkedOut;
    });

    if (context.read<AttendanceTypeProvider>().isLocationBased) {
      await _fetchFreshLocation();
    }
  }

  /// Clears any previously stored position and fetches a brand-new fix.
  /// This is intentionally called before every check-in/out attempt (and
  /// on pull-to-refresh) rather than reusing a cached position, since the
  /// user's location can genuinely change between actions.
  Future<void> _fetchFreshLocation() async {
    setState(() {
      _currentPosition = null;
      _fixStatus = _LocationFixStatus.loading;
      _locationErrorMessage = '';
    });

    try {
      final batterySaverOn = await BatterySaverService.instance
          .isBatterySaverOn();

      if (batterySaverOn) {
        if (mounted) {
          setState(() {
            _fixStatus = _LocationFixStatus.failed;
            _locationErrorMessage =
                'Battery Saver is on. Turn it off to check in/out accurately.';
          });

          await BatterySaverDialog.show(context);
        }
        return;
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (mounted) {
          setState(() {
            _fixStatus = _LocationFixStatus.failed;
            _locationErrorMessage = 'Please enable location services.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _fixStatus = _LocationFixStatus.failed;
              _locationErrorMessage = 'Location permission is required.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (mounted) {
          setState(() {
            _fixStatus = _LocationFixStatus.failed;
            _locationErrorMessage =
                'Location permission is required. Please enable it in settings.';
          });
        }
        return;
      }

      Position position;
      int retryCount = 0;

      do {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        if (position.accuracy <= 20) break;

        retryCount++;
        await Future.delayed(const Duration(seconds: 2));
      } while (retryCount < 3);

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _fixStatus = _LocationFixStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _fixStatus = _LocationFixStatus.failed;
        _locationErrorMessage =
            'Could not get your location. Please try again.';
      });
    }
  }

  Future<void> _handleButtonTap() async {
    // Ignore taps while a previous check-in/check-out is still in flight.
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final isLocationBased = context
          .read<AttendanceTypeProvider>()
          .isLocationBased;

      if (isLocationBased) {
        await _handleLocationBasedTap();
      } else {
        await _handleFaceBasedTap();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// LOCATION_BASED flow: no camera, submit straight to the
  /// location-checkin / location-checkout API using the position already
  /// fetched on Home load (or refetched below on retry).
  Future<void> _handleLocationBasedTap() async {
    if (_fixStatus != _LocationFixStatus.ready || _currentPosition == null) {
      // Shouldn't normally happen since the button is disabled in this
      // state, but retry fetching just in case.
      await _fetchFreshLocation();
      return;
    }

    final position = _currentPosition!;

    if (_checkStatus == CheckStatus.checkedOut) {
      final checkInProvider = context.read<CheckInProvider>();

      await checkInProvider.submitLocationCheckIn(prefetchedPosition: position);

      if (!mounted) return;

      if (checkInProvider.isSuccess) {
        context.read<CheckOutProvider>().reset();

        setState(() => _checkStatus = CheckStatus.checkedIn);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful'),
            duration: Duration(seconds: 2),
          ),
        );

        await context.read<AttendanceStatusProvider>().fetchStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkInProvider.errorMessage.isNotEmpty
                  ? checkInProvider.errorMessage
                  : 'Check-in failed',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      final checkOutProvider = context.read<CheckOutProvider>();

      await checkOutProvider.submitLocationCheckOut(
        prefetchedPosition: position,
      );

      if (!mounted) return;

      if (checkOutProvider.isSuccess) {
        context.read<CheckInProvider>().reset();
        context.read<BreakProvider>().resetAll();

        await _onRefresh();
        // Success snackbar is already handled by _onCheckOutProviderChanged
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              checkOutProvider.errorMessage.isNotEmpty
                  ? checkOutProvider.errorMessage
                  : 'Check-out failed',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    // Clear and refetch location for the next attempt, win or lose.
    await _fetchFreshLocation();
  }

  /// FACE_BASED flow — unchanged from the current app: navigates to the
  /// camera-based VerificationScreen which does face + location checks.
  Future<void> _handleFaceBasedTap() async {
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
        context.read<BreakProvider>().resetAll();
        // await context.read<AttendanceStatusProvider>().fetchStatus();
        await _onRefresh();
        // Button state will be updated by the listener
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    final attendanceTypeProvider = context.watch<AttendanceTypeProvider>();
    final isLocationBased = attendanceTypeProvider.isLocationBased;

    // Button is gated by the location fix for LOCATION_BASED orgs, and by
    // _isSubmitting for both flows so a second tap can't fire while a
    // check-in/check-out request is still in flight.
    final bool buttonEnabled =
        !_isSubmitting &&
        (!isLocationBased || _fixStatus == _LocationFixStatus.ready);

    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: availableHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppStyle.responsiveWidth(context, 20),
                      vertical: AppStyle.responsiveHeight(context, 24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                        const LiveClockWidget(),

                        _initialStatusLoading
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  width: AppStyle.responsiveWidth(context, 220),
                                  height: AppStyle.responsiveWidth(
                                    context,
                                    220,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              )
                            : CheckInButton(
                                status: _checkStatus,
                                onTap: _handleButtonTap,
                                enabled: buttonEnabled,
                                isFetchingLocation:
                                    isLocationBased &&
                                    _fixStatus == _LocationFixStatus.loading,
                              ),

                        // Location-based orgs: surface why the button is
                        // disabled / offer a retry when the fix failed.
                        if (isLocationBased &&
                            _fixStatus == _LocationFixStatus.failed)
                          Padding(
                            padding: EdgeInsets.only(
                              top: AppStyle.responsiveHeight(context, 8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _locationErrorMessage.isNotEmpty
                                      ? _locationErrorMessage
                                      : 'Unable to fetch your location.',
                                  textAlign: TextAlign.center,
                                  style: AppStyle.jakartaText(
                                    context: context,
                                    size: 13,
                                    weight: FontWeight.w500,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _fetchFreshLocation,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),

                        // Show break button only when checked in
                        if (_checkStatus == CheckStatus.checkedIn)
                          const BreakButton(),

                        // ✅ Use Consumer to get organization name from ProfileProvider
                        Consumer<ProfileProvider>(
                          builder: (context, provider, child) {
                            final organizationName =
                                provider.profile?.organizationName ??
                                'Loading...';
                            return LocationBadge(
                              locationStatus: _locationStatus,
                              locationName: organizationName,
                            );
                          },
                        ),

                        Consumer<AttendanceStatusProvider>(
                          builder: (context, attendanceProvider, child) {
                            return AttendanceStatsRow(
                              checkInTime: attendanceProvider.checkInTime,
                              totalHours: attendanceProvider.totalHours,
                              checkOutTime: attendanceProvider.checkOutTime,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
