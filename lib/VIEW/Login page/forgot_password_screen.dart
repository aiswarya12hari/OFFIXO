import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Login%20Page/forgot_password_provider.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/circular_back_button.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/continue_button.dart';
import 'package:offixo/VIEW/Login%20page/Widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ================= FORM KEY =================
  final _formKey = GlobalKey<FormState>();

  // ================= CONTROLLERS =================
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
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
                    "Forgot Password?",
                    style: AppStyle.text(
                      context: context,
                      size: 34,
                      weight: FontWeight.w800,
                      color: AppStyle.primaryColor,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 4)),

                  Text(
                    "Enter your registered email to receive an OTP",
                    style: AppStyle.text(
                      context: context,
                      size: 16,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 40)),

                  // ================= EMAIL LABEL =================
                  Text(
                    "Email Id",
                    style: AppStyle.text(
                      context: context,
                      size: 15,
                      color: AppStyle.textSecondary,
                    ),
                  ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 10)),

                  // ================= EMAIL FIELD =================
                  CustomTextField(
                    hintText: "Enter your registered email",
                    controller: emailController,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter email";
                      }

                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );

                      if (!emailRegex.hasMatch(value.trim())) {
                        return "Enter valid email";
                      }

                      return null;
                    },
                  ),

                  // ================= API ERROR =================
                  if (forgotPasswordProvider.sendOtpError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: Text(
                        forgotPasswordProvider.sendOtpError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  SizedBox(height: AppStyle.responsiveHeight(context, 40)),

                  // ================= SEND OTP BUTTON =================
                  ContinueButton(
                    label: "Send OTP",
                    isLoading: forgotPasswordProvider.isSendingOtp,

                    onTap: () {
                      forgotPasswordProvider.clearSendOtpError();

                      if (_formKey.currentState?.validate() != true) {
                        return;
                      }

                      forgotPasswordProvider.sendOtp(
                        context: context,
                        email: emailController.text.trim(),
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