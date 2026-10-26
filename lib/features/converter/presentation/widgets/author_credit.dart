import 'package:flutter/material.dart';

import '../../../../core/platform/links.dart';
import '../../../../core/theme/colors.dart';

class AuthorCredit extends StatelessWidget {
  const AuthorCredit({super.key, this.fontSize = 10.5, this.logoSize = 14});

  final double fontSize;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Hecho por isdose.com',
      child: InkWell(
        onTap: () => openExternalLink('https://isdose.com'),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  'assets/branding/isdose-logo.png',
                  width: logoSize,
                  height: logoSize,
                  cacheWidth: 48,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Hecho por isdose.com',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
