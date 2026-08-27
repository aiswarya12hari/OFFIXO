import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:offixo/VIEW/Leave%20Page/widgets/leave_shimmer_widgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/MODEL/leave_model.dart';
import 'package:offixo/PROVIDER/Leave%20Page/leave_provider.dart';


class LeaveDetailScreen extends StatefulWidget {
  final LeaveModel leave;
  const LeaveDetailScreen({super.key, required this.leave});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<LeaveProvider>();
      provider.resetCertificateState();
      provider.fetchMedicalCertificate(widget.leave.id);
    });
  }

  Future<void> _pickAndUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (files.isEmpty || files.first.path == null) return;

    final file = File(files.first.path!);
    final provider = context.read<LeaveProvider>();
    final success = await provider.uploadMedicalCertificate(
      widget.leave.id,
      file,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate uploaded successfully')),
      );
    } else if (provider.certificateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.certificateError!),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _viewCertificate(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open certificate')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = widget.leave;

    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.whiteColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppStyle.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leave Details',
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
            _DetailCard(leave: leave),
            SizedBox(height: AppStyle.responsiveHeight(context, 24)),
            Text(
              'Medical Certificate',
              style: AppStyle.jakartaText(
                context: context,
                size: 14,
                weight: FontWeight.w700,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<LeaveProvider>(
              builder: (context, provider, _) {
                if (provider.isCertificateLoading) {
                  return const MedicalCertificateShimmer();
                }

                final certUrl = provider.medicalCertificateUrl;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (certUrl != null && certUrl.isNotEmpty)
                      _CertificateTile(
                        onView: () => _viewCertificate(certUrl),
                        onReplace: provider.isCertificateUploading
                            ? null
                            : _pickAndUpload,
                        isUploading: provider.isCertificateUploading,
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: provider.isCertificateUploading
                              ? null
                              : _pickAndUpload,
                          icon: provider.isCertificateUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(
                                  Icons.upload_file_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          label: Text(
                            provider.isCertificateUploading
                                ? 'Uploading...'
                                : 'Upload Certificate',
                            style: AppStyle.jakartaText(
                              context: context,
                              size: 14,
                              color: Colors.white,
                              weight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyle.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leave Detail Card ──────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final LeaveModel leave;
  const _DetailCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyle.whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppStyle.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leave.leaveTypeName,
            style: AppStyle.jakartaText(
              context: context,
              size: 16,
              weight: FontWeight.w700,
              color: AppStyle.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _row('From', leave.fromDate),
          _row('To', leave.toDate),
          _row('Session', leave.session),
          _row('Days', leave.numberOfDays),
          _row('Status', leave.status),
          _row('Reason', leave.reason),
          if (leave.rejectionReason != null &&
              leave.rejectionReason!.isNotEmpty)
            _row('Rejection Reason', leave.rejectionReason!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Builder(
        builder: (context) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: AppStyle.jakartaText(
                  context: context,
                  size: 12,
                  color: AppStyle.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: AppStyle.jakartaText(
                  context: context,
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppStyle.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Certificate Tile (shown when already uploaded) ────────────────────────

class _CertificateTile extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback? onReplace;
  final bool isUploading;

  const _CertificateTile({
    required this.onView,
    required this.onReplace,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppStyle.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_rounded,
            color: AppStyle.primaryColor,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Certificate uploaded',
              style: AppStyle.jakartaText(
                context: context,
                size: 13,
                weight: FontWeight.w600,
                color: AppStyle.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onView,
            child: Text(
              'View',
              style: AppStyle.jakartaText(
                context: context,
                size: 13,
                weight: FontWeight.w600,
                color: AppStyle.primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: onReplace,
            icon: isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: AppStyle.textSecondary,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }
}