import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/future_message.dart';
import '../repository/message_repository.dart';
import '../utils/date_format.dart';
import '../widgets/delete_dialog.dart';

class MessageDetailScreen extends StatefulWidget {
  final FutureMessage message;
  final MessageRepository repository;

  const MessageDetailScreen({
    super.key,
    required this.message,
    required this.repository,
  });

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  Timer? _countdownTimer;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.message.isUnlocked) {
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (!mounted) return;
          setState(() {});
          if (widget.message.isUnlocked) timer.cancel();
        },
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _maybeReveal(bool unlockedNow) {
    if (unlockedNow && !_revealed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _revealed = true);
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;
    HapticFeedback.lightImpact();
    await widget.repository.delete(widget.message.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Message deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedNow = widget.message.isUnlocked;
    _maybeReveal(unlockedNow);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Message'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete message',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: unlockedNow ? _buildUnlocked(context) : _buildLocked(context),
    );
  }

  Widget _buildLocked(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remaining = widget.message.unlockAt.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.deepBurgundy,
            ),
            const SizedBox(height: 16),
            Text(
              'Not yet.',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This message opens on ${formatDateTime(widget.message.unlockAt)}.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CountdownUnit(
                  value: days.toString(),
                  unit: days == 1 ? 'DAY' : 'DAYS',
                ),
                _CountdownUnit(
                  value: hours.toString().padLeft(2, '0'),
                  unit: 'HRS',
                ),
                _CountdownUnit(
                  value: minutes.toString().padLeft(2, '0'),
                  unit: 'MIN',
                ),
                _CountdownUnit(
                  value: seconds.toString().padLeft(2, '0'),
                  unit: 'SEC',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlocked(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedOpacity(
        opacity: _revealed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WRITTEN ${formatDate(widget.message.createdAt).toUpperCase()}',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'OPENED ${formatDate(widget.message.unlockAt).toUpperCase()}',
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            Text(
              daysSinceWritten(widget.message.createdAt),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message.content,
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String unit;

  const _CountdownUnit({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: textTheme.displayLarge),
          const SizedBox(height: 4),
          Text(unit, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
