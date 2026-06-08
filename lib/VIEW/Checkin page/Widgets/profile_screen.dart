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
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
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

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  Text(
                    profile.designation,
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  Container(
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
                            Icons.badge,
                            "Employee No",
                            profile.empNo),

                        _divider(),

                        _profileRow(
                            Icons.email,
                            "Email",
                            profile.email),

                        _divider(),

                        _profileRow(
                            Icons.phone,
                            "Phone",
                            profile.phoneNumber),

                        _divider(),

                        _profileRow(
                            Icons.work,
                            "Member Type",
                            profile.memberType),

                        _divider(),

                        _profileRow(
                            Icons.person,
                            "Gender",
                            profile.gender),

                        _divider(),

                        _profileRow(
                            Icons.bloodtype,
                            "Blood Group",
                            profile.bloodGroup),

                        _divider(),

                        _profileRow(
                            Icons.cake,
                            "DOB",
                            profile.dateOfBirth),

                        _divider(),

                        _profileRow(
                            Icons.location_on,
                            "Address",
                            profile.presentAddress),

                        _divider(),

                        _profileRow(
                            Icons.business,
                            "Organization",
                            profile.organizationName),

                        _divider(),

                        _profileRow(
                            Icons.category,
                            "Org Type",
                            profile.organizationType),

                        _divider(),

                        _profileRow(
                            Icons.person_outline,
                            "Owner",
                            profile.organizationOwner),

                        _divider(),

                        _profileRow(
                            Icons.location_city,
                            "Org Address",
                            profile.organizationAddress),

                        _divider(),

                        _profileRow(
                            Icons.call,
                            "Org Phone",
                            profile.organizationPhone),

                        _divider(),

                        _profileRow(
                            Icons.calendar_today,
                            "Start Date",
                            profile.startDate),

                        _divider(),

                        _profileRow(
                          Icons.fingerprint,
                          "Biometric",
                          profile
                                  .isBiometricEnabled
                              ? "Enabled"
                              : "Disabled",
                        ),

                        _divider(),

                        _profileRow(
                          Icons.check_circle,
                          "Status",
                          profile.isActive
                              ? "Active"
                              : "Inactive",
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

  Widget _divider() {
    return const Divider();
  }

  Widget _profileRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                AppStyle.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(
                    height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}