import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Leave%20Page/leave_provider.dart';
import 'package:provider/provider.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _reasonController = TextEditingController();

  int _selectedLeaveType = 1;
  String _selectedSession = 'FULL_DAY';
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<Map<String, dynamic>> _leaveTypes = [
    {'id': 1, 'label': 'Sick Leave'},
    {'id': 2, 'label': 'Casual Leave'},
    {'id': 3, 'label': 'Restricted Leave'},
  ];

  final List<Map<String, String>> _sessionChoices = [
    {'value': 'FULL_DAY', 'label': 'Full Day'},
    {'value': 'HALF_DAY_MORNING', 'label': 'Half Day - Morning'},
    {'value': 'HALF_DAY_AFTERNOON', 'label': 'Half Day - Afternoon'},
  ];

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    final first =
        isFrom ? DateTime.now() : (_fromDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppStyle.primaryColor,
            onPrimary: Colors.white,
            onSurface: AppStyle.textPrimary,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select from and to dates')),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason')),
      );
      return;
    }

    await context.read<LeaveProvider>().submitLeaveRequest(
          leaveType: _selectedLeaveType,
          fromDate: _formatDate(_fromDate!),
          toDate: _formatDate(_toDate!),
          session: _selectedSession,
          reason: _reasonController.text.trim(),
        );

    if (!mounted) return;

    final provider = context.read<LeaveProvider>();
    if (provider.isSuccess) {
      _showSuccessDialog();
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Leave Submitted!',
              style: AppStyle.jakartaText(
                context: context,
                size: 18,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your leave request has been submitted and is pending approval.',
              textAlign: TextAlign.center,
              style: AppStyle.jakartaText(
                context: context,
                size: 13,
                color: AppStyle.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to leave list
              },
              style: TextButton.styleFrom(
                backgroundColor: AppStyle.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Done',
                style: AppStyle.jakartaText(
                  context: context,
                  size: 14,
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
          'Leave Request',
          style: AppStyle.jakartaText(
            context: context,
            size: 16,
            weight: FontWeight.w700,
            color: AppStyle.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppStyle.responsiveWidth(context, 20),
          vertical: AppStyle.responsiveHeight(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: 'Leave Type'),
            const SizedBox(height: 10),
            _LeaveTypeSelector(
              leaveTypes: _leaveTypes,
              selected: _selectedLeaveType,
              onSelected: (id) => setState(() => _selectedLeaveType = id),
            ),

            SizedBox(height: AppStyle.responsiveHeight(context, 24)),

            _SectionLabel(label: 'Session'),
            const SizedBox(height: 10),
            _SessionDropdown(
              sessions: _sessionChoices,
              selected: _selectedSession,
              onChanged: (val) => setState(() => _selectedSession = val),
            ),

            SizedBox(height: AppStyle.responsiveHeight(context, 24)),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'From Date'),
                      const SizedBox(height: 10),
                      _DatePickerField(
                        displayText: _displayDate(_fromDate),
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'To Date'),
                      const SizedBox(height: 10),
                      _DatePickerField(
                        displayText: _displayDate(_toDate),
                        onTap: () => _pickDate(isFrom: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppStyle.responsiveHeight(context, 24)),

            _SectionLabel(label: 'Reason'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppStyle.whiteColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppStyle.borderColor),
              ),
              child: TextField(
                controller: _reasonController,
                maxLines: 4,
                style: AppStyle.jakartaText(context: context, size: 13),
                decoration: InputDecoration(
                  hintText: 'Enter the reason for your leave...',
                  hintStyle: AppStyle.jakartaText(
                    context: context,
                    size: 13,
                    color: AppStyle.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            SizedBox(height: AppStyle.responsiveHeight(context, 36)),

            Consumer<LeaveProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyle.primaryColor,
                      disabledBackgroundColor:
                          AppStyle.primaryColor.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit Request',
                            style: AppStyle.jakartaText(
                              context: context,
                              size: 15,
                              color: Colors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppStyle.jakartaText(
        context: context,
        size: 13,
        weight: FontWeight.w600,
        color: AppStyle.textPrimary,
      ),
    );
  }
}

class _LeaveTypeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> leaveTypes;
  final int selected;
  final ValueChanged<int> onSelected;

  const _LeaveTypeSelector({
    required this.leaveTypes,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: leaveTypes.map((type) {
        final isSelected = selected == type['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(type['id'] as int),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: type['id'] != leaveTypes.last['id'] ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppStyle.primaryColor
                    : AppStyle.whiteColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppStyle.primaryColor
                      : AppStyle.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  type['label'] as String,
                  textAlign: TextAlign.center,
                  style: AppStyle.jakartaText(
                    context: context,
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: isSelected
                        ? AppStyle.whiteColor
                        : AppStyle.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SessionDropdown extends StatelessWidget {
  final List<Map<String, String>> sessions;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SessionDropdown({
    required this.sessions,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppStyle.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppStyle.textSecondary),
          style: AppStyle.jakartaText(context: context, size: 13),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          items: sessions
              .map((s) => DropdownMenuItem(
                    value: s['value'],
                    child: Text(s['label']!),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String displayText;
  final VoidCallback onTap;

  const _DatePickerField({required this.displayText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = displayText == 'Select date';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppStyle.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppStyle.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppStyle.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: AppStyle.jakartaText(
                  context: context,
                  size: 12,
                  color: isPlaceholder
                      ? AppStyle.textSecondary
                      : AppStyle.textPrimary,
                  weight: isPlaceholder
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}