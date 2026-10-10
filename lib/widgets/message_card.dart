import 'package:flutter/material.dart';

import '../main.dart';
import '../models/future_message.dart';
import '../utils/date_format.dart';

class MessageCard extends StatelessWidget {
  final FutureMessage message;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MessageCard({
    super.key,
    required this.message,
    required this.onTap,
    required this.onLongPress,
  });

  String _firstTwoLines(String content) {
    return content.split('\n').take(2).join('\n').trim();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unlocked = message.isUnlocked;
    final accent = unlocked ? AppColors.softCoral : AppColors.deepBurgundy;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        border: Border.all(color: AppColors.hairlineBorder, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  unlocked ? Icons.lock_open_outlined : Icons.lock_outline,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unlocked ? 'Unlocked' : 'Locked',
                        style: textTheme.labelSmall?.copyWith(color: accent),
                      ),
                      const SizedBox(height: 4),
                      if (unlocked) ...[
                        Text(
                          _firstTwoLines(message.content),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Written on ${formatDate(message.createdAt)}',
                          style: textTheme.bodyMedium,
                        ),
                      ] else ...[
                        Text(
                          'Opens on ${formatDate(message.unlockAt)}',
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          relativeLabel(message.unlockAt),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
