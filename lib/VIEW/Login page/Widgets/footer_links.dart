import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class FooterLinks
    extends StatelessWidget {
  const FooterLinks({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        /// FORGOT PASSWORD
        Center(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      "Forgot Password ? ",
                  style:
                      AppStyle.text(
                    context:
                        context,
                    size: 14,
                    color:
                        AppStyle
                            .textSecondary,
                  ),
                ),

                TextSpan(
                  text:
                      "Contact Admin",
                  style:
                      AppStyle.text(
                    context:
                        context,
                    size: 14,
                    color:
                        AppStyle
                            .primaryColor,
                    weight:
                        FontWeight
                            .w700,
                  ),
                ),
              ],
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

        /// TERMS & PRIVACY
        Center(
          child: RichText(
            textAlign:
                TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      "By clicking Continue, you agree to our\n",
                  style:
                      AppStyle.text(
                    context:
                        context,
                    size: 12,
                    color:
                        AppStyle
                            .textSecondary,
                  ),
                ),

                TextSpan(
                  text:
                      "Terms of Service",
                  style:
                      AppStyle.text(
                    context:
                        context,
                    size: 12,
                    color:
                        AppStyle
                            .primaryColor,
                    weight:
                        FontWeight
                            .w600,
                  ),
                ),

                TextSpan(
                  text:
                      " and ",
                  style:
                      AppStyle.text(
                    context:
                        context,
                    size: 12,
                    color:
                        AppStyle
                            .textSecondary,
                  ),
                ),

                TextSpan(
                  text:
                      "Privacy Policy",
                  style:
                      AppStyle.text(
                    context:
                        context,
                    size: 12,
                    color:
                        AppStyle
                            .primaryColor,
                    weight:
                        FontWeight
                            .w600,
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