import 'package:flutter/material.dart';
import 'package:offixo/PROVIDER/Login%20Page/login_provider.dart';
import 'package:provider/provider.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/circular_back_button.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/continue_button.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/custom_text_field.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/footer_links.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  // ================= FORM KEY =================
  final _formKey =
      GlobalKey<FormState>();

  // ================= CONTROLLERS =================
  final TextEditingController
      emailController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider =
        Provider.of<LoginProvider>(
      context,
    );

    return Scaffold(
      resizeToAvoidBottomInset:
          true,
      backgroundColor:
          AppStyle.backgroundColor,

      body: SafeArea(
        child:
            SingleChildScrollView(
          physics:
              const ClampingScrollPhysics(),

          child: Padding(
            padding:
                const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 20,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      120,
                    ),
                  ),

                  const CircularBackButton(),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      15,
                    ),
                  ),

                  Text(
                    "Welcome Back,",
                    style:
                        AppStyle.text(
                      context:
                          context,
                      size: 34,
                      weight:
                          FontWeight
                              .w800,
                      color:
                          AppStyle
                              .primaryColor,
                    ),
                  ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      4,
                    ),
                  ),

                  Text(
                    "Login to your Account",
                    style:
                        AppStyle.text(
                      context:
                          context,
                      size: 16,
                      color:
                          AppStyle
                              .textSecondary,
                    ),
                  ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      40,
                    ),
                  ),

                  // ================= EMAIL LABEL =================
                  Text(
                    "Email Id",
                    style:
                        AppStyle.text(
                      context:
                          context,
                      size: 15,
                      color:
                          AppStyle
                              .textSecondary,
                    ),
                  ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      10,
                    ),
                  ),

                  // ================= EMAIL FIELD =================
                  CustomTextField(
                    hintText:
                        "hariharans@gmail.com",
                    controller:
                        emailController,
                    icon:
                        Icons
                            .mail_outline,

                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .trim()
                              .isEmpty) {
                        return "Please enter email";
                      }

                      final emailRegex =
                          RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );

                      if (!emailRegex
                          .hasMatch(
                        value.trim(),
                      )) {
                        return "Enter valid email";
                      }

                      return null;
                    },
                  ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      10,
                    ),
                  ),

                  // ================= PASSWORD LABEL =================
                  Text(
                    "Password",
                    style:
                        AppStyle.text(
                      context:
                          context,
                      size: 15,
                      color:
                          AppStyle
                              .textSecondary,
                    ),
                  ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      10,
                    ),
                  ),

                  // ================= PASSWORD FIELD =================
                  CustomTextField(
                    hintText:
                        "****************",
                    controller:
                        passwordController,
                    icon:
                        Icons
                            .lock_outline,
                    isPassword:
                        true,

                    validator:
                        (value) {
                      if (value ==
                              null ||
                          value
                              .trim()
                              .isEmpty) {
                        return "Please enter password";
                      }

                      if (value
                              .trim()
                              .length <
                          6) {
                        return "Password must be at least 6 characters";
                      }

                      return null;
                    },
                  ),

                  // ================= API ERROR =================
                  if (loginProvider
                          .loginError !=
                      null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 8,
                        left: 8,
                      ),
                      child: Text(
                        loginProvider
                            .loginError!,
                        style:
                            const TextStyle(
                          color:
                              Colors.red,
                          fontSize:
                              13,
                        ),
                      ),
                    ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      40,
                    ),
                  ),

                  // ================= LOGIN BUTTON =================
                  ContinueButton(
                    isLoading:
                        loginProvider
                            .isLoading,

                    onTap: () {
                      // CLEAR OLD ERROR
                      loginProvider
                          .clearError();

                      // VALIDATE FORM
                      if (_formKey
                              .currentState
                              ?.validate() !=
                          true) {
                        return;
                      }

                      loginProvider
                          .login(
                        context:
                            context,
                        email:
                            emailController
                                .text
                                .trim(),
                        password:
                            passwordController
                                .text
                                .trim(),
                      );
                    },
                  ),

                  SizedBox(
                    height: AppStyle
                        .responsiveHeight(
                      context,
                      20,
                    ),
                  ),

                  // ================= FOOTER =================
                  const FooterLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}