import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

enum CheckStatus { checkedIn, checkedOut }

class CheckInButton extends StatefulWidget {
  final CheckStatus status;
  final VoidCallback onTap;

  const CheckInButton({super.key, required this.status, required this.onTap});

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  bool get _isCheckedIn => widget.status == CheckStatus.checkedIn;

  Color get _buttonColor =>
      _isCheckedIn ? const Color(0xFFFF6B00) : const Color(0xFF34C45A);

  String get _label => _isCheckedIn ? 'Check Out' : 'Check In';

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final double layer1 = AppStyle.responsiveWidth(context, 285);

    // final double layer2 = AppStyle.responsiveWidth(context, 239);

    // final double layer3 = AppStyle.responsiveWidth(context, 210);

    // final double layer4 = AppStyle.responsiveWidth(context, 196);

    return GestureDetector(
      onTap: widget.onTap,

      child: Stack(
        alignment: Alignment.center,

        children: [
          /// ───────── LAYER 1 ─────────
          Container(
            width: 285,
            height: 245,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xCCFFFDFD),
            ),
          ),

          /// ───────── LAYER 2 ─────────
          Container(
            width: 239,
            height: 238,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD9D9D9),
            ),
          ),

          /// ───────── ROTATING LAYERS ─────────
          AnimatedBuilder(
            animation: _rotationController,

            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159265,

                child: child,
              );
            },

            child: Stack(
              alignment: Alignment.center,

              children: [
                /// ───────── LAYER 3 ─────────
                Container(
                  width: 210,
                  height: 210,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    gradient: LinearGradient(
                      colors: _isCheckedIn
                          ? [
                              const Color(0xFFFFDDCC),
                              const Color(0xFFFFCCB3),
                              const Color(0xFFFFB347),
                            ]
                          : [
                              const Color(0xFFD4F5DC),
                              const Color(0xFFB8E6C1),
                              const Color(0xFF8ED4A0),
                            ],

                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                /// ───────── LAYER 4 ─────────
                Container(
                  width: 196,
                  height: 196,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    gradient: LinearGradient(
                      colors: _isCheckedIn
                          ? [
                              const Color(0xFFFFB347),
                              const Color(0xFFFF8C00),
                              const Color(0xFFE65C00),
                            ]
                          : [const Color(0xFF5DD16F), const Color(0xFF1E8C34)],

                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: _buttonColor.withOpacity(0.5),

                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// ───────── ICON + TEXT ─────────
          Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              SvgPicture.asset(
                'assets/svg/checkinicon.svg',

                width: AppStyle.responsiveWidth(context, 45.55),

                height: AppStyle.responsiveWidth(context, 51.34),

                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),

              SizedBox(height: AppStyle.responsiveHeight(context, 8)),

              Text(
                _label,

                style: AppStyle.jakartaText(
                  context: context,

                  size: 20,

                  weight: FontWeight.w700,

                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
