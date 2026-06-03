import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const ContinueButton({
    super.key,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppStyle.responsiveHeight(
        context,
        58,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(40),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF06B6D4),
              Color(0xFF2294D6),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ElevatedButton(
          onPressed:
              isLoading ? null : onTap,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            shadowColor:
                Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                40,
              ),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  "Log in",
                  style: AppStyle.text(
                    context: context,
                    size: 18,
                    weight:
                        FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}