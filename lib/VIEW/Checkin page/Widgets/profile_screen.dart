import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Profile%20Page/profile_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<ProfileProvider>()
          .fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor:
            AppStyle.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color:
                AppStyle.primaryColor,
          ),
          onPressed: () =>
              Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style:
              AppStyle.jakartaText(
            context: context,
            size: 18,
            weight:
                FontWeight.w600,
            color: const Color(
              0xFF232323,
            ),
          ),
        ),
      ),
      body:
          Consumer<ProfileProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          if (provider.isLoading) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final profile =
              provider.profile;

          if (profile == null) {
            return const Center(
              child: Text(
                "No profile data found",
              ),
            );
          }

          return SafeArea(
            child:
                SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    AppStyle
                        .responsiveWidth(
                  context,
                  20,
                ),
                vertical:
                    AppStyle
                        .responsiveHeight(
                  context,
                  24,
                ),
              ),
              child: Column(
                children: [
                  /// PROFILE IMAGE
                  CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        profile.faceImage
                                .isNotEmpty
                            ? NetworkImage(
                                profile
                                    .faceImage,
                              )
                            : null,
                    child: profile
                            .faceImage
                            .isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 40,
                          )
                        : null,
                  ),

                  SizedBox(
                    height:
                        AppStyle
                            .responsiveHeight(
                      context,
                      16,
                    ),
                  ),

                  /// NAME
                  Text(
                    profile.fullName,
                    style:
                        AppStyle
                            .jakartaText(
                      context:
                          context,
                      size: 22,
                      weight:
                          FontWeight
                              .w600,
                      color:
                          AppStyle
                              .primaryColor,
                    ),
                  ),

                  SizedBox(
                    height:
                        AppStyle
                            .responsiveHeight(
                      context,
                      4,
                    ),
                  ),

                  /// ROLE
                  Text(
                    profile
                        .designation,
                    style:
                        AppStyle
                            .jakartaText(
                      context:
                          context,
                      size: 14,
                      weight:
                          FontWeight
                              .w400,
                      color:
                          const Color(
                        0xFF6B7280,
                      ),
                    ),
                  ),

                  SizedBox(
                    height:
                        AppStyle
                            .responsiveHeight(
                      context,
                      30,
                    ),
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(20),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    child: Column(
                      children: [
                        _profileRow(
                          context,
                          Icons
                              .email_outlined,
                          "Email",
                          profile
                              .email,
                        ),
                        const Divider(),

                        _profileRow(
                          context,
                          Icons
                              .phone_outlined,
                          "Phone",
                          profile
                              .phoneNumber,
                        ),
                        const Divider(),

                        _profileRow(
                          context,
                          Icons
                              .business_outlined,
                          "Organization",
                          profile
                              .organizationName,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              AppStyle.primaryColor,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              label,
            ),
            Text(
              value,
            ),
          ],
        ),
      ],
    );
  }
}