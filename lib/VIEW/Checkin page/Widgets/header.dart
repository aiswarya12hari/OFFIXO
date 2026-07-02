import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Leave%20Page/leave_provider.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/delete_account_dialog.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/logout_dialog.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/profile_screen.dart';
import 'package:offixo/VIEW/Leave%20page/leave_screen.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const Header({super.key, required this.userName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final menuWidth = AppStyle.responsiveWidth(context, 190);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// LEFT SIDE TEXT
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: AppStyle.jakartaText(
                context: context,
                size: 14,
                color: const Color(0xFF232323),
                weight: FontWeight.w400,
              ),
            ),
            SizedBox(height: AppStyle.responsiveHeight(context, 0)),
            Text(
              userName,
              style: AppStyle.jakartaText(
                context: context,
                size: 22,
                color: AppStyle.primaryColor,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),

        /// PROFILE IMAGE + MENU
        PopupMenuButton<String>(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
          onSelected: (value) {
            if (value == 'logout') {
              showDialog(
                context: context,
                builder: (_) => const LogoutDialog(),
              );
            } else if (value == 'profile') {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            } else if (value == 'leave') {
              context.read<LeaveProvider>().reset();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LeaveScreen()));
            } else if (value == 'delete_account') {
              showDialog(
                context: context,
                builder: (_) => const DeleteAccountDialog(),
              );
            }
          },
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          color: AppStyle.whiteColor,
          elevation: 12,
          shadowColor: const Color(0xFF2294D6).withOpacity(0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppStyle.borderColor, width: 1),
          ),
          itemBuilder: (_) => [
            /// ── PROFILE ──
            _styledItem(
              value: 'profile',
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              iconColor: AppStyle.primaryColor,
              iconBg: const Color(0xFFE8F4FD),
              menuWidth: menuWidth,
            ),

            /// ── LEAVE ──
            _styledItem(
              value: 'leave',
              icon: Icons.event_busy_rounded,
              label: 'Leave',
              iconColor: const Color(0xFF0EA5E9),
              iconBg: const Color(0xFFE0F2FE),
              menuWidth: menuWidth,
            ),

            /// ── LOGOUT ──
            _styledItem(
              value: 'logout',
              icon: Icons.logout_rounded,
              label: 'Logout',
              iconColor: const Color(0xFFFF9800),
              iconBg: const Color(0xFFFFF3E0),
              labelColor: const Color(0xFFFF9800),
              menuWidth: menuWidth,
            ),

            /// ── DIVIDER ──
            // const PopupMenuDivider(height: 1),

            /// ── DELETE ACCOUNT ──
            _styledItem(
              value: 'delete_account',
              icon: Icons.delete_forever_rounded,
              label: 'Delete Account',
              iconColor: Colors.red,
              iconBg: const Color(0xFFFFEBEE),
              labelColor: Colors.red,
              labelWeight: FontWeight.w600,
              menuWidth: menuWidth,
            ),
          ],

          /// AVATAR TRIGGER
          child: Container(
            width: AppStyle.responsiveWidth(context, 52),
            height: AppStyle.responsiveWidth(context, 52),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD2ECFA), width: 2),
              // boxShadow: [
              //   BoxShadow(
              //     color: AppStyle.primaryColor.withOpacity(0.15),
              //     blurRadius: 8,
              //     offset: const Offset(0, 58),
              //   ),
              // ],
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 28,
                        color: AppStyle.primaryColor,
                      ),
                    )
                  : Icon(Icons.person, size: 28, color: AppStyle.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  /// ── REUSABLE STYLED MENU ITEM ──
  PopupMenuItem<String> _styledItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
    required double menuWidth,
    Color labelColor = const Color(0xFF1E293B),
    FontWeight labelWeight = FontWeight.w500,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      // child: SizedBox(
      //   width: menuWidth,
      //   child: Row(
      //     children: [
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppStyle.textStatic(
              size: 13.5,
              color: labelColor,
              weight: labelWeight,
            ),
          ),
        ],
      ),
    );
  }
}
