import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/logout_dialog.dart';
import 'package:offixo/VIEW/Checkin%20page/Widgets/profile_screen.dart';

class Header extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const Header({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        /// LEFT SIDE TEXT
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style:
                  AppStyle.jakartaText(
                context: context,
                size: 14,
                color:
                    const Color(
                  0xFF232323,
                ),
                weight:
                    FontWeight.w400,
              ),
            ),

            SizedBox(
              height:
                  AppStyle
                      .responsiveHeight(
                context,
                0,
              ),
            ),

            Text(
              userName,
              style:
                  AppStyle.jakartaText(
                context: context,
                size: 22,
                color:
                    AppStyle
                        .primaryColor,
                weight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),

        /// PROFILE IMAGE + MENU
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value ==
                'logout') {
              showDialog(
                context: context,
                builder:
                    (_) =>
                        const LogoutDialog(),
              );
            } else if (value ==
                'profile') {
              Navigator.of(
                      context)
                  .push(
                MaterialPageRoute(
                  builder:
                      (_) =>
                          const ProfileScreen(),
                ),
              );
            }
          },

          offset:
              const Offset(
            0,
            55,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          itemBuilder: (_) => [
            const PopupMenuItem(
              value:
                  'profile',
              child: Row(
                children: [
                  Icon(
                    Icons
                        .person_outline_rounded,
                  ),
                  SizedBox(
                    width:
                        10,
                  ),
                  Text(
                    'Profile',
                  ),
                ],
              ),
            ),

            const PopupMenuItem(
              value:
                  'logout',
              child: Row(
                children: [
                  Icon(
                    Icons
                        .logout_rounded,
                    color:
                        Color(
                      0xFFEF4444,
                    ),
                  ),
                  SizedBox(
                    width:
                        10,
                  ),
                  Text(
                    'Logout',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFFEF4444,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          child: Container(
            width:
                AppStyle
                    .responsiveWidth(
              context,
              52,
            ),

            height:
                AppStyle
                    .responsiveWidth(
              context,
              52,
            ),

            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              border:
                  Border.all(
                color:
                    const Color(
                  0xFFD2ECFA,
                ),
                width:
                    1.5,
              ),
            ),

            child:
                ClipOval(
              child:
                  avatarUrl !=
                              null &&
                          avatarUrl!
                              .isNotEmpty
                      ? Image.network(
                          avatarUrl!,
                          fit: BoxFit
                              .cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Icon(
                              Icons
                                  .person,
                              size:
                                  28,
                              color:
                                  AppStyle.primaryColor,
                            );
                          },
                        )
                      : Icon(
                          Icons
                              .person,
                          size:
                              28,
                          color:
                              AppStyle.primaryColor,
                        ),
            ),
          ),
        ),
      ],
    );
  }
}