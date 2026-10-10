import 'package:flutter/material.dart';

Future<bool> showDeleteConfirmDialog(BuildContext context) async {
  final textTheme = Theme.of(context).textTheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Delete this message?',
        style: textTheme.headlineSmall,
      ),
      content: Text(
        'This cannot be undone.',
        style: textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
