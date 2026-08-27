import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Login%20Page/forgot_password_provider.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/circular_back_button.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/continue_button.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ================= FORM KEY =================
  final _formKey = GlobalKey<FormState>();

  // ================= CONTROLLERS =================
  final TextEditingController otpController = TextEditingController();

  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forgotPasswordProvider = Provider.of<ForgotPasswordProvider>(
      context,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppStyle.backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),

          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 20,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  SizedBox(height: AppStyle.responsiveHeight(context, 120)),

                  CircularBackButton(onTap: () => Navigator.pop(context)),

                  SizedBox(height: AppStyle.responsiveHeight(context, 15)),

                  Text(
                    "Reset Password",
                    style: AppStyle.text(
                      context: context,
                      size: 34,
                      weight: FontWeight.w800,
                      color: AppStyle.primaryColor,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 4)),

                  Text(
                    "Enter the OTP sent to your email and set a new password",
                    style: AppStyle.text(
                      context: context,
                      size: 16,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 40)),

                  // ================= EMAIL (READ-ONLY) =================
                  Text(
                    "Email Id",
                    style: AppStyle.text(
                      context: context,
                      size: 15,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 10)),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyle.borderColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppStyle.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          color: AppStyle.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.email,
                            style: AppStyle.text(context: context, size: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 20)),

                  // ================= OTP =================
                  Text(
                    "OTP",
                    style: AppStyle.text(
                      context: context,
                      size: 15,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 10)),

                  CustomTextField(
                    hintText: "Enter OTP",
                    controller: otpController,
                    icon: Icons.password_outlined,
                    keyboardType: TextInputType.number,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter the OTP";
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 20)),

                  // ================= NEW PASSWORD =================
                  Text(
                    "New Password",
                    style: AppStyle.text(
                      context: context,
                      size: 15,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 10)),

                  CustomTextField(
                    hintText: "****************",
                    controller: newPasswordController,
                    icon: Icons.lock_outline,
                    isPassword: true,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter new password";
                      }

                      if (value.trim().length < 6) {
                        return "Password must be at least 6 characters";
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 20)),

                  // ================= CONFIRM PASSWORD =================
                  Text(
                    "Confirm Password",
                    style: AppStyle.text(
                      context: context,
                      size: 15,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 10)),

                  CustomTextField(
                    hintText: "****************",
                    controller: confirmPasswordController,
                    icon: Icons.lock_outline,
                    isPassword: true,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please confirm your password";
                      }

                      if (value.trim() != newPasswordController.text.trim()) {
                        return "Passwords do not match";
                      }

                      return null;
                    },
                  ),

                  // ================= API ERROR =================
                  if (forgotPasswordProvider.resetError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: Text(
                        forgotPasswordProvider.resetError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 40)),

                  // ================= RESET PASSWORD BUTTON =================
                  ContinueButton(
                    label: "Reset Password",
                    isLoading: forgotPasswordProvider.isResetting,

                    onTap: () {
                      forgotPasswordProvider.clearResetError();

                      if (_formKey.currentState?.validate() != true) {
                        return;
                      }

                      forgotPasswordProvider.resetPassword(
                        context: context,
                        email: widget.email,
                        otp: otpController.text.trim(),
                        newPassword: newPasswordController.text.trim(),
                        confirmPassword: confirmPasswordController.text
                            .trim(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}