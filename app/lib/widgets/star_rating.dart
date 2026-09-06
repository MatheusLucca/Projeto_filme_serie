import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int? rating;
  final ValueChanged<int?> onChanged;
  final int maxStars;

  const StarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= maxStars; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(rating == i ? null : i),
            icon: Icon(
              (rating ?? 0) >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.brass,
            ),
          ),
      ],
    );
  }
}
