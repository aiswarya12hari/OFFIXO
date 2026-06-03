import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<CustomTextField> createState() =>
      _CustomTextFieldState();
}

class _CustomTextFieldState
    extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured =
        widget.isPassword;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextFormField(
      controller:
          widget.controller,

      obscureText:
          _isObscured,

      validator:
          widget.validator,

      autovalidateMode:
          AutovalidateMode
              .onUserInteraction,

      style:
          AppStyle.text(
        context: context,
        size: 15,
      ),

      textInputAction:
          widget.isPassword
              ? TextInputAction
                  .done
              : TextInputAction
                  .next,

      decoration:
          InputDecoration(
        hintText:
            widget.hintText,

        hintStyle:
            AppStyle.text(
          context:
              context,
          size: 14,
          color: AppStyle
              .textSecondary,
        ),

        prefixIcon: Icon(
          widget.icon,
          color:
              AppStyle
                  .primaryColor,
          size: 22,
        ),

        suffixIcon:
            widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscured
                          ? Icons
                              .visibility_off_outlined
                          : Icons
                              .visibility_outlined,
                      color:
                          AppStyle.primaryColor,
                    ),
                    onPressed:
                        () {
                      setState(
                        () {
                          _isObscured =
                              !_isObscured;
                        },
                      );
                    },
                  )
                : null,

        filled: true,
        fillColor:
            Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 18,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color: AppStyle
                .borderColor,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color: AppStyle
                .primaryColor,
            width: 1.5,
          ),
        ),

        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color: Colors.red,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          borderSide:
              const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}