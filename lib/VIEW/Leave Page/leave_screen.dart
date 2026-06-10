import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/MODEL/leave_model.dart';
import 'package:offixo/PROVIDER/Leave%20Page/leave_provider.dart';
import 'package:offixo/VIEW/Leave%20Page/leave_request_screen.dart';
import 'package:provider/provider.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<LeaveProvider>().fetchLeaves());
  }

  Future<void> _onRefresh() async {
    await context.read<LeaveProvider>().fetchLeaves();
  }

  void _openLeaveRequestForm() {
    context.read<LeaveProvider>().resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.whiteColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppStyle.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Leaves',
          style: AppStyle.jakartaText(
            context: context,
            size: 16,
            weight: FontWeight.w700,
            color: AppStyle.textPrimary,
          ),
        ),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, _) {
          if (provider.isFetching) {
            return const Center(
              child: CircularProgressIndicator(color: AppStyle.primaryColor),
            );
          }

          if (provider.fetchError != null) {
            return _ErrorState(
              message: provider.fetchError!,
              onRetry: _onRefresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppStyle.primaryColor,
            child: provider.leaves.isEmpty
                ? _EmptyState(onApply: _openLeaveRequestForm)
                : _LeaveList(
                    leaves: provider.leaves,
                    onApply: _openLeaveRequestForm,
                  ),
          );
        },
      ),
    );
  }
}

// ─── Leave List ───────────────────────────────────────────────────────────────

class _LeaveList extends StatelessWidget {
  final List<LeaveModel> leaves;
  final VoidCallback onApply;

  const _LeaveList({required this.leaves, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppStyle.responsiveWidth(context, 20),
        right: AppStyle.responsiveWidth(context, 20),
        top: AppStyle.responsiveHeight(context, 20),
        bottom: AppStyle.responsiveHeight(context, 100),
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: leaves.length + 1, // +1 for the header summary row
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${leaves.length} Request${leaves.length != 1 ? 's' : ''}',
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 13,
                    color: AppStyle.textSecondary,
                    weight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: onApply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppStyle.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Leave Request',
                          style: AppStyle.jakartaText(
                            context: context,
                            size: 12,
                            color: Colors.white,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LeaveCard(leave: leaves[index - 1]),
        );
      },
    );
  }
}

// ─── Leave Card ───────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final LeaveModel leave;
  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(leave.status);
    final statusBg = statusColor.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: AppStyle.whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: leave type + status badge ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    leave.leaveTypeName,
                    style: AppStyle.jakartaText(
                      context: context,
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(leave.status),
                    style: AppStyle.jakartaText(
                      context: context,
                      size: 11,
                      weight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: AppStyle.borderColor),
            const SizedBox(height: 10),

            // ── Date range row ───────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppStyle.primaryColor),
                const SizedBox(width: 6),
                Text(
                  '${_fmtDisplay(leave.fromDate)}  →  ${_fmtDisplay(leave.toDate)}',
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppStyle.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppStyle.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${leave.numberOfDays} day${double.tryParse(leave.numberOfDays) == 1.0 ? '' : 's'}',
                    style: AppStyle.jakartaText(
                      context: context,
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppStyle.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Session ──────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppStyle.textSecondary),
                const SizedBox(width: 6),
                Text(
                  _sessionLabel(leave.session),
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 12,
                    color: AppStyle.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Reason ───────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded,
                    size: 14, color: AppStyle.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    leave.reason,
                    style: AppStyle.jakartaText(
                      context: context,
                      size: 12,
                      color: AppStyle.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ── Rejection reason (if any) ────────────────────────────────
            if (leave.rejectionReason != null &&
                leave.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'Reason: ${leave.rejectionReason}',
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 11,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Applied at ───────────────────────────────────────────────
            Text(
              'Applied: ${_fmtAppliedAt(leave.appliedAt)}',
              style: AppStyle.jakartaText(
                context: context,
                size: 11,
                color: AppStyle.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return Colors.red.shade500;
      case 'PENDING':
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return '✓ Approved';
      case 'REJECTED':
        return '✕ Rejected';
      case 'PENDING':
      default:
        return '● Pending';
    }
  }

  String _sessionLabel(String session) {
    switch (session) {
      case 'HALF_DAY_MORNING':
        return 'Half Day - Morning';
      case 'HALF_DAY_AFTERNOON':
        return 'Half Day - Afternoon';
      case 'FULL_DAY':
      default:
        return 'Full Day';
    }
  }

  // "2026-06-15" → "15 Jun 2026"
  String _fmtDisplay(String date) {
    try {
      final d = DateTime.parse(date);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  // ISO timestamp → "09 Jun 2026, 05:18 PM"
  String _fmtAppliedAt(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final amPm = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}, '
          '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $amPm';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onApply;
  const _EmptyState({required this.onApply});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: AppStyle.responsiveHeight(context, 120)),
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppStyle.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded,
                  size: 38, color: AppStyle.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No Leave Requests',
              style: AppStyle.jakartaText(
                context: context,
                size: 16,
                weight: FontWeight.w700,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t applied for any leave yet.',
              style: AppStyle.jakartaText(
                context: context,
                size: 13,
                color: AppStyle.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Leave Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyle.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: AppStyle.jakartaText(
                  context: context,
                  size: 14,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyle.jakartaText(
                context: context,
                size: 13,
                color: AppStyle.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
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
        ),
      ),
    );
  }
}