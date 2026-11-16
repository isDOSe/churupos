import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import 'author_credit.dart';

class _TopChamferClipper extends CustomClipper<Path> {
  const _TopChamferClipper(this.cut);

  final double cut;

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, cut)
      ..lineTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_TopChamferClipper oldClipper) => oldClipper.cut != cut;
}

class SheetShell extends StatelessWidget {
  const SheetShell({super.key, required this.child, this.showCredit = false});

  final Widget child;
  final bool showCredit;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _TopChamferClipper(18),
      child: ColoredBox(
        color: AppColors.raised,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                child,
                if (showCredit) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: AuthorCredit(fontSize: 10.5, logoSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
