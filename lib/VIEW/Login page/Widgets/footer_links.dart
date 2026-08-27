import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/VIEW/Login%20page/forgot_password_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterLinks extends StatelessWidget {
  const FooterLinks({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching $urlString: $e');
    }
  }

  Future<void> _launchPrivacyPolicy() {
    return _launchUrl(
      'https://www.freeprivacypolicy.com/live/ba0f8923-df1e-49b6-9aa8-54160c5d64fa',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// FORGOT PASSWORD
        Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Forgot Password ? ",
                  style: AppStyle.text(
                    context: context,
                    size: 14,
                    color: AppStyle.textSecondary,
                  ),
                ),

                TextSpan(
                  text: "Reset it",
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                  style: AppStyle.text(
                    context: context,
                    size: 14,
                    color: AppStyle.primaryColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: AppStyle.responsiveHeight(context, 30)),

        /// TERMS & PRIVACY
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: "By clicking Continue, you agree to our\n",
                  style: AppStyle.text(
                    context: context,
                    size: 12,
                    color: AppStyle.textSecondary,
                  ),
                ),

                TextSpan(
                  text: "Terms of Service",
                  recognizer: TapGestureRecognizer()
                    ..onTap = _launchPrivacyPolicy,
                  style: AppStyle.text(
                    context: context,
                    size: 12,
                    color: AppStyle.primaryColor,
                    weight: FontWeight.w600,
                  ),
                ),

                TextSpan(
                  text: " and ",
                  style: AppStyle.text(
                    context: context,
                    size: 12,
                    color: AppStyle.textSecondary,
                  ),
                ),

                TextSpan(
                  text: "Privacy Policy",
                  recognizer: TapGestureRecognizer()
                    ..onTap = _launchPrivacyPolicy,
                  style: AppStyle.text(
                    context: context,
                    size: 12,
                    color: AppStyle.primaryColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}