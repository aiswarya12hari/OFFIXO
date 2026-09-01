import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Profile%20Page/total_working_hours_provider.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/total_working_hours_shimmer.dart';
import 'package:provider/provider.dart';

/// Entry point pushed from the Profile dropdown menu. Owns its own
/// `TotalWorkingHoursProvider` instance (created here, not registered
/// globally in main.dart) so this feature is fully self-contained and
/// doesn't touch app-wide provider wiring.
class TotalWorkingHoursScreen extends StatelessWidget {
  const TotalWorkingHoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TotalWorkingHoursProvider()..fetchForDate(DateTime.now()),
      child: const _TotalWorkingHoursView(),
    );
  }
}

class _TotalWorkingHoursView extends StatelessWidget {
  const _TotalWorkingHoursView();

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<TotalWorkingHoursProvider>();

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppStyle.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // ignore: use_build_context_synchronously
      context.read<TotalWorkingHoursProvider>().fetchForDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppStyle.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Total Working Hours',
          style: AppStyle.jakartaText(
            context: context,
            size: 18,
            weight: FontWeight.w600,
            color: const Color(0xFF232323),
          ),
        ),
      ),
      body: Consumer<TotalWorkingHoursProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateSelector(context, provider),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildContent(context, provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateSelector(BuildContext context, TotalWorkingHoursProvider provider) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppStyle.primaryColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.formattedSelectedDate,
                style: AppStyle.jakartaText(
                  context: context,
                  size: 15,
                  weight: FontWeight.w600,
                  color: const Color(0xFF232323),
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppStyle.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TotalWorkingHoursProvider provider) {
    if (provider.isLoading) {
      return const TotalWorkingHoursShimmer(key: ValueKey('working-hours-shimmer'));
    }

    if (provider.error.isNotEmpty) {
      return _messageCard(
        context,
        key: 'working-hours-error',
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red,
        title: 'Something went wrong',
        subtitle: provider.error,
        showRetry: true,
        provider: provider,
      );
    }

    if (provider.hasNoData || provider.status == null) {
      return _messageCard(
        context,
        key: 'working-hours-empty',
        icon: Icons.event_busy_rounded,
        iconColor: AppStyle.textSecondary,
        title: 'No Attendance Data',
        subtitle: 'There is no attendance record for this date.',
        showRetry: false,
        provider: provider,
      );
    }

    final status = provider.status!;

    return Container(
      key: const ValueKey('working-hours-content'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoRow(
            context,
            Icons.login_rounded,
            'Check-in Time',
            status.checkInTime.isNotEmpty ? status.checkInTime : '--:--',
          ),
          const Divider(),
          _infoRow(
            context,
            Icons.logout_rounded,
            'Check-out Time',
            status.checkOutTime.isNotEmpty ? status.checkOutTime : '--:--',
          ),
          const Divider(),
          _infoRow(
            context,
            Icons.timer_outlined,
            'Total Working Hours',
            status.totalWorkingHours.isNotEmpty
                ? status.totalWorkingHours
                : '00:00:00',
          ),
          if (status.isCurrentlyActive) ...[
            const Divider(),
            _infoRow(
              context,
              Icons.play_circle_outline_rounded,
              'Current Session Duration',
              status.currentSessionDuration.isNotEmpty
                  ? status.currentSessionDuration
                  : '00:00:00',
            ),
          ],
        ],
      ),
    );
  }

  Widget _messageCard(
    BuildContext context, {
    required String key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool showRetry,
    required TotalWorkingHoursProvider provider,
  }) {
    return Container(
      key: ValueKey(key),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppStyle.jakartaText(
              context: context,
              size: 16,
              weight: FontWeight.w600,
              color: const Color(0xFF232323),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppStyle.jakartaText(
              context: context,
              size: 13,
              weight: FontWeight.w400,
              color: AppStyle.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetry) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => provider.fetchForDate(provider.selectedDate),
              child: Text(
                'Retry',
                style: AppStyle.jakartaText(
                  context: context,
                  size: 14,
                  weight: FontWeight.w600,
                  color: AppStyle.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppStyle.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF232323),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 14,
                    weight: FontWeight.w400,
                    color: AppStyle.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}