// import 'package:flutter/material.dart';
// import 'package:offixo/CORE/Widget/app_style.dart';

// class ActionButtons extends StatelessWidget {
//   final bool isSuccess;

//   const ActionButtons({super.key, required this.isSuccess});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(
//           width: AppStyle.responsiveWidth(context, 252),

//           height: AppStyle.responsiveHeight(context, 45),

//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppStyle.primaryColor,

//               elevation: 0,

//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(48),
//               ),
//             ),

//             onPressed: () {
//               Navigator.pop(context);
//             },

//             child: Text(
//               isSuccess ? 'Continue' : 'Try Again',
//               textAlign: TextAlign.center,
//               style: AppStyle.jakartaText(
//                 context: context,

//                 size: 16,

//                 weight: FontWeight.w600,

//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),

//         SizedBox(height: AppStyle.responsiveHeight(context, 20)),

//         if (!isSuccess)
//           GestureDetector(
//             onTap: () {
//               Navigator.pop(context);
//             },

//             child: Text(
//               textAlign: TextAlign.center,
//               'Back',

//               style: AppStyle.jakartaText(
//                 context: context,

//                 size: 16,

//                 weight: FontWeight.w600,

//                 color: Colors.white54,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

class ActionButtons extends StatelessWidget {
  final bool isSuccess;
  final bool isAlreadyCheckedIn;
  final VoidCallback? onTryAgain;

  const ActionButtons({
    super.key,
    required this.isSuccess,
    this.isAlreadyCheckedIn = false,
    this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: AppStyle.responsiveWidth(context, 252),
          height: AppStyle.responsiveHeight(context, 45),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
            ),
            onPressed: () {
              if (isSuccess || isAlreadyCheckedIn) {
                Navigator.pop(context);
              } else {
                onTryAgain?.call();
              }
            },
            child: Text(
              isSuccess || isAlreadyCheckedIn ? 'Continue' : 'Try Again',
              textAlign: TextAlign.center,
              style: AppStyle.jakartaText(
                context: context,
                size: 16,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        SizedBox(height: AppStyle.responsiveHeight(context, 20)),

        if (!isSuccess && !isAlreadyCheckedIn)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Back',
              textAlign: TextAlign.center,
              style: AppStyle.jakartaText(
                context: context,
                size: 16,
                weight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ),
      ],
    );
  }
}