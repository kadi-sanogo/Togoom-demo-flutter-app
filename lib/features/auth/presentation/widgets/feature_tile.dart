import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:togoom/core/theme/app_colors.dart';

class FeatureTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final bool isPrimary;
  final VoidCallback? onTap;

  const FeatureTile({
    super.key,
    required this.title,
    required this.iconPath,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: isPrimary ? AppColors.secondary : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.secondary.withOpacity(0.2),
          highlightColor: AppColors.secondary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  color: isPrimary ? Colors.white : AppColors.secondary,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isPrimary ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isPrimary ? Colors.white : AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}